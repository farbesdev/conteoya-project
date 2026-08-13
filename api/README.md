# ConteoYA — Backend API (Laravel 12 + PostgreSQL 16)

API REST del sistema **ConteoYA** para la captura, validación y consolidación de actas electorales en las Elecciones Regionales y Municipales 2026 (ERM 2026) del Perú.

---

## 🛠️ Stack

| Capa | Tecnología |
|------|-----------|
| Framework | Laravel 12 (PHP 8.2+) |
| Autenticación | Laravel Sanctum (Bearer Token) |
| Base de datos | PostgreSQL 16+ |
| Cache / Queues | Redis |
| Almacenamiento | Cloudflare R2 (S3-compatible, privado) |
| Documentación API | Dedoc Scramble (OpenAPI 3.1) |
| Realtime (Fase 2) | Laravel Reverb |

---

## ⚙️ Instalación y configuración

### Requisitos previos

- PHP 8.2+
- Composer
- PostgreSQL 16+
- Redis
- El archivo `database/erm2026.db` en la raíz del monorepo (datos maestros JEE)

### Pasos

```bash
# 1. Instalar dependencias
cd api/
composer install

# 2. Configurar variables de entorno
cp .env.example .env
php artisan key:generate

# 3. Configurar .env con tus credenciales
# DB_CONNECTION=pgsql
# DB_HOST=127.0.0.1
# DB_PORT=5432
# DB_DATABASE=conteoya_bd
# DB_USERNAME=...
# DB_PASSWORD=...

# 4. Ejecutar migraciones
php artisan migrate

# 5. Ejecutar seeders (roles + usuarios de prueba + datos JEE)
php artisan db:seed

# 6. Iniciar servidor local
php artisan serve
```

---

## 🗄️ Base de datos

### Migraciones (orden de ejecución)

| # | Migración | Descripción |
|---|-----------|-------------|
| 1 | `0001_01_01_000000_create_users_table` | Tabla `users` con columna `role` (string) |
| 2 | `0001_01_01_000001_create_cache_table` | Tablas de cache y sesiones |
| 3 | `0001_01_01_000002_create_jobs_table` | Cola de trabajos |
| 4 | `2026_08_09_165656_create_personal_access_tokens_table` | Tokens Sanctum |
| 5 | `2026_08_09_165708_create_conteoya_tables` | Esquema principal: geografía, catálogo electoral, personeros, actas, sync, auditoría |
| 6 | `2026_08_10_102628_create_roles_table` | Tabla `roles` + FK `role_id` en `users` |
| 7 | `2026_08_10_220000_make_device_id_nullable_in_sync_operations_table` | Hace `device_id` nullable en `sync_operations` |

### Seeders

```bash
# Todos los seeders (orden orquestado)
php artisan db:seed

# Seeders individuales
php artisan db:seed --class=RoleSeeder          # Crea roles: ADMIN, DIRECTOR, PERSONERO
php artisan db:seed --class=UserSeeder          # Crea usuarios de prueba por cada rol
php artisan db:seed --class=JeeDatabaseSeeder   # Carga datos maestros JEE (requiere erm2026.db)
```

---

## 👥 Roles del sistema

| Rol | `name` | Descripción |
|-----|--------|-------------|
| Administrador | `ADMIN` | Acceso total. Gestiona elecciones, usuarios y configuración. |
| Director | `DIRECTOR` | Supervisor de sede. Gestiona personeros y consulta resultados. |
| Personero | `PERSONERO` | Captura actas desde la app móvil. Accede a sus mesas asignadas. |

---

## 🔐 Autenticación (Sanctum)

Todas las rutas protegidas requieren el header:

```
Authorization: Bearer {token}
```

El token se obtiene desde `POST /api/v1/login`.

### Respuesta de login

```json
{
  "access_token": "1|XyZ...",
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
    "personero_id": 1,
    "polling_station_code": "030390"
  }
}
```

### Usuarios de prueba (solo desarrollo)

> ⚠️ **Cambiar contraseñas antes de pasar a producción.**

| Email | Password | Rol | Mesa Asignada |
|-------|----------|-----|---------------|
| `admin@conteoya.pe` | `Admin123!` | `ADMIN` | — |
| `director@conteoya.pe` | `Director123!` | `DIRECTOR` | — |
| `personero@conteoya.pe` | `Personero123!` | `PERSONERO` | Mesa `030390` (Lima Cercado) |
| `personero.puertoinca@conteoya.pe` | `Puertoinca123!` | `PERSONERO` | Mesa `040104` (Yuyapichis) |

---

## 📡 Endpoints disponibles (v1.0.0 — Fase 0 + Fase 1)

Base URL: `http://localhost:8000/api/v1`

### Autenticación

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `POST` | `/login` | Pública | Iniciar sesión → devuelve Bearer token + rol |
| `GET` | `/me` | 🔒 Bearer | Perfil del usuario autenticado |
| `POST` | `/logout` | 🔒 Bearer | Revocar token actual |

### Usuarios (CRUD — solo ADMIN / DIRECTOR)

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `GET` | `/users` | 🔒 Bearer | Listar usuarios (con filtro `?role=` y `?search=`) |
| `POST` | `/users` | 🔒 Bearer | Crear usuario (crea perfil `personero` automáticamente si aplica) |
| `GET` | `/users/{id}` | 🔒 Bearer | Ver usuario específico |
| `PUT/PATCH` | `/users/{id}` | 🔒 Bearer | Actualizar usuario |
| `DELETE` | `/users/{id}` | 🔒 Bearer | Eliminar usuario (solo ADMIN) |

### Personero

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `GET` | `/personero/polling-stations` | 🔒 Bearer | Mesas asignadas al personero autenticado |

### Catálogos electorales _(caché Redis)_

| Método | Ruta | Auth | Cache | Descripción |
|--------|------|------|-------|-------------|
| `GET` | `/departments` | 🔒 Bearer | 24h | Listado de departamentos |
| `GET` | `/provinces` | 🔒 Bearer | 24h | Provincias (filtrable `?department_code=`) |
| `GET` | `/districts` | 🔒 Bearer | 24h | Distritos (filtrable `?province_code=`) |
| `GET` | `/elections` | 🔒 Bearer | 24h | Elecciones con niveles electorales |
| `GET` | `/political-organizations` | 🔒 Bearer | 12h | Organizaciones políticas |
| `GET` | `/electoral-lists` | 🔒 Bearer | 1h | Listas electorales paginadas (`?electoral_level_id=&district_code=&page=`) |

### Actas Electorales (Fase 1)

| Método | Ruta | Auth | Rate Limit | Descripción |
|--------|------|------|------------|-------------|
| `POST` | `/acts` | 🔒 Bearer | `throttle:acts` | Registrar acta (idempotente, `Idempotency-Key`) |
| `GET` | `/acts/{id}` | 🔒 Bearer | — | Ver acta con totales, resultados y evidencias |
| `POST` | `/acts/{id}/confirm` | 🔒 Bearer | `throttle:acts` | Confirmar acta (transición → `CONFIRMED`) |

### Evidencias Fotográficas (Fase 1)

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `POST` | `/acts/{id}/evidence/upload-url` | 🔒 Bearer | Genera Presigned PUT URL en R2 (TTL 15min) |
| `POST` | `/acts/{id}/evidence/confirm` | 🔒 Bearer | Registra evidencia tras subida exitosa a R2 |
| `GET` | `/acts/{id}/evidence/{eid}/download` | 🔒 Bearer | Genera Presigned GET URL para descarga (TTL 60min) |

### OCR / IA (Fase 1 — Human-in-the-Loop)

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `POST` | `/acts/recognize` | 🔒 Bearer | Procesar imagen de acta con OCR/IA (devuelve propuesta con `confidence`) |
| `POST` | `/acts/{id}/recognize` | 🔒 Bearer | Re-procesar imagen de acta ya existente |

### Motor de Sincronización Offline (Fase 1)

| Método | Ruta | Auth | Rate Limit | Descripción |
|--------|------|------|------------|-------------|
| `POST` | `/sync` | 🔒 Bearer | `throttle:ingestion` | Enviar lote de `SyncOperation` (idempotente por `client_operation_id`) |
| `GET` | `/sync/pull` | 🔒 Bearer | `throttle:ingestion` | Descargar actualizaciones del servidor al dispositivo |
| `GET` | `/sync/status` | 🔒 Bearer | `throttle:ingestion` | Estado de sync de las operaciones del personero |

### Rate Limiting

| Grupo | Límite | Aplicado a |
|-------|--------|------------|
| `api` | 60 req/min por IP | Throttle global |
| `login` | 5 req/min por IP | Endpoint `/login` |
| `acts` | Config `throttle:acts` | Escritura de actas y confirmaciones |
| `ingestion` | Config `throttle:ingestion` | Endpoints `/sync` |

---

## 📁 Estructura del proyecto

```text
api/
├── app/
│   ├── Contracts/                  # Interfaces (StorageProviderInterface, ActRecognitionProviderInterface)
│   ├── Domain/
│   │   ├── Acts/                   # ActService, ActValidationService, ActRecognitionService, DTOs
│   │   └── Evidence/               # EvidenceService
│   ├── Http/
│   │   ├── Controllers/Api/V1/     # AuthController, ActController, EvidenceController,
│   │   │                           # RecognitionController, SyncController, UserController,
│   │   │                           # CatalogController, PersoneroController
│   │   ├── Middleware/             # IdempotencyMiddleware
│   │   ├── Requests/               # CreateActRequest, ConfirmActRequest, RecognizeActRequest,
│   │   │                           # RequestUploadUrlRequest, ConfirmEvidenceRequest, SyncOperationRequest
│   │   └── Resources/              # ActResource, ActTotalsResource, ActResultResource,
│   │                               # ActEvidenceResource, SyncOperationResource
│   ├── Infrastructure/
│   │   ├── Ocr/                    # GeminiVisionProvider, OpenAiVisionProvider, MockActRecognitionProvider
│   │   └── Storage/                # R2StorageProvider, MockStorageProvider
│   ├── Jobs/                       # ProcessSyncOperationJob
│   ├── Models/                     # User, Role, Personero, Device, Act, ActTotal, ActResult,
│   │                               # ActEvidence, OcrAiExtraction, SyncOperation, AuditLog, ...
│   ├── Policies/                   # ActPolicy, EvidencePolicy
│   └── Traits/                     # MigrationSeedingMethod
├── config/
│   └── scramble.php                # Configuración OpenAPI (Bearer auth, título, descripción)
├── database/
│   ├── migrations/                 # 7 migraciones del esquema ConteoYA
│   └── seeders/                    # DatabaseSeeder, RoleSeeder, UserSeeder, JeeDatabaseSeeder
└── routes/
    └── api.php                     # Rutas API v1 con throttle, auth:sanctum e idempotent
```

---

## 📖 Documentación API (Scramble)

La documentación OpenAPI interactiva se genera automáticamente con **Dedoc Scramble**.

```bash
# Acceder en el navegador (servidor local corriendo)
http://localhost:8000/docs/api

# Exportar spec OpenAPI a archivo JSON
php artisan scramble:export   # → genera api/api.json
```

Ver la referencia completa en [docs/api_reference.md](../docs/api_reference.md).

---

## 🔧 Comandos útiles

```bash
# Limpiar caché de config y rutas
php artisan config:clear && php artisan route:clear

# Ver todas las rutas registradas
php artisan route:list --path=api

# Refrescar BD completa (⚠️ destruye datos)
php artisan migrate:fresh --seed

# Ejecutar tests
php artisan test

# Exportar spec OpenAPI (ejecutar tras cada cambio de ruta o controller)
php artisan scramble:export
```

---

## 📄 Licencia

Proyecto privado — Plataforma ConteoYA para ERM 2026.
