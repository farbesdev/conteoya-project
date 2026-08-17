# 01 — Módulo: Backend API (Laravel 12)

> **Módulo:** API Backend  
> **Tecnología:** Laravel 12 · PHP 8.2+ · Laravel Sanctum · Dedoc Scramble

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
│   ├── Controllers/Api/V1/ # Controladores delgados (ActController, CatalogController, etc.)
│   ├── Middleware/         # IdempotencyMiddleware, Throttle
│   ├── Requests/           # Form Requests con validación estricta y autorización
│   └── Resources/          # API Resources para serialización de respuestas
├── Infrastructure/         # Implementaciones concretas de Storage (Cloudflare R2) y OCR
├── Jobs/                   # Procesamiento asíncrono en colas (ProcessSyncOperationJob)
├── Models/                 # Modelos Eloquent con relaciones tipadas
└── Policies/               # Autorización de acceso por usuario y propiedad de mesa
```

---

## 2. Flujo de Controladores y Servicios

1. **Recepción del Request:** El `FormRequest` valida los tipos de datos y ejecuta `authorize()` validando el rol y la asignación de mesa (`ActPolicy`).
2. **Middleware de Idempotencia:** Intercepta si viene `Idempotency-Key` o `client_operation_id`. Si ya fue procesado, devuelve la respuesta cacheada sin re-ejecutar.
3. **Servicio de Dominio (`ActService`):** Ejecuta la transacción ACID en base de datos (`Act::updateOrCreate`, `ActTotal`, `ActResult`).
4. **Validación de Totales:** `ActValidationService` comprueba la cuadratura matemática sin bloquear la ingesta (genera `warnings`).
5. **Auditoría:** Registra la acción en `audit_logs`.
