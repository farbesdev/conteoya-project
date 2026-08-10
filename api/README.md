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

| Migración | Descripción |
|-----------|-------------|
| `0001_01_01_000000_create_users_table` | Tabla `users` con columna `role` (string) |
| `0001_01_01_000001_create_cache_table` | Tablas de cache y sesiones |
| `0001_01_01_000002_create_jobs_table` | Cola de trabajos |
| `2026_08_09_165656_create_personal_access_tokens_table` | Tokens Sanctum |
| `2026_08_09_165708_create_conteoya_tables` | Esquema principal: geography, catálogo electoral, personeros, actas |
| `2026_08_10_102628_create_roles_table` | Tabla `roles` + FK `role_id` en `users` |

### Seeders

```bash
# Todos los seeders (orden orquestado)
php artisan db:seed

# Seeders individuales
php artisan db:seed --class=RoleSeeder    # Crea roles: ADMIN, DIRECTOR, PERSONERO
php artisan db:seed --class=UserSeeder    # Crea un usuario de prueba por cada rol
php artisan db:seed --class=JeeDatabaseSeeder  # Carga datos maestros JEE (requiere erm2026.db)
```

---

## 👥 Roles del sistema

La tabla `roles` define los tres roles del sistema. Cada `user` tiene una FK `role_id` hacia `roles`, además de mantener la columna `role` (string) para compatibilidad y acceso rápido sin JOIN.

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

### Flujo de autenticación

```
POST /api/v1/login
  → Valida credenciales (email + password)
  → Si es Personero + device_uuid → registra/actualiza dispositivo
  → Devuelve: access_token + usuario + objeto rol completo
```

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
    "personero_id": 1
  }
}
```

### Usuarios de prueba (solo desarrollo)

> ⚠️ **Cambiar contraseñas antes de pasar a producción.**

| Email | Password | Rol |
|-------|----------|-----|
| `admin@conteoya.pe` | `Admin123!` | `ADMIN` |
| `director@conteoya.pe` | `Director123!` | `DIRECTOR` |
| `personero@conteoya.pe` | `Personero123!` | `PERSONERO` |

---

## 📡 Endpoints disponibles (v0.1.0 — Fase 0)

Base URL: `http://localhost:8000/api/v1`

### Autenticación

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `POST` | `/login` | Pública | Iniciar sesión → devuelve Bearer token + rol |
| `GET` | `/me` | 🔒 Bearer | Perfil del usuario autenticado |
| `POST` | `/logout` | 🔒 Bearer | Revocar token actual |

### Personero

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `GET` | `/personero/polling-stations` | 🔒 Bearer | Mesas asignadas al personero autenticado |

### Catálogos electorales _(caché Redis 24h)_

| Método | Ruta | Auth | Parámetros | Descripción |
|--------|------|------|------------|-------------|
| `GET` | `/departments` | 🔒 Bearer | — | Listado de departamentos |
| `GET` | `/provinces` | 🔒 Bearer | `?department_code=` | Provincias (filtrable) |
| `GET` | `/districts` | 🔒 Bearer | `?province_code=` | Distritos (filtrable) |
| `GET` | `/elections` | 🔒 Bearer | — | Elecciones con niveles electorales |
| `GET` | `/political-organizations` | 🔒 Bearer | — | Organizaciones políticas |
| `GET` | `/electoral-lists` | 🔒 Bearer | `?electoral_level_id=&district_code=&page=` | Listas electorales paginadas |

---

## 📖 Documentación API (Scramble)

La documentación OpenAPI interactiva se genera automáticamente con **Dedoc Scramble**.

```bash
# Acceder en el navegador (servidor local corriendo)
http://localhost:8000/docs/api

# Exportar spec OpenAPI a archivo JSON
php artisan scramble:export   # → genera api/api.json
```

**Características:**
- Rutas públicas (`/login`) → `security: []`
- Rutas protegidas → `security: Bearer` (detectado automáticamente por `auth:sanctum`)
- Anotaciones `@tags`, `@bodyParam`, `@response` en todos los controladores

---

## 📁 Estructura del proyecto

```text
api/
├── app/
│   ├── Http/Controllers/Api/V1/
│   │   ├── AuthController.php      # Login, /me, Logout
│   │   ├── CatalogController.php   # Catálogos electorales (geog. + electoral)
│   │   └── PersoneroController.php # Mesas asignadas al personero
│   ├── Models/
│   │   ├── Role.php                # Roles del sistema (ADMIN, DIRECTOR, PERSONERO)
│   │   ├── User.php                # Usuario con role_id FK + hasRole()
│   │   ├── Personero.php           # Perfil personero de mesa
│   │   ├── Device.php              # Dispositivo móvil registrado
│   │   └── ...                     # Modelos electorales (Act, Election, etc.)
│   └── Traits/
│       └── MigrationSeedingMethod.php
├── config/
│   └── scramble.php                # Configuración OpenAPI (Bearer auth, título, descripción)
├── database/
│   ├── migrations/                 # 6 migraciones (ver tabla arriba)
│   └── seeders/
│       ├── DatabaseSeeder.php      # Orquestador principal
│       ├── RoleSeeder.php          # Roles del sistema
│       ├── UserSeeder.php          # Usuarios de prueba por rol
│       └── JeeDatabaseSeeder.php   # Datos maestros JEE
└── routes/
    └── api.php                     # Rutas API v1 con throttle y auth:sanctum
```

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
```

---

## 📄 Licencia

Proyecto privado — Plataforma ConteoYA para ERM 2026.
