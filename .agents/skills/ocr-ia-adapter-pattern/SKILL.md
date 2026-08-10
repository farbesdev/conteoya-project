---
name: ocr-ia-adapter-pattern
description: >
  Experto y buenas prácticas en el diseño del adapter pattern para integración de
  servicios OCR/IA en sistemas de reconocimiento de actas electorales. Cubre el contrato
  ActRecognitionService, proveedores intercambiables, manejo de confianza, validación de
  imágenes y el principio Human-in-the-Loop obligatorio para ConteoYA.
  Activar en "OCR", "IA", "AI", "reconocimiento", "adapter", "provider", "visión",
  "ActRecognitionService", "confidence", "extracción".
---

# Experto y Buenas Prácticas en OCR / IA — Adapter Pattern para Ingesta de Actas

## 1. Principio Fundamental: Human-In-The-Loop

> **La IA/OCR NUNCA confirma un acta. Solo propone valores.**
> 
> El personero debe revisar cada campo propuesto y confirmar manualmente.
> Los valores con `confidence < 0.85` deben resaltarse visualmente como "requieren revisión".

Este principio debe ser inviolable en **todas** las capas del sistema.

---

## 2. Arquitectura del Adapter

```text
ActRecognitionService (Orquestador)
        │
        ├── OcrProvider (Interface)
        │       ├── TesseractOcrProvider    # Local / open-source
        │       ├── GoogleVisionOcrProvider # Google Cloud Vision API
        │       └── AzureCognitiveProvider  # Azure Form Recognizer
        │
        └── AiProvider (Interface)
                ├── OpenAiVisionProvider    # GPT-4o Vision
                ├── GeminiVisionProvider    # Gemini 1.5 Pro Vision
                └── MockAiProvider          # Para testing sin API externa
```

---

## 3. Contratos (Interfaces)

### Interface OcrProvider / AiProvider
```php
// app/Contracts/ActRecognitionProvider.php
interface ActRecognitionProvider
{
    /**
     * Procesa una imagen de acta y devuelve la extracción estructurada.
     *
     * @param  string $imagePath  Ruta local al archivo de imagen
     * @param  string $mimeType   MIME type del archivo
     * @return ActExtractionResult
     * @throws ExtractionFailedException
     */
    public function extract(string $imagePath, string $mimeType): ActExtractionResult;

    /**
     * Nombre identificador del proveedor (para audit logs).
     */
    public function getName(): string;
}
```

### DTOs de Entrada y Salida
```php
// app/Domain/Acts/DTOs/ActExtractionResult.php
final class ActExtractionResult
{
    public function __construct(
        public readonly string  $providerName,
        public readonly ?string $pollingStationCode,    // Mesa detectada
        public readonly ?int    $registeredVoters,
        public readonly ?int    $votersWhoVoted,
        public readonly ?int    $totalVotes,
        public readonly ?int    $blankVotes,
        public readonly ?int    $nullVotes,
        public readonly ?int    $challengedVotes,
        /** @var ExtractionField[] */
        public readonly array   $results,               // Votos por lista/candidato
        /** @var ExtractionFieldConfidence[] */
        public readonly array   $confidenceMap,         // confidence por campo
        public readonly array   $rawResponse,           // JSON original del proveedor
        public readonly \Carbon\CarbonImmutable $processedAt,
    ) {}

    /**
     * Verifica si algún campo tiene confianza baja (< threshold).
     */
    public function hasLowConfidenceFields(float $threshold = 0.85): bool
    {
        return collect($this->confidenceMap)
                ->some(fn (ExtractionFieldConfidence $f) => $f->confidence < $threshold);
    }
}

// app/Domain/Acts/DTOs/ExtractionFieldConfidence.php
final class ExtractionFieldConfidence
{
    public function __construct(
        public readonly string $field,     // 'total_votes', 'blank_votes', etc.
        public readonly mixed  $value,     // Valor extraído
        public readonly float  $confidence // 0.0 – 1.0
    ) {}
}
```

---

## 4. ActRecognitionService — Orquestador

```php
// app/Domain/Acts/ActRecognitionService.php
class ActRecognitionService
{
    public function __construct(
        private readonly ActRecognitionProvider $provider,
        private readonly ImageValidatorService  $imageValidator,
        private readonly AuditLogger            $auditLogger,
    ) {}

    /**
     * Punto de entrada principal. Valida imagen → extrae → audita → devuelve.
     */
    public function recognize(
        string $imagePath,
        string $mimeType,
        int    $actId,
    ): ActExtractionResult {
        // 1. Validar imagen antes de enviarla al proveedor
        $this->imageValidator->validate($imagePath, $mimeType);

        // 2. Extraer con el proveedor configurado
        $result = $this->provider->extract($imagePath, $mimeType);

        // 3. Persistir resultado bruto para trazabilidad
        OcrAiExtraction::create([
            'act_id'              => $actId,
            'provider_name'       => $result->providerName,
            'raw_response_json'   => $result->rawResponse,
            'extracted_data_json' => $this->toExtractedData($result),
            'processed_at'        => $result->processedAt,
        ]);

        // 4. Audit log
        $this->auditLogger->log(
            action:     'OCR_EXTRACTION',
            entityType: 'acts',
            entityId:   (string) $actId,
            payload:    ['provider' => $result->providerName, 'hasLowConfidence' => $result->hasLowConfidenceFields()],
        );

        return $result;
    }
}
```

---

## 5. Implementación de Proveedor Mock (Testing)

```php
// app/Infrastructure/Recognition/MockActRecognitionProvider.php
class MockActRecognitionProvider implements ActRecognitionProvider
{
    public function extract(string $imagePath, string $mimeType): ActExtractionResult
    {
        return new ActExtractionResult(
            providerName:       'mock',
            pollingStationCode: '030390',
            registeredVoters:   300,
            votersWhoVoted:     287,
            totalVotes:         287,
            blankVotes:         8,
            nullVotes:          5,
            challengedVotes:    0,
            results: [
                new ExtractionField('Partido A', organizationId: 1, votes: 145),
                new ExtractionField('Partido B', organizationId: 2, votes: 129),
            ],
            confidenceMap: [
                new ExtractionFieldConfidence('total_votes',  287, 0.98),
                new ExtractionFieldConfidence('blank_votes',  8,   0.91),
                new ExtractionFieldConfidence('null_votes',   5,   0.87),
                new ExtractionFieldConfidence('partido_a_votes', 145, 0.62), // ← Baja confianza
            ],
            rawResponse:  ['mock' => true],
            processedAt:  now()->toImmutable(),
        );
    }

    public function getName(): string { return 'mock'; }
}
```

---

## 6. Respuesta al Cliente — Resaltar Campos de Baja Confianza

```json
{
  "extraction": {
    "provider": "google_vision",
    "processed_at": "2026-10-04T14:32:10Z",
    "polling_station_code": "030390",
    "registered_voters": 300,
    "total_votes": 574,
    "blank_votes": 8,
    "null_votes": 12,
    "challenged_votes": 0,
    "confidence_map": [
      { "field": "total_votes",    "value": 574, "confidence": 0.97, "needs_review": false },
      { "field": "blank_votes",    "value": 8,   "confidence": 0.91, "needs_review": false },
      { "field": "partido_a_votes","value": 145,  "confidence": 0.61, "needs_review": true }
    ],
    "has_low_confidence": true,
    "low_confidence_threshold": 0.85
  },
  "warning": "Algunos campos tienen baja confianza y requieren revisión manual antes de confirmar el acta."
}
```

> **En Flutter:** Los campos con `needs_review: true` se resaltan en amarillo/naranja y el botón "Confirmar" permanece deshabilitado hasta que el personero revise todos los campos marcados.

---

## 7. Binding en el Service Provider

```php
// app/Providers/AppServiceProvider.php
$this->app->bind(ActRecognitionProvider::class, function () {
    return match (config('services.ocr.driver')) {
        'google_vision' => new GoogleVisionOcrProvider(config('services.ocr.google_key')),
        'openai'        => new OpenAiVisionProvider(config('services.ocr.openai_key')),
        'mock'          => new MockActRecognitionProvider(),
        default         => throw new \InvalidArgumentException('OCR provider no configurado'),
    };
});
```

---

## 8. Validación de Imagen Antes de Procesar

```php
// app/Domain/Evidence/ImageValidatorService.php
class ImageValidatorService
{
    private const ALLOWED_MIMES = ['image/jpeg', 'image/png', 'image/webp'];
    private const MAX_SIZE_BYTES = 10 * 1024 * 1024; // 10MB

    public function validate(string $path, string $mimeType): void
    {
        if (!in_array($mimeType, self::ALLOWED_MIMES)) {
            throw new InvalidImageException("MIME no permitido: {$mimeType}");
        }

        $size = filesize($path);
        if ($size > self::MAX_SIZE_BYTES) {
            throw new InvalidImageException("Archivo demasiado grande: {$size} bytes");
        }

        // Verificar que es realmente una imagen (no solo por extensión)
        [$width, $height] = getimagesize($path);
        if (!$width || !$height) {
            throw new InvalidImageException("El archivo no es una imagen válida.");
        }
    }
}
```

---

## 9. Reglas Críticas

| Regla | Descripción |
|-------|-------------|
| **Human-in-the-Loop siempre** | OCR/AI solo propone. Nunca confirma. Nunca escribe en `acts.status = CONFIRMED` directamente. |
| **Guardar raw_response** | El JSON original del proveedor se persiste en `ocr_ai_extractions.raw_response_json` para auditoría. |
| **Threshold configurable** | `confidence_threshold` configurable en `.env`, no hardcodeado. |
| **Provider intercambiable** | Binding en ServiceProvider — cambiar de Google Vision a OpenAI sin tocar código de negocio. |
| **Validar imagen antes** | Mime, tamaño y dimensiones verificados antes de enviar a API externa. |
| **Audit log de extracciones** | Quién solicitó, qué proveedor, qué acta, cuándo, si había baja confianza. |
| **Sin keys en el cliente** | Las API keys de OCR/IA nunca llegan al app móvil. Todo pasa por el backend. |
