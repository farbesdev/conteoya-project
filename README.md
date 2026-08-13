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
| **Frontend Web** | Vue 3.5 + Vite 8 + Pinia *(Fase 2 — no iniciada)* |
| **Realtime** | Laravel Reverb *(Fase 2 — no iniciada)* |
| **Documentación API** | Dedoc Scramble (OpenAPI 3.1) |

---

## 📁 Estructura del Proyecto

```text
conteoya-project/
├── api/                    # 🟠 Backend Laravel 12 (activo)
├── mobile/                 # 🔵 App Móvil Flutter 3.44 (activo)
├── database/               # Datos maestros JEE (erm2026.db)
├── docs/                   # Documentación técnica
├── specs/                  # Especificaciones funcionales por fase
├── .agents/                # Skills y customizations para agentes IA
├── GEMINI.md               # Reglas del proyecto para Antigravity
├── CLAUDE.md               # Reglas del proyecto para Claude AI
└── README.md               # Este archivo
```

Ver los READMEs individuales para detalles de cada subproyecto:
- [`api/README.md`](api/README.md) — Instalación, migraciones, endpoints, comandos backend
- [`mobile/README.md`](mobile/README.md) — Instalación, arquitectura, features, comandos mobile

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
# Backend (desde api/)
cd api/
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve

# App Móvil (desde mobile/)
cd mobile/
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
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

Ver [docs/api_reference.md](docs/api_reference.md) para la referencia completa de endpoints.

---

## 🚀 Fases de Implementación

| Fase | Estado | Descripción |
|------|--------|-------------|
| **Fase 0 — Foundation** | ✅ Completada | API base, PostgreSQL, Sanctum, Roles, Catálogo JEE, Auth |
| **Fase 1 — Ingesta** | 🟡 En progreso | App Flutter 3.44 offline-first, Drift SQLite, captura de actas, evidencias R2, OCR/IA, sync engine |
| **Fase 2 — Resultados** | ⏳ Pendiente | Dashboard Vue 3, consolidados, Laravel Reverb realtime |
| **Fase 3 — Hardening** | ⏳ Pendiente | E2E, carga masiva, auditoría, disaster recovery |

---

## 📄 Licencia y Propiedad

Proyecto privado para la ingesta y consolidación electoral ERM 2026 — Perú.
