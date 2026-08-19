# 01 — Módulo: Backend API (Laravel 12)

> **Módulo:** API Backend  
> **Tecnología:** Laravel 12 · PHP 8.2+ · Laravel Sanctum · Dedoc Scramble · PostgreSQL 16+ · Redis

---

## 1. Arquitectura en Capas

El backend sigue los principios de Clean Architecture y Domain-Driven Design simplificado:

```text
api/app/
├── Contracts/              # Interfaces de almacenamiento (StorageProviderInterface) y OCR
├── Domain/                 # Servicios de dominio y DTOs de negocio
│   ├── Acts/               # ActService, ActValidationService, DTOs
│   └── Evidence/           # EvidenceService, DTOs
├── Http/
│   ├── Controllers/Api/V1/ # Controladores delgados (ActController, PersoneroController, etc.)
│   ├── Middleware/         # IdempotencyMiddleware, Throttle
│   ├── Requests/           # Form Requests con validación estricta y autorización
│   └── Resources/          # API Resources para serialización de respuestas
├── Infrastructure/         # Implementaciones concretas de Storage (Cloudflare R2) y OCR
├── Jobs/                   # Procesamiento asíncrono en colas (ProcessSyncOperationJob)
├── Models/                 # Modelos Eloquent con relaciones tipadas
├── Policies/               # Autorización de acceso por usuario y propiedad de mesa
└── Providers/              # AppServiceProvider, QueryMacroServiceProvider
```

---

## 2. Búsqueda Agnóstica Case-Insensitive (`QueryMacroServiceProvider`)

Para garantizar compatibilidad universal con **PostgreSQL 16**, **SQLite** (pruebas automatizadas) y **MySQL**, se implementó el proveedor de macros [`QueryMacroServiceProvider`](file:///home/fredy/Documents/Proyectos/conteoya-project/api/app/Providers/QueryMacroServiceProvider.php):

* **`whereAnyInsensitive(array $columns, ?string $value)`**: Construye consultas parametrizadas con `LOWER(columna) LIKE ?` utilizando marcadores posicionales PDO `?`.
* **`orWhereAnyInsensitive(array $columns, ?string $value)`**: Variante disyuntiva para encadenamiento fluido.
* **Soporte Multi-Término (*Tokens*):** Si el usuario busca términos desordenados o compuestos (ej. `"Carlos Perez"`), la macro evalúa la coincidencia de todos los términos dentro de los campos seleccionados.
* **Seguridad:** 100% libre de inyección SQL al delegar el binding al driver PDO de Laravel.

---

## 3. Flujo de Controladores y Servicios

1. **Recepción del Request:** El `FormRequest` valida los tipos de datos y ejecuta `authorize()` validando el rol y la asignación de mesa (`ActPolicy`).
2. **Middleware de Idempotencia:** Intercepta si viene `Idempotency-Key` o `client_operation_id`. Si ya fue procesado, devuelve la respuesta cacheada sin re-ejecutar.
3. **Servicio de Dominio (`ActService`):** Ejecuta la transacción ACID en base de datos (`Act::updateOrCreate`, `ActTotal`, `ActResult`).
4. **Validación de Totales:** `ActValidationService` comprueba la cuadratura matemática sin bloquear la ingesta (genera `warnings`).
5. **Auditoría:** Registra la acción en `audit_logs`.

---

## 4. Controladores Principales

| Controlador | Propósito | Roles Permitidos |
|---|---|---|
| `AuthController` | Inicio de sesión (con email o DNI), perfil `/me`, logout y cambio de contraseña | Público / Autenticado |
| `ActController` | Ingesta, borrador, confirmación y consulta de actas electorales | `PERSONERO`, `ADMIN`, `DIRECTOR` |
| `PersoneroController` | Listado y búsqueda paginada agnóstica de personeros, consulta de mesas asignadas y activación/desactivación de acceso | `ADMIN`, `DIRECTOR` (listado) / `PERSONERO` (mesas) |
| `UserController` | CRUD de usuarios, reseteo de contraseñas y búsqueda agnóstica | `ADMIN`, `DIRECTOR` |
| `PollingStationController` | Consulta paginada de mesas, filtrado geográfico y búsqueda agnóstica | Autenticado |
| `CatalogController` | Departamentos, provincias, distritos, listas electorales y plantilla de cédula (`/ballot-template`) | Autenticado |
| `EvidenceController` | Generación de URLs presignadas para subida directa a Cloudflare R2 y confirmación de evidencias con SHA-256 | `PERSONERO`, `ADMIN`, `DIRECTOR` |
| `RecognitionController` | OCR/IA multimodal de actas (Human-in-the-Loop) | `PERSONERO`, `ADMIN`, `DIRECTOR` |
| `SyncController` | Motor de sincronización bidireccional push/pull con caché Redis | `PERSONERO`, `ADMIN`, `DIRECTOR` |
