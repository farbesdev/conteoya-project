---
name: database-modeling-analysis-design
description: Experto y buenas prácticas en Modelado de Base de Datos: Fase de Análisis (Conceptual) y Fase de Diseño (Lógico y Físico).
---

# Experto y Buenas Prácticas en Modelado de Base de Datos

## Lifecycle del Modelado

### 1. Fase de Análisis (Modelo Conceptual)
- Identificación de Entidades de Dominio, Atributos clave y Relaciones (Cardinalidad 1:1, 1:N, N:M).
- Desacoplamiento de datos maestros (Ubigeo, Catálogo Electoral, Candidaturas) frente a datos transaccionales (Actas, Votos, Evidencias, Auditoría).
- Flexibilidad para múltiples niveles electorales (Gobernador Regional, Consejero Regional, Alcalde Provincial, Regidores, Alcalde Distrital, Regidores Distritales).

### 2. Fase de Diseño (Modelo Lógico)
- Normalización en 3FN (Tercera Forma Normal) para eliminar redundancias anómalas.
- Definición formal de Claves Primarias (PK), Claves Foráneas (FK) y Claves Alternativas/Candidatas (AK/UK).
- Resolución de relaciones N:M mediante tablas asociativas explícitas con significado de negocio (ej. `candidacies`, `personero_polling_station`).

### 3. Fase de Diseño Físico (PostgreSQL 16+)
- Mapeo de tipos de datos relacionales concretos (`BIGINT`, `VARCHAR`, `TIMESTAMPTZ`, `JSONB`, `NUMERIC`).
- Definición de Estrategias de Indización (B-tree, GIN), Nombres de Restricciones (FK, PK, UK, CHK), Triggers de timestamps (`updated_at`).
- Definición de scripts SQL DDL idempotentes (`CREATE TABLE IF NOT EXISTS`, `ALTER TABLE ... ADD CONSTRAINT`).
