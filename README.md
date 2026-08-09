# ConteoYA — Plataforma de Ingesta, Validación y Visualización de Resultados Electorales (ERM 2026)

**ConteoYA** es una plataforma diseñada para la captura, validación, trazabilidad y consolidación de resultados electorales en las Elecciones Regionales y Municipales 2026 (ERM 2026) en Perú.

Permite a los personeros registrar resultados de actas electorales mediante una aplicación móvil (Flutter), operando en modalidad **offline-first** con registro manual o asistido por OCR/IA, conservación de fotoevidencias inalterables y sincronización idempotente hacia una API backend (Laravel 13 + PostgreSQL 16).

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
  • Laravel 13 API             • Flutter 3.44 Mobile        • Vue 3.5 Web App
  • PostgreSQL 16+             • SQLite + Drift             • Pinia + Vite 8
  • Redis + Sanctum            • Offline-first              • Consolidación
  • Catálogo JEE & Ubigeo      • Cámara / OCR / IA          • Laravel Reverb (Realtime)
  • Auth & Dispositivos        • Idempotencia & Evidencia   • Dashboards & Reportes
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

- **Backend API:** Laravel 13 (PHP 8.5) + Laravel Sanctum
- **Base de Datos Principal:** PostgreSQL 16+
- **Cache & Queues:** Redis
- **Almacenamiento de Evidencia:** Cloudflare R2 / S3 (Privado + Signed URLs)
- **App Móvil:** Flutter 3.44 + SQLite/Drift (Offline-first)
- **Frontend Web (Dashboards):** Vue 3.5 + Vite 8 + Pinia + Vuetify 4 / Tailwind CSS
- **Realtime:** Laravel Reverb + Echo

---

## 📁 Estructura del Proyecto y Documentación

```text
conteoya-project/
├── .agents/                 # Customizations y Skills especializadas para Antigravity / Gemini
│   └── skills/
│       ├── database-modeling-analysis-design/
│       ├── postgresql-16-best-practices/
│       └── software-engineering-best-practices/
├── database/                # Archivos de BD y Scripts SQL
│   ├── erm2026.db           # Fuente SQLite de datos maestros JEE
│   └── schema_v1_postgres.sql # DDL optimizado PostgreSQL 16+ para Fases 0 y 1
├── docs/                    # Documentación técnica y modelado
│   └── database_modeling.md # Especificación del Modelado Conceptual, Lógico y Físico
├── specs/                   # Especificaciones funcionales del proyecto
│   ├── CONTEOYA_PROPUESTA_FASES_ERM2026.md
│   ├── CONTEOYA_PROMPT_FASE0_FOUNDATION.md
│   ├── CONTEOYA_PROMPT_FASE1_INGESTA.md
│   ├── CONTEOYA_PROMPT_FASE2_REALTIME_DASHBOARD.md
│   └── CONTEOYA_PROMPT_FASE3_HARDENING.md
└── README.md                # Guía principal del proyecto
```

---

## 🗄️ Modelado de Base de Datos (PostgreSQL 16+)

El esquema de base de datos se ha diseñado bajo los siguientes principios:
1. **Desacoplamiento Catálogos / Transacciones:** Mantiene separados los datos maestros (Ubigeos, Organizaciones Políticas, Candidaturas) de las transacciones (Actas, Votos, Evidencias, Auditoría).
2. **Niveles Electorales Polimórficos (`electoral_levels`):** Soporta dinámicamente cargos regionales (Gobernador, Consejero), provinciales (Alcalde, Regidores) y distritales sin columnas rígidas.
3. **Offline-First & Idempotencia (`sync_operations`):** Utiliza `client_operation_id` (UUID) para evitar duplicados en reintentos de red.
4. **Human-In-The-Loop:** OCR/IA sólo propone valores con grados de confianza (`confidence`); la confirmación final la realiza el personero humano.

Para más detalle, consulta [docs/database_modeling.md](docs/database_modeling.md) y el script [database/schema_v1_postgres.sql](database/schema_v1_postgres.sql).

---

## 🚀 Fases de Implementación

- **Fase 0 — Foundation:** Infraestructura, PostgreSQL, Sanctum, Redis, Ubigeo y Datos Maestros del JEE (`erm2026.db`).
- **Fase 1 — Ingesta de Actas:** Flujo offline-first en Flutter, captura manual/asistida, evidencia fotográfica en R2, sincronización idempotente.
- **Fase 2 — Consolidación y Realtime:** Dashboard en Vue 3, consolidados por Ubigeo/Nivel y transmisión vía Laravel Reverb.
- **Fase 3 — Hardening:** Pruebas de concurrencia, simulación de carga masiva, auditoría y recuperación ante desastres.

---

## 📄 Licencia y Propiedad
Proyecto para la ingesta y consolidación electoral ERM 2026 — Perú.
