# 00 — Registro de Decisiones de Arquitectura (ADRs)

> **Documento:** Architectural Decision Records (ADRs)  
> **Proyecto:** ConteoYA — ERM 2026

---

### ADR-001: Selección de PostgreSQL 16 con Tipos JSONB
- **Contexto:** Se requiere un motor relacional de alto rendimiento que permita almacenar esquemas de resultados semiestructurados (OCR outputs, metadatos extensibles) y ejecutar agregaciones analíticas complejas.
- **Decisión:** Utilizar PostgreSQL 16+ con soporte nativo de `JSONB`, índices GIN, vistas SQL optimizadas y funciones almacenadas en `PL/pgSQL`.
- **Estado:** Aceptado e Implementado.

---

### ADR-002: Desacoplamiento de Centros de Votación mediante Vistas y Función Almacenada
- **Contexto:** En elecciones masivas, la tabla `electoral_locations` (locales físicos) puede estar incompleta o ausente al inicio. Las mesas (`polling_stations`) contienen los datos de ubicación directa (distrito, provincia, departamento).
- **Decisión:** Crear las vistas SQL `v_polling_stations_ubigeo` y `v_electoral_ballot_lists`, junto con la función `fn_get_polling_station_ballot(p_station_code, p_level_id)` que construye la plantilla de la cédula en un solo round-trip SQL.
- **Estado:** Aceptado e Implementado.

---

### ADR-003: Almacenamiento de Evidencias en Cloudflare R2 con URLs Presignadas
- **Contexto:** Las actas físicas fotografiadas requieren almacenamiento inalterable, confidencial y sin costos exorbitantes de transferencia (egress).
- **Decisión:** Utilizar Cloudflare R2 (S3-compatible) con bucket 100% privado. El backend genera URLs presignadas con TTL de 15 minutos para subida y 60 minutos para descarga. La app móvil calcula el hash SHA-256 local antes de transferir.
- **Estado:** Aceptado e Implementado.

---

### ADR-004: Persistencia Local en Flutter con Drift (SQLite) v5
- **Contexto:** La app móvil debe operar 100% offline en zonas sin cobertura. Se requiere una base de datos local robusta con soporte transaccional y migraciones de esquema seguras.
- **Decisión:** Implementar Drift (SQLite) v5 con tablas tipadas, índices de búsqueda y un motor de sincronización asíncrono (`SyncEngine`).
- **Estado:** Aceptado e Implementado.

---

### ADR-005: Idempotencia en Dos Niveles (Cliente / Servidor)
- **Contexto:** En condiciones de conectividad inestable, las peticiones HTTP pueden reenviarse múltiples veces generando riesgo de duplicidad de votos o actas.
- **Decisión:** Generar un UUID `client_operation_id` en el cliente para cada mutación y validar en el servidor mediante `IdempotencyMiddleware` con cache de respuestas y constraint `UNIQUE` en base de datos.
- **Estado:** Aceptado e Implementado.
