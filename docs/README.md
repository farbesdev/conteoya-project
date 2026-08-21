# ConteoYA — Centro de Documentación Técnica

> **Ecosistema:** ConteoYA — Plataforma de Ingesta, Validación y Consolidación Electoral  
> **Dominio:** Elecciones Regionales y Municipales 2026 (ERM 2026) — Perú  
> **Estándar:** Fusión de **arc42** (Estructura y Rigor Arquitectural) y **Diátaxis Framework** (Orientación por Necesidad del Lector).

---

## 🗺️ Mapa de Navegación de la Documentación

La documentación está organizada en **7 módulos temáticos** estructurados en español:

| Módulo | Enfoque Diátaxis / Arc42 | Descripción y Contenido |
|---|---|---|
| [**`00-arquitectura/`**](00-arquitectura/) | **Explicación / Arc42 §1-4, §7, §9-11** | Visión general del sistema, objetivos, restricciones de negocio, registro de decisiones (ADRs) y topología cloud. |
| [**`01-modulos/`**](01-modulos/) | **Referencia / Arc42 §5, §6** | Desglose por componentes: Backend API (Laravel 12), App Móvil (Flutter), Base de Datos (PostgreSQL 16) y Motor de Sincronización. |
| [**`02-integraciones/`**](02-integraciones/) | **Referencia / Integraciones Cloud** | Almacenamiento privado Cloudflare R2 (S3) con URLs presignadas y Adaptador OCR/IA (Human-in-the-Loop). |
| [**`03-guias/`**](03-guias/) | **Tutoriales & How-To Guides** | Puesta en marcha local paso a paso, cómo registrar actas de forma idempotente y cómo consultar la plantilla de la cédula. |
| [**`04-plantillas/`**](04-plantillas/) | **Plantillas Operativas** | Plantilla estándar para Registro de Decisiones de Arquitectura (ADRs). |
| [**`05-seguridad/`**](05-seguridad/) | **Explicación & Reglas Críticas** | Control de acceso por roles (RBAC), verificación de propiedad de mesa, idempotencia estricta y bitácora de auditoría. |
| [**`06-glosario/`**](06-glosario/) | **Referencia / Arc42 §12** | Glosario unificado de términos del proceso electoral peruano (ERM 2026), ubigeos y siglas. |

---

## 🧭 Rutas de Lectura Sugeridas según el Rol

### 👨‍💻 Para Desarrolladores Backend (Laravel 12 / PHP)
1. [`03-guias/instalacion-local.md`](03-guias/instalacion-local.md) — Configurar el entorno local en 5 minutos.
2. [`01-modulos/api-backend.md`](01-modulos/api-backend.md) — Estructura de controladores, policies, form requests y DTOs.
3. [`01-modulos/modelado-base-datos.md`](01-modulos/modelado-base-datos.md) — Esquema relacional, vistas y función almacenada.
4. [`05-seguridad/control-acceso-auditoria.md`](05-seguridad/control-acceso-auditoria.md) — Reglas de roles e idempotencia.

### 📱 Para Desarrolladores Móviles (Flutter / Dart)
1. [`03-guias/instalacion-local.md`](03-guias/instalacion-local.md) — Setup de la app móvil.
2. [`01-modulos/app-movil.md`](01-modulos/app-movil.md) — Clean Architecture, Riverpod y base de datos local Drift SQLite.
3. [`01-modulos/motor-sincronizacion.md`](01-modulos/motor-sincronizacion.md) — Máquina de estados del `SyncEngine` y backoff exponencial.
4. [`02-integraciones/cloudflare-r2.md`](02-integraciones/cloudflare-r2.md) — Cálculo de SHA-256 local y upload directo a R2.

### 💻 Para Desarrolladores Frontend Web (Vue 3.5 / TypeScript)
1. [`03-guias/instalacion-local.md`](03-guias/instalacion-local.md) — Setup del entorno web con Vite.
2. [`01-modulos/frontend-web.md`](01-modulos/frontend-web.md) — Arquitectura Vue 3, Pinia stores, control de tiempo real y build para producción.
3. [`05-seguridad/control-acceso-auditoria.md`](05-seguridad/control-acceso-auditoria.md) — Gestión de autenticación por tokens Sanctum.

### 🏛️ Para Arquitectos de Software y Líderes Técnicos
1. [`00-arquitectura/vision-general.md`](00-arquitectura/vision-general.md) — Objetivos de calidad, diagramas de contexto y alcance.
2. [`00-arquitectura/decisiones-diseno-adrs.md`](00-arquitectura/decisiones-diseno-adrs.md) — Registro histórico de decisiones técnicas.
3. [`00-arquitectura/despliegue-infraestructura.md`](00-arquitectura/despliegue-infraestructura.md) — Topología y resiliencia en la nube.

