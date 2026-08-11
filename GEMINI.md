# GEMINI.md — ConteoYA Project Rules & Agent Instructions

> **Scope:** Este archivo aplica a todo el workspace `conteoya-project/`.
> Antigravity lo carga automáticamente en cada sesión de trabajo.

---

## 🗺️ Contexto del Proyecto

**ConteoYA** es una plataforma de misión crítica para la captura, validación y consolidación
de actas electorales en las Elecciones Regionales y Municipales 2026 (ERM 2026) — Perú.

### Stack activo

| Capa | Tecnología |
|------|-----------|
| Backend API | **Laravel 12** · PHP 8.2+ · Laravel Sanctum · Dedoc Scramble |
| Base de datos | **PostgreSQL 16+** |
| Cache / Queues | **Redis** |
| Almacenamiento | **Cloudflare R2** (S3-compatible, privado) |
| App Móvil | **Flutter 3.44** · Dart · SQLite · Drift |
| Frontend Web | Vue 3.5 · Vite 8 · Pinia *(Fase 2 — no iniciada)* |
| Realtime | Laravel Reverb *(Fase 2 — no iniciada)* |
| Docs API | Dedoc Scramble (OpenAPI 3.1) |

### Monorepo — estructura de carpetas

```
conteoya-project/
├── .agents/skills/        ← Skills de experto cargados bajo demanda
├── api/                   ← Backend Laravel 12 (código activo)
│   ├── app/
│   │   ├── Http/Controllers/Api/V1/
│   │   │   ├── AuthController.php
│   │   │   ├── CatalogController.php
│   │   │   └── PersoneroController.php
│   │   └── Models/
│   │       ├── Role.php · User.php · Personero.php · Device.php
│   │       └── Act · ActResult · ActTotal · ActEvidence · ...
│   ├── config/scramble.php
│   ├── database/migrations/   ← 6 migraciones aplicadas
│   └── database/seeders/      ← RoleSeeder · UserSeeder · JeeDatabaseSeeder
├── database/erm2026.db    ← Datos maestros JEE (SQLite fuente)
├── docs/                  ← Documentación técnica
│   ├── database_modeling.md
│   └── api_reference.md
└── specs/                 ← Especificaciones funcionales por fase
```

### Estado actual de desarrollo

| Fase | Estado | Descripción |
|------|--------|-------------|
| **Fase 0 — Foundation** | ✅ Completada | API base, PostgreSQL, Sanctum, Roles, Auth, Catálogos JEE |
| **Fase 1 — Ingesta** | 🔜 Próxima | Flutter offline-first, actas, evidencias R2, sync engine |
| **Fase 2 — Resultados** | ⏳ Pendiente | Dashboard Vue 3, realtime Reverb |
| **Fase 3 — Hardening** | ⏳ Pendiente | E2E, carga, auditoría |

---

## 🛠️ Skills Disponibles — Activar Antes de Implementar

Antes de escribir código en cualquier área, **leer el skill correspondiente**.

| Skill | Activar cuando... |
|-------|-------------------|
| `git-conventional-commits` | Antes de cualquier `git commit` o crear una rama |
| `postgresql-16-best-practices` | Diseño de tablas, índices, constraints, migraciones |
| `software-engineering-best-practices` | Arquitectura, patrones, offline-first, idempotencia |
| `flutter-dart-best-practices` | Cualquier código Flutter/Dart |
| `sqlite-drift-offline-first` | Tablas Drift, DAOs, sync local |
| `cloudflare-r2-s3-storage` | Upload de evidencias, presigned URLs |
| `laravel-api-fase1-ingesta` | Endpoints de ingesta: actas, sync, evidencia |
| `ocr-ia-adapter-pattern` | Integración OCR/IA, ActRecognitionService |
| `offline-first-sync-engine` | Motor de sincronización Flutter ↔ Laravel |

---

## 📏 Reglas Obligatorias — Backend (Laravel)

### Autenticación y Seguridad

- **SIEMPRE** usar `auth:sanctum` en rutas protegidas. Nunca omitir middleware de autenticación.
- **SIEMPRE** verificar ownership de mesa en Policies antes de procesar actas: un personero solo puede operar sus mesas asignadas.
- **NUNCA** exponer credenciales de R2/S3 al cliente móvil. Solo el backend genera presigned URLs.
- **SIEMPRE** registrar en `audit_logs`: quién, qué acción, qué entidad, IP, timestamp, dispositivo.
- El campo `role` en `users` y el modelo `Role` (tabla `roles` con FK `role_id`) son la fuente de verdad de roles. Los tres roles son: `ADMIN`, `DIRECTOR`, `PERSONERO`.

### Idempotencia

- **TODOS** los endpoints de escritura (`POST`, `PUT`, `PATCH`) deben soportar `Idempotency-Key` o `client_operation_id`.
- Si una operación ya fue procesada (misma `client_operation_id`), devolver la respuesta cacheada con `X-Idempotent-Replayed: true`. **Nunca duplicar**.
- Usar `IdempotencyMiddleware` para esto. No reinventar la rueda.

### Validaciones de Actas

- **NUNCA** bloquear el envío de un acta solo por inconsistencia de totales — son `warnings`, no errores `422`.
- La suma `votos_listas + blancos + nulos + impugnados` debe igualar `total_votes`. Si no, advertir.
- `voters_who_voted <= registered_voters` y `total_votes <= registered_voters`. Si no, advertir.
- **NUNCA** modificar automáticamente el valor ingresado por el personero.

### Estructura de Código

- Usar **Form Requests** para toda validación de entrada. Nunca validar en el controller directamente.
- Usar **API Resources** para toda serialización de respuesta. Nunca devolver Eloquent crudo.
- Usar **Policies** para toda autorización. Nunca usar `if ($user->role === ...)` en controladores.
- Usar **Services/UseCases** para lógica de negocio. Los controladores solo orquestan.
- Usar **Jobs** para procesamiento asíncrono (sync operations, OCR). Nunca bloquear el request.

### API y Documentación

- **SIEMPRE** mantener las anotaciones Scramble actualizadas: `@tags`, `@bodyParam`, `@response`, `@unauthenticated` en todos los controladores.
- **SIEMPRE** exportar `api.json` después de cambios en rutas o controladores: `php artisan scramble:export`.
- Versionar todos los endpoints bajo `/api/v1`. Futuras versiones irán en `/api/v2`.

### Base de Datos

- **NUNCA** bajar `schemaVersion` ni eliminar migraciones ya aplicadas.
- Usar `updateOrCreate` en seeders para hacerlos idempotentes.
- Aplicar `PRAGMA foreign_keys = ON` (en SQLite local) y respetar FKs en PostgreSQL.
- Índices en todas las claves foráneas y columnas de filtrado frecuente (`status`, `election_id`, `polling_station_id`).

---

## 📏 Reglas Obligatorias — Mobile (Flutter/Dart)

- **Null safety estricto**. Nunca usar `dynamic`. Nunca usar el operador `!` (bang) sin razón justificada.
- **Offline es el modo normal**. Toda acción del usuario debe funcionar sin red. La sync es siempre asíncrona.
- **La IA nunca confirma un acta**. OCR/AI solo propone valores. El personero siempre confirma.
- **SHA-256 del archivo de evidencia se calcula en el cliente** antes de guardarlo localmente y antes de subirlo.
- **`client_operation_id`** es un UUID generado en el cliente para cada `SyncOperation`. Nunca generado por el servidor.
- **Clean Architecture** obligatoria: Domain → Data → Presentation. Las capas no se pueden saltear.
- **Riverpod** para state management. Nunca `setState` para estado global.
- Preferir `sealed class` de Dart 3 para modelar estados exhaustivos.

---

## 📏 Reglas de Commits (siempre)

Leer el skill `git-conventional-commits` antes de cualquier commit.

```
<emoji> <tipo>(<scope>): <descripción en español>
```

Scopes del proyecto:
- `api` — Backend Laravel
- `mobile` — Flutter app
- `database` — Migraciones y seeders
- `docs` — Documentación
- `specs` — Especificaciones ADR/prompts
- `config` — Configuración de herramientas

**NUNCA** hacer commit directo a `main` o `develop`.

---

## ⛔ Restricciones Absolutas

Estas restricciones NO tienen excepciones:

1. **La IA nunca confirma un acta electoral.** Es un principio de negocio inviolable. OCR/AI produce `source: AI|OCR` + `confidence`. El personero siempre confirma.
2. **El bucket R2 nunca es público.** Todo acceso a evidencias es mediante presigned URLs con TTL máximo de 1 hora para descarga, 15 minutos para subida.
3. **No implementar Fase 2 ni Fase 3** hasta que el usuario indique explícitamente que Fase 1 está terminada y aceptada.
4. **No eliminar ni revertir migraciones** ya aplicadas en la base de datos sin aprobación explícita del usuario.
5. **No exponer credenciales** (R2 keys, API keys OCR, Sanctum tokens) en logs, respuestas de API o código fuente.
6. **Un personero no puede registrar actas de mesas no asignadas.** Verificar siempre en `authorize()` del FormRequest y en la Policy.
7. **No usar `dynamic` en código Dart** bajo ninguna circunstancia.

---

## ✅ Obligaciones / Deberes del Agente

Antes de entregar cualquier cambio, o cuando el usuario solicite un **commit** o **push**:

- [ ] **Verificación Automática UI/UX (`ui-ux-pro-max`)**: Inspeccionar la interfaz móvil/web para verificar estándares visuales, contraste WCAG AAA, touch targets ≥ 44pt y micro-interacciones.
- [ ] **Code Review & Quality Gate (`code-review-and-quality`)**: Ejecutar la suite completa de pruebas y analizadores en todos los módulos (`php artisan test` en `api/` y `flutter analyze` + `flutter test` en `mobile/`). No realizar commit si hay fallas.
- [ ] Leer el skill correspondiente a la tecnología modificada.
- [ ] Actualizar anotaciones Scramble y exportar `api.json` si se modifican rutas/controladores en `api/`.
- [ ] Actualizar `docs/api_reference.md` si se agregan, modifican o eliminan endpoints.
- [ ] Actualizar `docs/database_modeling.md` si se agregan nuevas tablas o relaciones.
- [ ] Crear o actualizar `README.md` de cada subproyecto si cambia la forma de instalación/uso.
- [ ] Hacer commit con mensaje semántico correcto (skill `git-conventional-commits`).
- [ ] Nunca dejar `TODO`, `FIXME`, credenciales hardcodeadas ni `console.log`/`dd()`/`dump()` en el código entregado.

---

## 🔑 Credenciales de Prueba (solo desarrollo)

| Email | Password | Rol |
|-------|----------|-----|
| `admin@conteoya.pe` | `Admin123!` | `ADMIN` |
| `director@conteoya.pe` | `Director123!` | `DIRECTOR` |
| `personero@conteoya.pe` | `Personero123!` | `PERSONERO` |

> ⚠️ Cambiar antes de staging/producción. Nunca hardcodear en código fuente.

---

## 📖 Documentación de Referencia

| Documento | Descripción |
|-----------|-------------|
| [README.md raíz](./README.md) | Visión general, stack, fases, setup rápido |
| [api/README.md](./api/README.md) | Instalación, migraciones, seeders, endpoints, comandos |
| [docs/database_modeling.md](./docs/database_modeling.md) | Modelado conceptual/lógico/físico de BD |
| [docs/api_reference.md](./docs/api_reference.md) | Referencia completa de endpoints con ejemplos |
| [specs/CONTEOYA_PROPUESTA_FASES_ERM2026.md](./specs/CONTEOYA_PROPUESTA_FASES_ERM2026.md) | Propuesta completa de fases |
| [specs/CONTEOYA_PROMPT_FASE0_FOUNDATION.md](./specs/CONTEOYA_PROMPT_FASE0_FOUNDATION.md) | Spec Fase 0 |
| [specs/CONTEOYA_PROMPT_FASE1_INGESTA.md](./specs/CONTEOYA_PROMPT_FASE1_INGESTA.md) | Spec Fase 1 |
