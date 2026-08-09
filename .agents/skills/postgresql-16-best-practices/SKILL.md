---
name: postgresql-16-best-practices
description: Experto y buenas prácticas en PostgreSQL 16+, incluyendo optimizaciones, tipos de datos, particionamiento, índices e integridad declarativa.
---

# Experto y Buenas Prácticas en PostgreSQL 16+

## Directrices Técnicas
1. **Tipos de Datos Modernos & Claridad Semántica:**
   - Usar `UUID` (o `BIGINT` autonumérico / `GENERATED ALWAYS AS IDENTITY`) para claves primarias relacionales.
   - Usar `TIMESTAMPTZ` para todos los campos temporales (`created_at`, `updated_at`, `captured_at`, `confirmed_at`).
   - Usar `JSONB` para esquemas semiestructurados (OCR outputs, metadatos extensibles) con índices GIN si son consultables.
   - Usar `VARCHAR(n)` o `TEXT` con restricciones `CHECK` para enumeraciones flexibles o tipos `ENUM` de PostgreSQL.
2. **Integridad Referencial & Restricciones Declarativas:**
   - Aplicar `FOREIGN KEY` con acciones de borrado/actualización explícitas (`ON DELETE RESTRICT` / `ON DELETE CASCADE`).
   - Usar `CHECK` constraints para reglas de negocio críticas a nivel BD (ej: `votes >= 0`, `voters_who_voted <= registered_voters`).
   - Índices de unicidad (`UNIQUE`) compuestos para evitar duplicidad de actas por mesa y tipo de elección.
3. **Optimización de Consultas & Concurrencia:**
   - Crear índices `BTREE` en claves foráneas, columnas de filtrado frecuente (`status`, `election_id`, `polling_station_id`).
   - Usar `GENERATED ALWAYS AS (...) STORED` para campos calculados si fuera necesario o vistas materializadas para consolidación rápida.
   - Soporte nativo para transacciones aisladas e idempotencia.
