# ConteoYA — Backend API (Laravel 12 + PostgreSQL 16)

API REST de alto rendimiento del sistema **ConteoYA** para la captura, validación y consolidación de actas electorales en las Elecciones Regionales y Municipales 2026 (ERM 2026) del Perú.

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

### Migraciones Aplicadas

| # | Migración | Descripción |
|---|-----------|-------------|
| 1 | `0001_01_01_000000_create_users_table` | Tabla `users` con columna `role` (string) |
| 2 | `0001_01_01_000001_create_cache_table` | Tablas de cache y sesiones |
| 3 | `0001_01_01_000002_create_jobs_table` | Cola de trabajos |
| 4 | `2026_08_09_165656_create_personal_access_tokens_table` | Tokens Sanctum |
| 5 | `2026_08_09_165708_create_conteoya_tables` | Esquema principal: geografía, catálogo electoral, personeros, actas, sync, auditoría |
| 6 | `2026_08_10_102628_create_roles_table` | Tabla `roles` + FK `role_id` en `users` |
| 7 | `2026_08_10_220000_make_device_id_nullable_in_sync_operations_table` | Hace `device_id` nullable en `sync_operations` |
| 8 | `2026_08_13_153500_make_personero_id_nullable_in_sync_operations_table` | Hace `personero_id` nullable en `sync_operations` para operaciones de ADMIN/DIRECTOR |
| 9 | `2026_08_14_120000_add_odpe_and_pdf_fields_to_polling_stations_table` | Agrega campos ODPE y enlaces PDF a mesas electorales |
| 10 | `2026_08_17_130000_create_electoral_ballot_views_and_procedures` | Vistas SQL y procedimientos almacenados para generación de cédulas electorales |
| 11 | `2026_08_18_180000_add_jee_proceso_id_to_elections_table` | Agrega `jee_proceso_electoral_id` a la tabla `elections` |
| 12 | `2026_08_18_180100_add_jee_fields_to_personeros_table` | Extiende `personeros` con campos del padrón JEE (organización política, abogado, tipo personero, ubigeos) |

### Seeders

```bash
# Todos los seeders (orden orquestado)
php artisan db:seed

# Seeders individuales
php artisan db:seed --class=RoleSeeder          # Crea roles: ADMIN, DIRECTOR, PERSONERO
php artisan db:seed --class=UserSeeder          # Crea usuarios de prueba por cada rol
php artisan db:seed --class=JeeDatabaseSeeder   # Carga datos maestros JEE (requiere erm2026.db)
php artisan db:seed --class=PersonerosSeeder    # Importa y consolida personeros del padrón JEE
```

---

## 👥 Roles del sistema

| Rol | `name` | Descripción |
|-----|--------|-------------|
| Administrador | `ADMIN` | Acceso total. Gestiona elecciones, usuarios, personeros y configuración. |
| Director | `DIRECTOR` | Supervisor de sede. Gestiona personeros y consulta resultados. |
| Personero | `PERSONERO` | Captura actas desde la app móvil. Accede a sus mesas asignadas. |

---

## 🔐 Autenticación (Sanctum)

Todas las rutas protegidas requieren el header:

```
Authorization: Bearer {token}
```

El token se obtiene desde `POST /api/v1/login`. El login acepta indistintamente **correo electrónico** o **número de DNI** en el campo `email`.

### Usuarios de prueba (solo desarrollo)

> ⚠️ **Cambiar contraseñas antes de pasar a producción.**

| Email / DNI | Password | Rol | Mesa Asignada |
|-------|----------|-----|---------------|
| `admin@conteoya.pe` | `Admin123!` | `ADMIN` | — |
| `director@conteoya.pe` | `Director123!` | `DIRECTOR` | — |
| `personero@conteoya.pe` / `77889900` | `77889900!` | `PERSONERO` | Mesa `030390` (Lima Cercado) |
| `personero.puertoinca@conteoya.pe` / `44001122` | `44001122!` | `PERSONERO` | Mesa `021038` (Yuyapichis) |

> 💡 **Regla de Personeros:** La contraseña por defecto de todo personero es su **`[dni]!`** (ejemplo: DNI `41947287` tiene contraseña `41947287!`). Los personeros pueden iniciar sesión usando su correo o su DNI como usuario.

---

## 📡 Endpoints disponibles (v1.0.0 — Fase 0 + Fase 1)

Base URL: `http://localhost:8000/api/v1`

### Autenticación

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `POST` | `/login` | Pública | Iniciar sesión (con email o DNI) → devuelve Bearer token + rol |
| `GET` | `/me` | 🔒 Bearer | Perfil del usuario autenticado |
| `POST` | `/logout` | 🔒 Bearer | Revocar token actual |

### Usuarios (CRUD — solo ADMIN / DIRECTOR)

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `GET` | `/users` | 🔒 Bearer | Listar usuarios (búsqueda agnóstica `?search=` y filtro `?role=`) |
| `POST` | `/users` | 🔒 Bearer | Crear usuario (crea perfil `personero` automáticamente si aplica) |
| `GET` | `/users/{id}` | 🔒 Bearer | Ver usuario específico |
| `PUT/PATCH` | `/users/{id}` | 🔒 Bearer | Actualizar usuario |
| `DELETE` | `/users/{id}` | 🔒 Bearer | Eliminar usuario (solo ADMIN) |
| `POST` | `/users/{id}/reset-password` | 🔒 Bearer | Restablecer contraseña de usuario |

### Personeros (Gestión y Consulta)

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `GET` | `/personeros` | 🔒 Bearer | Listar personeros paginados con búsqueda insensible agnóstica `?search=` |
| `PATCH` | `/personeros/{id}/toggle-access` | 🔒 Bearer | Activar / desactivar acceso de personero y revocar tokens |
| `GET` | `/personero/polling-stations` | 🔒 Bearer | Mesas asignadas al personero autenticado |

### Mesas Electorales

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `GET` | `/polling-stations` | 🔒 Bearer | Listar mesas paginadas con búsqueda agnóstica `?search=` y filtros geográficos |
| `POST` | `/polling-stations` | 🔒 Bearer | Crear mesa (ADMIN / DIRECTOR) |
| `GET` | `/polling-stations/{id}` | 🔒 Bearer | Ver detalle de mesa |
| `PUT/PATCH` | `/polling-stations/{id}` | 🔒 Bearer | Actualizar mesa |
| `DELETE` | `/polling-stations/{id}` | 🔒 Bearer | Eliminar mesa (ADMIN) |

### Catálogos electorales _(caché Redis)_

| Método | Ruta | Auth | Cache | Descripción |
|--------|------|------|-------|-------------|
| `GET` | `/departments` | 🔒 Bearer | 24h | Listado de departamentos |
| `GET` | `/provinces` | 🔒 Bearer | 24h | Provincias (filtrable `?department_code=`) |
| `GET` | `/districts` | 🔒 Bearer | 24h | Distritos (filtrable `?province_code=`) |
| `GET` | `/elections` | 🔒 Bearer | 24h | Elecciones con niveles electorales |
| `GET` | `/political-organizations` | 🔒 Bearer | 12h | Organizaciones políticas |
| `GET` | `/electoral-lists` | 🔒 Bearer | 1h | Listas electorales paginadas |
| `GET` | `/catalogs/ballot-template` | 🔒 Bearer | 1h | Plantilla dinámica de cédula de sufragio por mesa o ubigeo |

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
| `GET` | `/sync/pull` | 🔒 Bearer | `throttle:ingestion` | Descargar actualizaciones del servidor al dispositivo con caché Redis |
| `GET` | `/sync/status` | 🔒 Bearer | `throttle:ingestion` | Estado de sync de las operaciones del personero |

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
│   │   │                           # CatalogController, PersoneroController, PollingStationController
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
│   └── Providers/                  # AppServiceProvider, QueryMacroServiceProvider
├── database/
│   ├── migrations/                 # 12 migraciones del esquema ConteoYA
│   └── seeders/                    # DatabaseSeeder, RoleSeeder, UserSeeder, JeeDatabaseSeeder, PersonerosSeeder
└── routes/
    └── api.php                     # Rutas API v1 con throttle, auth:sanctum e idempotent
```

---

## 🔧 Comandos útiles

```bash
# Limpiar caché de config y rutas
php artisan config:clear && php artisan route:clear

# Ver todas las rutas registradas
php artisan route:list --path=api

# Ejecutar suite de pruebas (28 tests)
php artisan test
```

---

## 📄 Licencia

Proyecto privado — Plataforma ConteoYA para ERM 2026.
