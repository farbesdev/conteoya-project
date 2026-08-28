# CLAUDE.md — ConteoYA Project Rules for Claude

> **Scope:** Este archivo es la fuente de verdad para Claude (claude.ai, Claude Code, Cursor con Claude)
> cuando trabaja en el workspace `conteoya-project/`.
> Su contenido es equivalente a `GEMINI.md` pero adaptado al formato y convenciones de Claude.

---

## 🗺️ Proyecto: ConteoYA

Plataforma de **misión crítica** para captura, validación y consolidación de actas electorales
en las Elecciones Regionales y Municipales 2026 (ERM 2026) — Perú.

### Stack tecnológico

```
Backend:   Laravel 12 · PHP 8.2+ · PostgreSQL 16+ · Redis · Laravel Sanctum
Docs API:  Dedoc Scramble (OpenAPI 3.1)
Storage:   Cloudflare R2 (S3-compatible, SIEMPRE privado)
Mobile:    Flutter 3.44 · Dart · SQLite · Drift (offline-first)
Frontend:  Vue 3.5 · Pinia · Vite 8  ← Fase 2, NO iniciada
Realtime:  Laravel Reverb              ← Fase 2, NO iniciada
```

### Monorepo — directorios clave

```
conteoya-project/
├── GEMINI.md              ← Reglas para Antigravity/Gemini
├── CLAUDE.md              ← Reglas para Claude (este archivo)
├── .agents/skills/        ← Skills de experto por tecnología
├── api/                   ← Backend Laravel 12 (activo)
│   ├── app/Contracts/                   Interfaces Storage y OCR
│   ├── app/Domain/Acts · Domain/Evidence Services, DTOs
│   ├── app/Http/Controllers/Api/V1/     AuthController · ActController · EvidenceController ·
│   │                                    RecognitionController · SyncController · UserController ·
│   │                                    CatalogController · PersoneroController
│   ├── app/Infrastructure/Ocr · Storage/  Providers OCR y R2
│   ├── app/Jobs/                         ProcessSyncOperationJob
│   ├── app/Middleware/                   IdempotencyMiddleware
│   ├── app/Policies/                     ActPolicy · EvidencePolicy
│   ├── app/Models/                       Role · User · Personero · Device · Act · ...
│   ├── config/scramble.php               Configuración OpenAPI
│   ├── database/migrations/              7 migraciones aplicadas en PostgreSQL
│   └── database/seeders/                 RoleSeeder · UserSeeder · JeeDatabaseSeeder
├── mobile/                ← App Flutter 3.44 (activo)
│   └── lib/
│       ├── core/database/  Drift schema v4, 8 tablas locales
│       ├── core/sync/      SyncEngine + BackoffCalculator
│       └── features/       acts · auth · dashboard · mesas · ocr_ai · personeros · sync · users
├── database/erm2026.db    ← Fuente SQLite con datos maestros JEE
├── docs/
│   ├── database_modeling.md
│   └── api_reference.md
└── specs/                 ← Specs funcionales por fase (NO modificar sin aprobación)
```

---

## 📊 Estado Actual del Proyecto

### Fase 0 — Foundation ✅ COMPLETADA

Lo implementado:

**Base de datos (PostgreSQL 16+):**
- Tabla `roles` — 3 registros: `ADMIN` (id:1), `DIRECTOR` (id:2), `PERSONERO` (id:3)
- Tabla `users` — con `role` (string) + `role_id` (FK → roles)
- Tablas del dominio geográfico: `departments`, `provinces`, `districts`, `electoral_locations`, `polling_stations`
- Tablas electorales: `elections`, `electoral_levels`, `political_organizations`, `electoral_lists`, `candidates`, `candidacies`
- Dominio personeros: `personeros`, `devices`, `personero_polling_station`
- Dominio actas (esquema listo, sin endpoints aún): `acts`, `act_totals`, `act_results`, `act_evidence`, `ocr_ai_extractions`
- Dominio sync/auditoría: `sync_operations`, `audit_logs`

**API activa (Base URL: /api/v1):**

| Método | Endpoint | Auth | Descripción |
|--------|----------|------|-------------|
| `POST` | `/login` | Pública | Devuelve Bearer token + usuario + objeto rol |
| `GET` | `/me` | Bearer | Perfil del usuario autenticado |
| `POST` | `/logout` | Bearer | Revoca el token |
| `GET` | `/personero/polling-stations` | Bearer | Mesas asignadas al personero |
| `GET` | `/departments` | Bearer | Catálogo departamentos (caché 24h) |
| `GET` | `/provinces` | Bearer | Catálogo provincias (caché 24h) |
| `GET` | `/districts` | Bearer | Catálogo distritos (caché 24h) |
| `GET` | `/elections` | Bearer | Elecciones con niveles electorales (caché 24h) |
| `GET` | `/political-organizations` | Bearer | Orgs. políticas (caché 12h) |
| `GET` | `/electoral-lists` | Bearer | Listas electorales paginadas (caché 1h) |

**Documentación:** `GET /docs/api` (Scramble interactive) · `GET /docs/api.json`

### Fase 1 — Ingesta 🟡 EN PROGRESO

**Endpoints activos (Fase 1):**

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| `GET/POST/PUT/DELETE` | `/users` | CRUD de usuarios (ADMIN/DIRECTOR) |
| `POST` | `/acts` | Registrar acta (idempotente, `Idempotency-Key`) |
| `GET` | `/acts/{id}` | Ver acta con totales, resultados y evidencias |
| `POST` | `/acts/{id}/confirm` | Confirmar acta |
| `POST` | `/acts/{id}/evidence/upload-url` | Presigned PUT URL en R2 (TTL 15min) |
| `POST` | `/acts/{id}/evidence/confirm` | Registrar evidencia tras subida |
| `GET` | `/acts/{id}/evidence/{eid}/download` | Presigned GET URL (TTL 60min) |
| `POST` | `/acts/recognize` | OCR/IA sobre imagen de acta |
| `POST` | `/sync` | Enviar lote de operaciones offline |
| `GET` | `/sync/pull` | Descargar actualizaciones del servidor |
| `GET` | `/sync/status` | Estado de sincronización del personero |

**App Móvil Flutter:**
- Drift schema v4, 8 tablas locales
- SyncEngine offline-first con exponential backoff
- Features: acts, auth, dashboard, mesas, ocr_ai, personeros, sync, users

### Fase 2 y 3 — ⏳ NO iniciar

---

## 🧰 Skills Disponibles

Lee el `SKILL.md` del skill correspondiente **antes** de escribir código en esa área.
Están en `.agents/skills/<nombre>/SKILL.md`.

| Skill | Cuándo activar |
|-------|----------------|
| `git-conventional-commits` | **Siempre** antes de cualquier commit |
| `postgresql-16-best-practices` | Diseñar/modificar tablas, índices, constraints |
| `software-engineering-best-practices` | Decisiones de arquitectura, patrones, offline |
| `flutter-dart-best-practices` | Código Flutter o Dart |
| `sqlite-drift-offline-first` | Tablas Drift, DAOs, sincronización local |
| `cloudflare-r2-s3-storage` | Subida de evidencias, presigned URLs |
| `laravel-api-fase1-ingesta` | Endpoints de ingesta: actas, sync, evidencia |
| `ocr-ia-adapter-pattern` | ActRecognitionService, providers OCR/IA |
| `offline-first-sync-engine` | Motor de sync Flutter ↔ Laravel |

---

## 📐 Arquitectura y Patrones Obligatorios

### Backend Laravel 12

```
Controller (orquesta)
  └── FormRequest (valida + autoriza)
  └── Policy (ownership, roles)
  └── Service/UseCase (lógica de negocio)
        └── Repository / Eloquent Model
  └── Job (asíncrono: sync, OCR)
  └── API Resource (serialización)
  └── Event (notificaciones)
```

**Reglas de capas:**
- Nunca validar en el controller — usar `FormRequest`.
- Nunca serializar Eloquent crudo — usar `JsonResource`.
- Nunca autorizar con `if ($user->role === ...)` en controllers — usar `Policy` y `Gate`.
- Nunca hacer lógica de negocio en el controller — usar `Service`.
- Nunca bloquear el request con operaciones lentas — usar `Job` + `Queue`.

### Mobile Flutter (Fase 1)

```
Presentation (Widgets + Riverpod Notifiers)
  └── Domain (UseCases + Entities + Repository interfaces)
  └── Data (Repository impls + DataSources)
        ├── Remote (Dio + API)
        └── Local (Drift DAOs)
```

**Reglas de capas:**
- Domain no importa Flutter, Drift ni Dio — solo Dart puro.
- Los Widgets no acceden a DataSources directamente.
- Toda operación que puede fallar devuelve `Either<Failure, T>`.

---

## ⚙️ Workflows por Área

### Cuando se modifica una ruta o controller

1. Actualizar anotaciones Scramble en el controller (`@tags`, `@bodyParam`, `@response`).
2. Ejecutar `php artisan scramble:export` → actualiza `api/api.json`.
3. Actualizar `docs/api_reference.md` con el nuevo endpoint.
4. Commit: `📝 docs(api): ...` + `✨ feat(api): ...` separados.

### Cuando se agrega una migración

1. Leer skill `postgresql-16-best-practices`.
2. Crear con `php artisan make:migration`.
3. Aplicar: `php artisan migrate`.
4. Actualizar `docs/database_modeling.md` con la nueva tabla/campo.
5. Actualizar el `api/README.md` (tabla de migraciones).
6. Commit: `🏗️ build(database): ...`.

### Cuando se agrega un seeder

1. Hacerlo idempotente con `updateOrCreate` (nunca `create` directo).
2. Registrarlo en `DatabaseSeeder` en el orden correcto.
3. Probar: `php artisan db:seed --class=NuevoSeeder`.
4. Commit: `🔧 chore(database): ...`.

### Cuando se hace commit

1. Leer skill `git-conventional-commits`.
2. Formato obligatorio: `<emoji> <tipo>(<scope>): <descripción en español>`.
3. Referencias a specs cuando aplique: `Refs: specs/CONTEOYA_PROMPT_FASE1_INGESTA.md`.
4. **NUNCA** commit directo a `main`. Usar ramas `feature/<scope>/<descripcion>`.

---

## ⛔ Restricciones Absolutas (SIN excepciones)

### 1. La IA/OCR nunca confirma un acta electoral
El campo `source` puede ser `MANUAL`, `OCR` o `AI`. Los valores con `source: AI` o `source: OCR`
son **propuestas**. El campo `acts.status` solo pasa a `CONFIRMED` cuando el personero
hace `POST /acts/{act}/confirm` manualmente. Este principio es **inviolable**.

### 2. El bucket R2 es siempre privado
`visibility: private`. Sin ACLs públicas. Sin URLs directas al bucket.
Solo presigned URLs con TTL: upload ≤ 15min, download ≤ 1h.

### 3. No adelantar fases sin instrucción explícita
No escribir código de Fase 2 (Vue, Reverb) ni Fase 3 (hardening) hasta que el usuario
dé la instrucción. No mezclar código de fases futuras en la implementación de Fase 1.

### 4. No eliminar migraciones aplicadas
Las migraciones son inmutables una vez aplicadas en cualquier ambiente.
Si es necesario un cambio, crear una nueva migración.

### 5. Ownership de mesa siempre verificado
Un personero **nunca** puede operar (crear/confirmar/subir evidencia) en mesas no asignadas.
Verificar en `FormRequest::authorize()` Y en `Policy`. Doble verificación obligatoria.

### 6. No exponer secretos
No hardcodear en código: tokens Sanctum, R2 access keys, API keys OCR/IA, contraseñas.
Todo va en `.env`. El `.env` nunca se commitea.

### 7. No usar `dynamic` en Dart
Todo el código Flutter/Dart debe ser completamente type-safe.

---

## ✅ Checklist Pre-Entrega (obligatorio antes de cada respuesta con código)

**Backend:**
- [ ] Form Request para toda entrada de datos
- [ ] Policy para toda autorización
- [ ] API Resource para toda respuesta
- [ ] Anotaciones Scramble actualizadas
- [ ] `api.json` exportado si cambiaron rutas
- [ ] Audit log registrado para acciones de escritura
- [ ] Idempotency-Key soportado en endpoints de escritura
- [ ] `docs/api_reference.md` actualizado

**Mobile:**
- [ ] Null safety estricto (sin `dynamic`, sin `!` injustificado)
- [ ] Clean Architecture respetada (Domain sin dependencias externas)
- [ ] `Either<Failure, T>` para operaciones que pueden fallar
- [ ] `client_operation_id` UUID generado en cliente para sync operations
- [ ] SHA-256 calculado antes de guardar evidencia localmente

**General:**
- [ ] Tests escritos o actualizados
- [ ] Sin `dd()`, `dump()`, `print()`, `debugPrint()` en código de producción
- [ ] Sin credenciales hardcodeadas
- [ ] Commit semántico correcto (skill: `git-conventional-commits`)
- [ ] Documentación actualizada si aplica

---

## 🔑 Usuarios de Prueba (solo desarrollo)

> ⚠️ Cambiar contraseñas antes de cualquier ambiente no-local.

```
admin@conteoya.pe                    / Admin123!     → ADMIN     (role_id: 1)
director@conteoya.pe                 / Director123!  → DIRECTOR  (role_id: 2)
personero@conteoya.pe  / [dni]       / [dni]!        → PERSONERO (role_id: 3, ej: 77889900!)
```

El usuario `personero@conteoya.pe` tiene un registro en `personeros` (DNI: `77889900`, password: `77889900!`). Todo personero tiene como contraseña por defecto su `[dni]!`.

---

## 🧠 Contexto de Dominio Electoral

- **ERM 2026** — Proceso electoral: código `ERM2026`, fecha `2026-10-04`, status `PLANNED`.
- **Acta electoral** — Documento oficial por mesa (`polling_station`) + elección + nivel electoral. Clave única: `(polling_station_id, election_id, electoral_level_id)`.
- **Personero** — Fiscal de partido asignado a una o más mesas de sufragio.
- **Niveles electorales** — `REGIONAL_GOBERNADOR`, `PROVINCIAL_ALCALDE`, `DISTRITAL_ALCALDE`, etc. Dinámicos, no columnas rígidas.
- **client_operation_id** — UUID de idempotencia generado en el dispositivo móvil. El servidor lo trata como idempotency key: igual key = misma operación, no duplicar.
- **SHA-256 de evidencia** — Hash del archivo de fotografía del acta. Garantiza integridad e inmutabilidad.

---

## 📖 Referencias Clave

| Documento | Path |
|-----------|------|
| Visión general | `README.md` |
| Backend setup | `api/README.md` |
| Modelado BD | `docs/database_modeling.md` |
| Endpoints API | `docs/api_reference.md` |
| Spec Fase 0 | `specs/CONTEOYA_PROMPT_FASE0_FOUNDATION.md` |
| Spec Fase 1 | `specs/CONTEOYA_PROMPT_FASE1_INGESTA.md` |
| Propuesta general | `specs/CONTEOYA_PROPUESTA_FASES_ERM2026.md` |
