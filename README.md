# ConteoYA — Plataforma de Ingesta, Validación y Visualización de Resultados Electorales (ERM 2026)

**ConteoYA** es una plataforma diseñada para la captura, validación, trazabilidad y consolidación de resultados electorales en las Elecciones Regionales y Municipales 2026 (ERM 2026) en Perú.

Permite a los personeros registrar resultados de actas electorales mediante una aplicación móvil (Flutter), operando en modalidad **offline-first** con registro manual o asistido por OCR/IA, conservación de fotoevidencias inalterables y sincronización idempotente hacia una API backend (Laravel 12 + PostgreSQL 16).

---

## 🏗️ Arquitectura General por Fases

```text
                           ┌─────────────────────────┐
                           │        CONTEOYA         │
                           └────────────┬────────────┘
                                        │
           ┌────────────────────────────┼────────────────────────────┐
           ▼                            ▼                            ▼
  FASE 0: FOUNDATION           FASE 1: INGESTA              FASE 2: RESULTADOS
  • Laravel 12 API             • Flutter 3.44 Mobile        • Vue 3.5 Web App
  • PostgreSQL 16+             • SQLite + Drift             • Pinia + Vite 8
  • Redis + Sanctum            • Offline-first              • Consolidación
  • Catálogo JEE & Ubigeo      • Cámara / OCR / IA          • Laravel Reverb (Realtime)
  • Auth, Roles & Dispositivos • Idempotencia & Evidencia   • Dashboards & Reportes
           │                            │                            │
           └────────────────────────────┼────────────────────────────┘
                                        │
                                        ▼
                               FASE 3: HARDENING
                               • Pruebas E2E & Concurrencia
                               • Rate Limiting & Security
                               • Simulación Electoral Masiva
                               • Resilience & Disaster Recovery
                                        │
                                        ▼
                               ┌─────────────────┐
                               │   PRODUCCIÓN    │
                               └─────────────────┘
```

---

## 🛠️ Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| **Backend API** | Laravel 12 (PHP 8.2+) + Laravel Sanctum |
| **Base de Datos** | PostgreSQL 16+ |
| **Cache & Queues** | Redis |
| **Almacenamiento** | Cloudflare R2 / S3 (Privado + Signed URLs) |
| **App Móvil** | Flutter 3.44 + SQLite/Drift (Offline-first) |
| **Frontend Web** | Vue 3.5 + Vite 8 + Pinia + Vuetify 4 |
| **Realtime** | Laravel Reverb + Echo |
| **Documentación API** | Dedoc Scramble (OpenAPI 3.1) |

---

## 📁 Estructura del Proyecto

```text
conteoya-project/
├── GEMINI.md                   # Reglas del proyecto para Antigravity / Gemini
├── CLAUDE.md                   # Reglas del proyecto para Claude AI
├── .agents/                    # Customizations y Skills para Agentes IA
│   └── skills/
│       ├── cloudflare-r2-s3-storage/    # Skill subida segura de evidencias
│       ├── flutter-dart-best-practices/ # Skill desarrollo mobile Flutter 3.44+
│       ├── git-conventional-commits/   # Skill estrategia de commits y ramas
│       ├── laravel-api-fase1-ingesta/   # Skill endpoints de ingesta en Laravel
│       ├── ocr-ia-adapter-pattern/      # Skill patrón Adapter OCR/IA
│       ├── offline-first-sync-engine/   # Skill motor de sincronización offline
│       ├── postgresql-16-best-practices/# Skill diseño BD en PostgreSQL 16
│       ├── software-engineering-best-practices/# Skill arquitectura e ingeniería
│       └── sqlite-drift-offline-first/  # Skill persistencia móvil Drift
├── api/                        # 🟠 Backend Laravel 12 (app principal activa)
│   ├── app/
│   │   ├── Http/Controllers/Api/V1/
│   │   │   ├── AuthController.php      # Login, /me, Logout (Sanctum)
│   │   │   ├── CatalogController.php   # Catálogos geográficos y electorales
│   │   │   └── PersoneroController.php # Mesas asignadas
│   │   └── Models/
│   │       ├── Role.php                # Modelo de Roles (ADMIN, DIRECTOR, PERSONERO)
│   │       ├── User.php                # Usuario con role_id FK
│   │       └── Personero.php           # Perfil personero
│   ├── config/scramble.php             # Configuración OpenAPI/Scramble
│   ├── database/
│   │   ├── migrations/                 # 6 migraciones del esquema ConteoYA
│   │   └── seeders/
│   │       ├── RoleSeeder.php          # Roles del sistema
│   │       ├── UserSeeder.php          # Usuarios de prueba por rol
│   │       └── JeeDatabaseSeeder.php   # Datos maestros JEE (requiere erm2026.db)
│   ├── routes/api.php                  # Rutas API v1 con throttle y Sanctum
│   └── README.md                       # Guía de instalación y uso del backend
├── database/                   # Archivos de BD fuente
│   └── erm2026.db              # Fuente SQLite de datos maestros JEE
├── docs/                       # Documentación técnica
│   ├── database_modeling.md    # Modelado Conceptual, Lógico y Físico
│   └── api_reference.md        # Referencia de endpoints y ejemplos
├── specs/                      # Especificaciones funcionales por fase
│   ├── CONTEOYA_PROPUESTA_FASES_ERM2026.md
│   ├── CONTEOYA_PROMPT_FASE0_FOUNDATION.md
│   ├── CONTEOYA_PROMPT_FASE1_INGESTA.md
│   ├── CONTEOYA_PROMPT_FASE2_REALTIME_DASHBOARD.md
│   └── CONTEOYA_PROMPT_FASE3_HARDENING.md
└── README.md                   # Este archivo
```

---

## 🗄️ Modelado de Base de Datos (PostgreSQL 16+)

El esquema de base de datos se ha diseñado bajo los siguientes principios:

1. **Desacoplamiento Catálogos / Transacciones:** Mantiene separados los datos maestros (Ubigeos, Organizaciones Políticas, Candidaturas) de las transacciones (Actas, Votos, Evidencias, Auditoría).
2. **Niveles Electorales Polimórficos (`electoral_levels`):** Soporta dinámicamente cargos regionales, provinciales y distritales sin columnas rígidas.
3. **Sistema de Roles con Tabla Propia (`roles`):** Tres roles predefinidos (ADMIN, DIRECTOR, PERSONERO) con integridad referencial (FK `role_id` en `users`).
4. **Offline-First & Idempotencia (`sync_operations`):** `client_operation_id` (UUID) para evitar duplicados en reintentos de red.
5. **Human-In-The-Loop:** OCR/IA sólo propone valores con grados de confianza (`confidence`); la confirmación final la realiza el personero humano.

Para más detalle, consulta:
- [docs/database_modeling.md](docs/database_modeling.md) — Modelado completo
- [docs/api_reference.md](docs/api_reference.md) — Referencia de endpoints

---

## 👥 Roles del Sistema

| Rol | `name` | Descripción |
|-----|--------|-------------|
| Administrador | `ADMIN` | Acceso total. Gestiona elecciones, usuarios y configuración. |
| Director | `DIRECTOR` | Supervisor de sede electoral. Ve resultados consolidados. |
| Personero | `PERSONERO` | Captura actas desde la app móvil. Accede a sus mesas asignadas. |

---

## 🔐 Autenticación y Setup Rápido

```bash
# Desde el directorio api/
cd api/

# 1. Migraciones
php artisan migrate

# 2. Seeders (roles + usuarios + datos JEE)
php artisan db:seed

# 3. Correr servidor
php artisan serve
```

### Usuarios de prueba

> ⚠️ Solo para desarrollo. Cambiar credenciales antes de pasar a producción.

| Email | Password | Rol | Mesa Asignada |
|-------|----------|-----|---------------|
| `admin@conteoya.pe` | `Admin123!` | `ADMIN` | — |
| `director@conteoya.pe` | `Director123!` | `DIRECTOR` | — |
| `personero@conteoya.pe` | `Personero123!` | `PERSONERO` | Mesa `030390` (Lima Cercado) |
| `personero.puertoinca@conteoya.pe` | `Puertoinca123!` | `PERSONERO` | Mesa `040104` (Yuyapichis) |

---

## 📡 API & Documentación OpenAPI

La API está versionada bajo `/api/v1` y documentada automáticamente con **Dedoc Scramble**.

```bash
# Documentación interactiva (servidor corriendo)
http://localhost:8000/docs/api

# Exportar OpenAPI JSON
php artisan scramble:export
```

### Endpoints Principales v1

- **Autenticación:** `/api/v1/login`, `/api/v1/me`, `/api/v1/logout` (Devuelve `polling_station_code` cuando es personero)
- **Gestión de Usuarios (CRUD):** `/api/v1/users` (ADMIN / DIRECTOR)
- **Personeros (CRUD):** `/api/v1/personeros` (ADMIN / DIRECTOR)
- **Mesas Electorales (CRUD):** `/api/v1/mesas` (ADMIN / DIRECTOR)
- **Ingesta de Actas & Evidencias:** `/api/v1/acts`, `/api/v1/acts/{id}/confirm`, `/api/v1/acts/{id}/evidence/upload-url`, `/api/v1/acts/{id}/evidence/confirm`
- **OCR/IA & Sync Offline:** `/api/v1/acts/recognize`, `/api/v1/sync`

Ver [docs/api_reference.md](docs/api_reference.md) para la referencia completa de endpoints.

---

## 🚀 Fases de Implementación

| Fase | Estado | Descripción |
|------|--------|-------------|
| **Fase 0 — Foundation** | ✅ Completada | API base, PostgreSQL, Sanctum, Roles, Catálogo JEE, Auth |
| **Fase 1 — Ingesta** | 🟡 En progreso | App Flutter 3.44 offline-first, Drift SQLite, CRUD usuarios/mesas, captura de actas, evidenciador R2 |
| **Fase 2 — Resultados** | ⏳ Pendiente | Dashboard Vue 3, consolidados, Laravel Reverb realtime |
| **Fase 3 — Hardening** | ⏳ Pendiente | E2E, carga masiva, auditoría, disaster recovery |

---

## 📄 Licencia y Propiedad

Proyecto privado para la ingesta y consolidación electoral ERM 2026 — Perú.
