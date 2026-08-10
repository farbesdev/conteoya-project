---
name: cloudflare-r2-s3-storage
description: >
  Experto y buenas prácticas en Cloudflare R2 y almacenamiento S3-compatible para
  subida segura de evidencias fotográficas electorales. Cubre presigned URLs, abstracción
  de storage, validación de archivos, integridad SHA-256, y configuración en Laravel.
  Activar en "R2", "S3", "cloudflare", "storage", "upload", "presigned", "evidencia", "fotografía".
---

# Experto y Buenas Prácticas en Cloudflare R2 / S3-Compatible Storage

## 1. Principios Fundamentales

- **Nunca exponer el bucket públicamente.** Las fotografías de actas son documentos electorales sensibles.
- **Siempre usar Presigned URLs o proxying seguro.** El cliente no accede al bucket directamente.
- **Verificar integridad con SHA-256.** Calcular en el cliente antes de subir; verificar en el servidor al recibir.
- **El cliente nunca tiene credenciales del bucket.** Solo el backend Laravel las posee.

---

## 2. Arquitectura de Subida Segura (Recomendada para ConteoYA)

```text
[App Flutter]
    │ 1. POST /api/v1/acts/{id}/evidence/upload-url
    │    (request: sha256, mime, size)
    │
[Backend Laravel]
    │ 2. Valida ownership de mesa y acta
    │ 3. Valida mime, size, sha256 (no duplicado)
    │ 4. Genera Presigned PUT URL (TTL 15min)
    │ 5. Registra EvidencePending en BD
    │
[App Flutter]
    │ 6. PUT {presigned_url} con el archivo binario
    │    (Header: Content-SHA256 del archivo)
    │
[Cloudflare R2]
    │ 7. Almacena objeto
    │
[App Flutter]
    │ 8. POST /api/v1/acts/{id}/evidence/confirm
    │    (body: object_key, sha256)
    │
[Backend Laravel]
    │ 9. Verifica que el objeto existe en R2
    │ 10. Actualiza act_evidence: storage_provider, object_key, confirmed_at
```

---

## 3. Configuración Laravel (S3-Compatible)

### `.env` para Cloudflare R2
```bash
FILESYSTEM_CLOUD=r2

AWS_ACCESS_KEY_ID=your_r2_access_key
AWS_SECRET_ACCESS_KEY=your_r2_secret_key
AWS_DEFAULT_REGION=auto          # Cloudflare R2 usa "auto"
AWS_BUCKET=conteoya-evidence
AWS_URL=                         # Vacío — no exponer URL pública
AWS_ENDPOINT=https://{account_id}.r2.cloudflarestorage.com
AWS_USE_PATH_STYLE_ENDPOINT=true # Requerido para R2
```

### `config/filesystems.php` — disk r2
```php
'r2' => [
    'driver'                  => 's3',
    'key'                     => env('AWS_ACCESS_KEY_ID'),
    'secret'                  => env('AWS_SECRET_ACCESS_KEY'),
    'region'                  => env('AWS_DEFAULT_REGION', 'auto'),
    'bucket'                  => env('AWS_BUCKET'),
    'endpoint'                => env('AWS_ENDPOINT'),
    'use_path_style_endpoint' => env('AWS_USE_PATH_STYLE_ENDPOINT', true),
    'url'                     => null,        // Nunca exponer URL pública
    'visibility'              => 'private',   // Siempre privado
    'throw'                   => true,        // Propagar excepciones
],
```

---

## 4. Abstracción de Storage en Laravel

### Interface StorageProvider
```php
// app/Contracts/StorageProvider.php
interface StorageProvider
{
    public function generateUploadUrl(
        string $objectKey,
        string $mimeType,
        int    $ttlSeconds = 900
    ): string;

    public function objectExists(string $objectKey): bool;

    public function generateDownloadUrl(
        string $objectKey,
        int    $ttlSeconds = 3600
    ): string;

    public function delete(string $objectKey): bool;
}
```

### Implementación R2StorageProvider
```php
// app/Infrastructure/Storage/R2StorageProvider.php
class R2StorageProvider implements StorageProvider
{
    public function __construct(
        private readonly FilesystemAdapter $disk
    ) {}

    public function generateUploadUrl(string $objectKey, string $mimeType, int $ttlSeconds = 900): string
    {
        // Generar presigned PUT URL con AWS SDK (Flysystem v3 + S3 adapter)
        return $this->disk->temporaryUploadUrl(
            $objectKey,
            now()->addSeconds($ttlSeconds),
            ['ContentType' => $mimeType]
        );
    }

    public function objectExists(string $objectKey): bool
    {
        return $this->disk->exists($objectKey);
    }

    public function generateDownloadUrl(string $objectKey, int $ttlSeconds = 3600): string
    {
        return $this->disk->temporaryUrl($objectKey, now()->addSeconds($ttlSeconds));
    }
}
```

---

## 5. Nomenclatura de Object Keys

### Estructura de paths en R2
```
evidence/{election_code}/{district_code}/{polling_station_code}/{act_id}/{sha256}.jpg
```

**Ejemplo:**
```
evidence/ERM2026/030301/030390/1247/a3f8c2d1e4b5...sha256....jpg
```

**Reglas:**
- Incluir siempre el SHA-256 en el key → garantiza unicidad e inmutabilidad.
- Nunca usar nombres de archivo originales del usuario (seguridad).
- Agrupar por elección → distrito → mesa → acta para facilitar listados y políticas de retención.

---

## 6. Validación en el Backend (Laravel)

```php
// app/Http/Requests/RequestEvidenceUploadUrlRequest.php
class RequestEvidenceUploadUrlRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'sha256'    => ['required', 'string', 'size:64', 'regex:/^[a-f0-9]{64}$/'],
            'mime_type' => ['required', 'string', 'in:image/jpeg,image/png,image/webp'],
            'file_size' => ['required', 'integer', 'min:1', 'max:' . (10 * 1024 * 1024)], // máx 10MB
        ];
    }
}
```

```php
// Verificar que el sha256 no esté ya registrado (deduplicación)
$exists = ActEvidence::where('sha256_hash', $request->sha256)->exists();
if ($exists) {
    return response()->json(['message' => 'Esta evidencia ya fue registrada.'], 409);
}
```

---

## 7. Verificación de Integridad Post-Subida

```php
// Al confirmar la subida, verificar sha256 directamente en R2
public function confirmEvidence(ConfirmEvidenceRequest $request, Act $act): JsonResponse
{
    $objectKey = $request->object_key;

    // 1. Verificar que el objeto existe en R2
    if (!$this->storage->objectExists($objectKey)) {
        return response()->json(['message' => 'El objeto no existe en el storage.'], 404);
    }

    // 2. Actualizar registro en BD
    $evidence = ActEvidence::where('act_id', $act->id)
                            ->where('sha256_hash', $request->sha256)
                            ->firstOrFail();

    $evidence->update([
        'object_key'       => $objectKey,
        'storage_provider' => 'R2',
        'confirmed_at'     => now(),
    ]);

    return response()->json(['message' => 'Evidencia confirmada.', 'evidence_id' => $evidence->id]);
}
```

---

## 8. Seguridad — Reglas Críticas

| Regla | Descripción |
|-------|-------------|
| **Bucket siempre privado** | `visibility: private` en config. Sin ACLs públicas. |
| **TTL corto en presigned URLs** | Máximo 15 minutos para upload, 1 hora para download. |
| **SHA-256 en cliente y servidor** | El cliente calcula, el servidor verifica contra el objeto en R2. |
| **Ownership verificado** | El personero solo puede subir evidencia de actas de sus mesas. |
| **No path traversal** | Sanitizar `object_key` — nunca aceptar paths del cliente directamente. |
| **Audit log de uploads** | Registrar en `audit_logs`: quién subió, cuándo, qué sha256. |
| **Sin presigned URLs cacheables** | Cada solicitud genera una URL nueva. No cachear en CDN. |

---

## 9. Fallback y Resiliencia

- Si el upload falla, la `SyncOperation` queda en estado `FAILED` y se reintenta con backoff exponencial.
- El objeto en R2 debe considerarse "pendiente de confirmación" hasta que el backend reciba el `POST /confirm`.
- Implementar un job de limpieza que elimine objetos "huérfanos" (subidos pero sin confirmación después de 24h).
- Para desconexiones prolongadas, el archivo se mantiene local hasta poder subirse; el acta queda en `READY_TO_SYNC`.
