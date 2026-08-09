# Prompt — ConteoYA Fase 1: Ingesta de actas

Actúa como **Software Architect, Mobile Architect, Backend Architect, PostgreSQL Architect y especialista en sistemas offline-first**.

El proyecto se llama **ConteoYA**.

Esta fase es la prioridad absoluta.

## Objetivo

Construir el sistema mediante el cual un personero puede registrar los resultados de un acta electoral:

1. manualmente;
2. mediante fotografía;
3. mediante OCR/IA asistida;
4. verificando los datos;
5. guardando offline;
6. sincronizando posteriormente con Laravel;
7. conservando la fotografía como evidencia.

## Stack

### Backend

- Laravel 13
- PHP 8.5
- PostgreSQL
- Redis
- Laravel Sanctum

### Mobile

- Flutter 3.44
- Dart
- SQLite
- Drift

### Storage

- Cloudflare R2
- S3-compatible abstraction

## Regla fundamental

**La IA nunca confirma un acta.**

La IA/OCR solamente propone valores.

El personero debe revisar y confirmar.

---

# 1. Flujo manual

Implementar:

```text
Login
 ↓
Mesa asignada
 ↓
Seleccionar tipo de elección
 ↓
Crear acta local
 ↓
Registrar votos
 ↓
Registrar blancos
 ↓
Registrar nulos
 ↓
Registrar impugnados
 ↓
Calcular totales
 ↓
Validar
 ↓
Fotografiar acta
 ↓
Confirmar
 ↓
Persistir SQLite
 ↓
Agregar Sync Operation
```

---

# 2. Offline-first

No usar localStorage.

Usar:

```text
SQLite + Drift
```

La base local debe almacenar:

- actas;
- resultados;
- evidencias pendientes;
- catálogos necesarios;
- operaciones de sincronización;
- estado de sincronización;
- errores;
- metadata del dispositivo.

Estados:

```text
DRAFT
READY_TO_SYNC
SYNCING
SYNCED
FAILED
CONFLICT
```

---

# 3. Sync Engine

Crear un motor de sincronización robusto.

Cada operación debe tener:

```text
client_operation_id
device_id
entity_type
entity_id
operation
payload
created_at
attempts
status
last_error
```

Usar `client_operation_id` como idempotency key.

Si el mismo request llega dos veces:

```text
NO DUPLICAR
```

Implementar:

- retry;
- exponential backoff;
- conectividad;
- reanudación;
- transacciones;
- checksum;
- control de conflictos.

---

# 4. Acta

Crear un modelo flexible.

No crear:

```text
votos_gobernador
votos_alcalde_provincial
votos_alcalde_distrital
```

Crear:

```text
acts
act_results
act_totals
```

`act_results` debe permitir:

```text
organization_id
candidate_id nullable
list_id nullable
electoral_level
votes
source
confidence nullable
```

Sources:

```text
MANUAL
OCR
AI
```

---

# 5. Validaciones

Implementar reglas:

```text
sum(resultados) + blancos + nulos + impugnados
```

contra:

```text
total_votos_emitidos
```

También:

```text
votos ≤ electores_habiles
```

y:

```text
ciudadanos_que_votaron ≤ electores_habiles
```

Las inconsistencias deben mostrar advertencias claras.

No modificar automáticamente el valor ingresado por el personero.

---

# 6. Fotografía

Al tomar fotografía:

1. validar MIME;
2. validar tamaño;
3. generar hash SHA-256;
4. guardar localmente;
5. asociar a acta;
6. sincronizar posteriormente;
7. subir a R2 mediante backend seguro.

No exponer el bucket públicamente.

Registrar:

```text
sha256
mime
size
width
height
captured_at
device_id
storage_key
```

---

# 7. OCR / IA

Diseñar un adapter:

```text
ActRecognitionService
        │
        ├── OCRProvider
        ├── AIProvider
        └── FutureProvider
```

Entrada:

```text
imagen
```

Salida estructurada:

```json
{
  "mesa": "030390",
  "electores_habiles": 300,
  "results": [],
  "blank_votes": 8,
  "null_votes": 12,
  "challenged_votes": 0,
  "total_votes": 574,
  "voters_who_voted": 296
}
```

Además:

```json
{
  "field": "total_votes",
  "value": 574,
  "confidence": 0.97
}
```

La aplicación debe resaltar valores con baja confianza.

---

# 8. Evidencia

Una acta puede tener:

```text
original image
processed image
OCR result
AI extraction result
```

Conservar el original.

No reemplazar la fotografía original por una imagen procesada.

---

# 9. API

Crear endpoints similares a:

```text
POST /api/v1/acts
POST /api/v1/acts/{act}/confirm
POST /api/v1/acts/{act}/evidence
POST /api/v1/sync
GET  /api/v1/sync/status
GET  /api/v1/personero/polling-stations
GET  /api/v1/elections/{election}/catalog
```

La API debe soportar idempotencia.

---

# 10. Seguridad

Implementar:

- Sanctum;
- authorization;
- policies;
- rate limiting;
- device identification;
- audit logs;
- signed upload URLs o mecanismo equivalente;
- validación de archivos;
- límites de payload;
- protección contra replay;
- ownership de mesa.

Un personero no debe poder registrar resultados de una mesa que no tiene asignada.

---

# 11. Pruebas críticas

Crear pruebas para:

### Offline

```text
crear acta
cerrar aplicación
abrir aplicación
recuperar acta
```

### Sync

```text
crear acta offline
recuperar internet
sincronizar
repetir request
```

Resultado:

```text
1 acta
NO duplicados
```

### Fallo de red

```text
upload
network failure
retry
success
```

### OCR

Verificar que:

```text
OCR != confirmación
```

### Concurrencia

Dos requests simultáneos no deben duplicar resultados.

---

# 12. Criterio de aceptación

La Fase 1 se considera terminada cuando:

> Un personero puede registrar completamente un acta sin internet, incluyendo fotografía, cerrar la aplicación, volver a abrirla, revisar la información, recuperar conectividad y sincronizarla con Laravel sin pérdida, duplicación ni corrupción.

Después de esto se habilita la Fase 2.
