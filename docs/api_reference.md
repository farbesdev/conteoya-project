# ConteoYA — Referencia de Endpoints API v1

**Base URL:** `http://localhost:8000/api/v1`  
**Versión:** 0.1.0 (Fase 0 — Foundation)  
**Autenticación:** Bearer Token (Laravel Sanctum)  
**Documentación interactiva:** `http://localhost:8000/docs/api`

---

## Autenticación

La API usa **Laravel Sanctum** con tokens Bearer. El flujo es:

```
1. POST /api/v1/login  →  obtener access_token
2. Enviar en cada request protegido:
   Authorization: Bearer {access_token}
3. POST /api/v1/logout  →  revocar token
```

### Rate Limiting

| Grupo | Límite |
|-------|--------|
| `api` (throttle global) | 60 req/min por IP |
| `login` (throttle estricto) | 5 req/min por IP |

---

## 🔓 Endpoints Públicos

### `POST /api/v1/login`

Autentica al usuario y devuelve un Bearer token junto con el perfil completo (incluyendo rol).

**Request Body**

| Campo | Tipo | Requerido | Descripción |
|-------|------|-----------|-------------|
| `email` | `string` | ✅ | Email del usuario |
| `password` | `string` | ✅ | Contraseña |
| `device_uuid` | `string` | ❌ | UUID único del dispositivo (solo personeros con app móvil) |
| `device_model` | `string` | ❌ | Modelo del dispositivo |

**Ejemplo de request**

```json
{
  "email": "personero@conteoya.pe",
  "password": "Personero123!",
  "device_uuid": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "device_model": "Samsung Galaxy S24"
}
```

**Respuesta `200 OK`**

```json
{
  "access_token": "3|XyZABCdef...",
  "token_type": "Bearer",
  "user": {
    "id": 3,
    "name": "Juan Pérez Demo",
    "email": "personero@conteoya.pe",
    "role": "PERSONERO",
    "role_id": 3,
    "is_active": true,
    "rol": {
      "id": 3,
      "name": "PERSONERO",
      "display_name": "Personero"
    },
    "personero_id": 1
  }
}
```

> 📝 **Nota:** El campo `rol` contiene el objeto completo del rol. El campo `role` (string) es un alias para acceso rápido sin JOIN. El campo `personero_id` es `null` para usuarios con roles `ADMIN` o `DIRECTOR`.

**Respuestas de error**

| Código | Descripción |
|--------|-------------|
| `401` | `"Las credenciales proporcionadas son incorrectas."` |
| `403` | `"El usuario se encuentra inactivo."` |
| `422` | Error de validación (email vacío, formato inválido, etc.) |

---

## 🔒 Endpoints Protegidos (Bearer Token)

Todos requieren el header: `Authorization: Bearer {token}`

---

### `GET /api/v1/me`

Devuelve el perfil completo del usuario autenticado.

**Respuesta `200 OK`**

```json
{
  "user": {
    "id": 3,
    "name": "Juan Pérez Demo",
    "email": "personero@conteoya.pe",
    "role": "PERSONERO",
    "role_id": 3,
    "is_active": true,
    "email_verified_at": null,
    "created_at": "2026-08-10T16:27:25.000000Z",
    "updated_at": "2026-08-10T16:27:25.000000Z",
    "rol": {
      "id": 3,
      "name": "PERSONERO",
      "display_name": "Personero"
    },
    "personero": {
      "id": 1,
      "user_id": 3,
      "document_number": "12345678",
      "phone_number": "+51 987 654 321",
      "created_at": "2026-08-10T16:27:25.000000Z",
      "updated_at": "2026-08-10T16:27:25.000000Z"
    }
  }
}
```

---

### `POST /api/v1/logout`

Revoca el token Bearer actual del usuario autenticado.

**Respuesta `200 OK`**

```json
{
  "message": "Sesión cerrada exitosamente."
}
```

---

### `GET /api/v1/personero/polling-stations`

Devuelve las mesas de sufragio asignadas al personero autenticado.

> ⚠️ Solo accesible por usuarios con rol `PERSONERO`.

**Respuesta `200 OK`**

```json
{
  "data": [
    {
      "id": 1,
      "code": "030390",
      "registered_voters": 300,
      "status": "ACTIVE",
      "electoral_location": {
        "id": 1,
        "name": "I.E. San José",
        "address": "Av. Principal 123",
        "district_code": "030301"
      }
    }
  ]
}
```

---

## 📚 Catálogos Electorales

Todos los catálogos están cacheados en **Redis** (TTL indicado por endpoint).  
Son accesibles para cualquier usuario autenticado independientemente de su rol.

---

### `GET /api/v1/departments`

Listado completo de departamentos ordenado por nombre.  
**Cache:** 24 horas (`catalog:departments`)

**Respuesta `200 OK`**

```json
[
  { "code": "01", "name": "AMAZONAS", "created_at": "...", "updated_at": "..." },
  { "code": "02", "name": "ÁNCASH", "created_at": "...", "updated_at": "..." }
]
```

---

### `GET /api/v1/provinces`

Listado de provincias, filtrable por departamento.  
**Cache:** 24 horas (`catalog:provinces:{department_code|all}`)

**Query Parameters**

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `department_code` | `string` | Código de departamento (ej: `"01"`) — opcional |

**Ejemplo**

```
GET /api/v1/provinces?department_code=15
```

---

### `GET /api/v1/districts`

Listado de distritos, filtrable por provincia.  
**Cache:** 24 horas (`catalog:districts:{province_code|all}`)

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `province_code` | `string` | Código de provincia (ej: `"1501"`) — opcional |

---

### `GET /api/v1/elections`

Elecciones registradas con sus niveles electorales.  
**Cache:** 24 horas (`catalog:elections`)

**Respuesta `200 OK`**

```json
[
  {
    "id": 1,
    "code": "ERM2026",
    "name": "Elecciones Regionales y Municipales 2026",
    "date": "2026-10-04",
    "status": "PLANNED",
    "levels": [
      { "id": 1, "code": "REGIONAL_GOBERNADOR", "name": "Gobernador Regional", "has_preferential_vote": false },
      { "id": 2, "code": "PROVINCIAL_ALCALDE",  "name": "Alcalde Provincial",  "has_preferential_vote": false }
    ]
  }
]
```

---

### `GET /api/v1/political-organizations`

Organizaciones políticas participantes.  
**Cache:** 12 horas (`catalog:political_organizations`)

---

### `GET /api/v1/electoral-lists`

Listas electorales paginadas (50 por página), con candidaturas e información de la organización.  
**Cache:** 1 hora por combinación de filtros

**Query Parameters**

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `electoral_level_id` | `integer` | Filtrar por nivel electoral — opcional |
| `district_code` | `string` | Filtrar por distrito — opcional |
| `page` | `integer` | Número de página (default: 1) |

**Ejemplo**

```
GET /api/v1/electoral-lists?electoral_level_id=3&district_code=150101&page=1
```

---

## 🗳️ Fase 1 — Ingesta de Actas, Evidencias y Sincronización

### `POST /api/v1/acts`
Registra o actualiza un acta electoral de manera atómica (`acts`, `act_totals`, `act_results`).
Soporta `Idempotency-Key` o `client_operation_id` para evitar duplicaciones.
Si la suma de votos difiere del total emitido declarado, devuelve `201 Created` con `validation_result.is_valid_total = false` y advertencias (`warnings`).

**Headers opcionales:**
- `Idempotency-Key: {uuid}`

**Request Body**
```json
{
  "client_operation_id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "polling_station_code": "030390",
  "election_id": 1,
  "electoral_level_id": 2,
  "act_code": "ACT-030390-MP",
  "status": "DRAFT",
  "totals": {
    "registered_voters": 300,
    "voters_who_voted": 280,
    "total_votes": 280,
    "blank_votes": 10,
    "null_votes": 5,
    "challenged_votes": 0
  },
  "results": [
    {
      "political_organization_id": 1,
      "votes": 165,
      "source": "MANUAL",
      "confidence": null
    },
    {
      "political_organization_id": 2,
      "votes": 100,
      "source": "OCR",
      "confidence": 0.94
    }
  ]
}
```

---

### `POST /api/v1/acts/{id}/confirm`
Transiciona el estado del acta a `CONFIRMED` e inserta la marca temporal de confirmación `confirmed_at`.

---

### `POST /api/v1/acts/{id}/evidence/upload-url`
Genera una Presigned PUT URL privada para Cloudflare R2 con TTL de 15 minutos.

**Request Body**
```json
{
  "sha256_hash": "a1b2c3d4e5f6...64caracteres",
  "file_mime": "image/jpeg",
  "file_size_bytes": 1048576
}
```

---

### `POST /api/v1/acts/{id}/evidence/confirm`
Registra la evidencia fotográfica en la base de datos tras la subida exitosa a R2.

---

### `POST /api/v1/acts/recognize`
Procesa una imagen de acta electoral mediante el adapter OCR/IA (*Human-in-the-Loop*).
Retorna la extracción estructurada con mapa de confianza (`confidence`). Los campos con confianza < 0.85 son resaltados para revisión obligatoria del personero.

---

### `POST /api/v1/sync`
Recibe un lote de operaciones offline (`SyncOperation`) generadas por el `SyncEngine` móvil.
Garantiza procesamiento idempotente por `client_operation_id`.

**Request Body**
```json
{
  "device_uuid": "dev-uuid-1234",
  "operations": [
    {
      "client_operation_id": "7b7a661f-99ab-48d6-95a9-4672bb193635",
      "entity_type": "acts",
      "entity_id": "local-uuid-act-1",
      "operation": "CREATE",
      "payload": { ... }
    }
  ]
}
```

---

### `GET /api/v1/sync/status`
Consulta el estado de sincronización de las operaciones del personero autenticado.

---

## 👥 Usuarios de Prueba (Desarrollo)

> ⚠️ Cambiar credenciales antes de pasar a producción o staging.

| Email | Password | Rol | `role_id` |
|-------|----------|-----|-----------|
| `admin@conteoya.pe` | `Admin123!` | `ADMIN` | `1` |
| `director@conteoya.pe` | `Director123!` | `DIRECTOR` | `2` |
| `personero@conteoya.pe` | `Personero123!` | `PERSONERO` | `3` |

---

## 🏷️ Tabla de Roles

| `id` | `name` | `display_name` | Descripción |
|------|--------|----------------|-------------|
| `1` | `ADMIN` | Administrador | Acceso total. Gestiona elecciones, usuarios y configuración. |
| `2` | `DIRECTOR` | Director | Supervisor de sede. Gestiona personeros y consulta resultados en tiempo real. |
| `3` | `PERSONERO` | Personero | Captura actas desde la app móvil. Accede a sus mesas asignadas. |

---

## 📖 Documentación OpenAPI (Scramble)

La spec OpenAPI 3.1 se genera automáticamente con **Dedoc Scramble**:

```bash
# UI interactiva en navegador
http://localhost:8000/docs/api

# JSON exportado
php artisan scramble:export
# → genera: api/api.json
```

**Configuración de seguridad:**
- `/login` → `security: []` (pública)
- Todos los demás endpoints → `security: [Bearer]` (detectado vía `auth:sanctum`)

---

_Última actualización: Fase 0 — v0.1.0 — 2026-08-10_
