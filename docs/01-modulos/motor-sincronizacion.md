# 01 — Módulo: Motor de Sincronización Offline-First (Sync Engine)

> **Módulo:** Sincronización Bidireccional  
> **Patrón:** Asynchronous Sync Engine · Exponential Backoff · Idempotencia

---

## 1. Ciclo de Vida de una Operación de Sincronización

Cada acción generada en la aplicación móvil crea un registro inmutable en `local_sync_operations_table` con un UUID generado en el cliente (`client_operation_id`).

```mermaid
stateDiagram-v2
    [*] --> PENDING: Mutación en App Móvil
    PENDING --> PROCESSING: SyncEngine detecta conexión
    PROCESSING --> SYNCED: HTTP 200/201 recibido
    PROCESSING --> FAILED: Error de red / Timeout
    FAILED --> RETRYING: Exponential Backoff (1s, 2s, 4s...)
    RETRYING --> PROCESSING: Intento agendado
    PROCESSING --> REJECTED: Error de negocio 403 / 422
    SYNCED --> [*]
```

---

## 2. Flujo de Sincronización de Actas y Evidencias

```mermaid
sequenceDiagram
    autonumber
    participant App as App Flutter
    participant Engine as Sync Engine
    participant API as Laravel 12 API
    participant R2 as Cloudflare R2

    App->>Engine: Encola Acta (client_operation_id: UUID)
    Engine->>API: POST /api/v1/acts (Payload con Idempotency-Key)
    API-->>Engine: 201 Created (ID Acta en Servidor)
    
    Engine->>API: POST /api/v1/acts/{id}/evidence/upload-url
    API-->>Engine: 200 OK (Presigned PUT URL)
    
    Engine->>R2: HTTP PUT (Binary Image Data)
    R2-->>Engine: 200 OK
    
    Engine->>API: POST /api/v1/acts/{id}/evidence/confirm (SHA-256)
    API-->>Engine: 200 OK
    Engine->>App: Marca Operación como SYNCED
```
