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
| **Frontend Web** | Vue 3.5 + Vuetify 3 + TypeScript 5.9 + Pinia + ApexCharts |
| **Realtime** | Laravel Reverb + Laravel Echo |
| **Documentación API** | Dedoc Scramble (OpenAPI 3.1) |

---

## 📁 Estructura del Proyecto (Ecosistema Multi-App)

> 💡 **Nota de Estructura:** Este repositorio **no es un monorepo formal** (no utiliza workspaces ni herramientas de monorepo como Nx o Turborepo); se trata de un **conjunto de aplicaciones y módulos independientes agrupados dentro del mismo espacio de trabajo del proyecto** para coordinar el backend, la aplicación móvil y la documentación centralizada.

```text
conteoya-project/
├── api/                    # 🟠 Backend Laravel 12 (activo)
├── mobile/                 # 🔵 App Móvil Flutter 3.44 (activo)
├── generate-pdf-erm2026/   # 📄 Generador vectorial de Actas Electorales ERM 2026 (Python/ReportLab)
├── scripts/                # 🛠️ Scripts utilitarios (generate_pdf_erm2026.sh, etc.)
├── database/               # Datos maestros JEE (erm2026.db)
├── docs/                   # Documentación técnica y reportes electorales
├── specs/                  # Especificaciones funcionales por fase
├── .agents/                # Skills y customizations para agentes IA
├── GEMINI.md               # Reglas del proyecto para Antigravity
├── CLAUDE.md               # Reglas del proyecto para Claude AI
└── README.md               # Este archivo
```

Ver los READMEs individuales para detalles de cada subproyecto:
- [`api/README.md`](api/README.md) — Instalación, migraciones, endpoints, comandos backend
- [`mobile/README.md`](mobile/README.md) — Instalación, arquitectura, features, comandos mobile
- [`generate-pdf-erm2026/README.md`](generate-pdf-erm2026/README.md) — Generador de actas oficiales ONPE en PDF con ReportLab

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

## 🚀 Guía de Comandos y Ejecución por Módulo

### 1. 🟠 Backend API (`api/` — Laravel 12 + PostgreSQL + Sanctum)

```bash
cd api/

# Instalación de dependencias
composer install

# Configuración de entorno
cp .env.example .env
php artisan key:generate

# Migraciones y Seeders (Roles, Usuarios, Datos JEE)
php artisan migrate:fresh --seed

# Iniciar servidor de desarrollo (http://127.0.0.1:8000)
php artisan serve

# Iniciar worker de colas (procesamiento asíncrono de sync y OCR)
php artisan queue:work

# Ejecutar suite de pruebas unitarias y de integración
php artisan test

# Exportar documentación OpenAPI (api.json)
php artisan scramble:export
```

---

### 2. 🔵 Aplicación Móvil (`mobile/` — Flutter 3.44 + Drift + Offline-First)

```bash
cd mobile/

# Instalación de dependencias
flutter pub get

# Generación de código Drift (SQLite) y Riverpod
dart run build_runner build --delete-conflicting-outputs

# Ejecutar en emulador o dispositivo físico
flutter run

# Ejecutar análisis estático y pruebas
flutter analyze
flutter test

# Compilar release para Android (APK)
flutter build apk --release
```

---

### 3. 🟢 Frontend Web (`web/` — Vue 3.5 + Vuetify 3 + Vite)

```bash
cd web/

# Instalación de dependencias
npm install

# Iniciar servidor de desarrollo con Vite (http://localhost:5173)
npm run dev

# Compilar para producción
npm run build

# Previsualizar build de producción
npm run preview
```

---

### 4. 📄 Generador de Actas Electorales (`generate-pdf-erm2026/` — Python + ReportLab)

```bash
# Opción A: Mediante script bash (desde la raíz del proyecto)
./scripts/generate_pdf_erm2026.sh --help
./scripts/generate_pdf_erm2026.sh 030390 040104 021038
./scripts/generate_pdf_erm2026.sh 030390 -o generate-pdf-erm2026/output

# Opción B: Modo interactivo
./scripts/generate_pdf_erm2026.sh

# Opción C: Ejecución directa con Python
generate-pdf-erm2026/.venv/bin/python generate-pdf-erm2026/generate.py 030390 -o mis_actas_pdf
```

Para más detalles, consulta [`generate-pdf-erm2026/README.md`](generate-pdf-erm2026/README.md).

---

### 5. 🗄️ Base de Datos y Datos Maestros JEE (`scripts/`)

```bash
# Construir/actualizar base de datos SQLite con datos oficiales del JEE
python3 scripts/build_erm2026_db.py
```

---

### 🔑 Credenciales de Prueba (Entorno de Desarrollo)

> ⚠️ Solo para desarrollo y pruebas locales.

| Email / Login | Password | Rol | Mesa Asignada |
|---|---|---|---|
| `admin@conteoya.pe` | `Admin123!` | `ADMIN` | Acceso global |
| `director@conteoya.pe` | `Director123!` | `DIRECTOR` | Acceso global |
| `personero@conteoya.pe` / `77889900` | `77889900!` | `PERSONERO` | Mesa `030390` (Lima Cercado) |
| `personero.puertoinca@conteoya.pe` / `44001122` | `44001122!` | `PERSONERO` | Mesa `021038` (Yuyapichis) |

> 💡 **Regla de Personeros:** La contraseña por defecto de todo personero es su **`[dni]!`** (su número de DNI seguido de `!`, ej. `41947287!`, `77889900!`, `44001122!`). Los personeros pueden iniciar sesión usando su correo o su DNI como usuario.

---

## 📚 Documentación Técnica Integral

El proyecto cuenta con un compendio de documentación estructurado bajo los estándares **arc42** y **Diátaxis Framework**, organizado en 7 módulos temáticos:

| Módulo | Descripción |
|---|---|
| [**`00-arquitectura/`**](docs/00-arquitectura/vision-general.md) | Visión general, metas de calidad, restricciones, topología cloud y registro de ADRs. |
| [**`01-modulos/`**](docs/01-modulos/api-backend.md) | Arquitectura del Backend Laravel 12, App Móvil Flutter, Base de Datos PostgreSQL 16 y Sync Engine. |
| [**`02-integraciones/`**](docs/02-integraciones/cloudflare-r2.md) | Storage privado Cloudflare R2 y Adaptador OCR/IA (Human-in-the-Loop). |
| [**`03-guias/`**](docs/03-guias/instalacion-local.md) | Tutorial de instalación local, How-To de ingesta de actas y consulta de cédulas. |
| [**`04-plantillas/`**](docs/04-plantillas/plantilla-adr.md) | Plantilla estándar para Registro de Decisiones de Arquitectura (ADRs). |
| [**`05-seguridad/`**](docs/05-seguridad/control-acceso-auditoria.md) | Matriz RBAC, verificación de ownership de mesa, idempotencia y auditoría. |
| [**`06-glosario/`**](docs/06-glosario/terminos-electorales.md) | Terminología del proceso electoral ERM 2026, ubigeos y siglas. |

👉 Consulta el índice maestro detallado en [**`docs/README.md`**](docs/README.md).

```bash
# Documentación interactiva (servidor corriendo)
http://localhost:8000/docs/api

# Exportar OpenAPI JSON
php artisan scramble:export
```

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
