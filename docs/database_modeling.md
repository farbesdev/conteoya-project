# ConteoYA — Documentación del Modelado de Base de Datos (Fases 0 y 1)

**Proyecto:** ConteoYA  
**Dominio:** Elecciones Regionales y Municipales 2026 (ERM 2026) — Perú  
**Motor Target:** PostgreSQL 16+  
**API Backend:** Laravel 12 + Sanctum + Dedoc Scramble  
**Última actualización:** Fase 0 — v0.1.0  

---

## 1. Introducción y Alcance

El presente documento establece el diseño y modelado integral de la base de datos relacional para la plataforma **ConteoYA**, cubriendo los requerimientos especificados para la **Fase 0 (Foundation / Datos Maestros)** y la **Fase 1 (Ingesta de Actas, Offline-First, Evidencia e Idempotencia)**.

### Principios Arquitecturales del Diseño:
1. **Desacoplamiento Catálogo / Transacción:** Separación estricta entre los datos maestros electorales (Ubigeo, Organizaciones, Candidaturas, Mesas) y la dinámica transaccional (Actas, Votos, Evidencias, Auditoría, Sincronización).
2. **Soporte Polimórfico de Niveles Electorales (Nivel Electoral Dinámico):** El modelo no utiliza columnas estáticas rígidas (como `votos_gobernador`, `votos_alcalde`). En su lugar, soporta de forma genérica niveles electorales (*REGIONAL_GOBERNADOR*, *REGIONAL_CONSEJERO*, *PROVINCIAL_ALCALDE*, *PROVINCIAL_REGIDOR*, *DISTRITAL_ALCALDE*, *DISTRITAL_REGIDOR*).
3. **Resiliencia Offline e Idempotencia:** Integración de claves de idempotencia (`client_operation_id`) y trazabilidad de sincronización desde clientes móviles (SQLite/Drift).
4. **Human-In-The-Loop & Auditability:** Distinción clara de la fuente de captura (`MANUAL`, `OCR`, `AI`, `IMPORTED`), almacenamiento de evidencia fotográfica inalterable con hashes SHA-256 y registro histórico completo de auditoría.

---

## 2. Fase de Análisis: Modelo Conceptual

En la fase de análisis conceptual se identifican las entidades clave agrupadas por dominios funcionales y sus interrelaciones de alto nivel.

```mermaid
erDiagram
    departments ||--|{ provinces : "contiene"
    departments ||--|{ districts : "contiene"
    provinces ||--|{ districts : "contiene"
    districts ||--|{ electoral_locations : "alberga"
    electoral_locations ||--|{ polling_stations : "pertenece"
    
    elections ||--|{ electoral_levels : "define"
    political_organizations ||--|{ electoral_lists : "postula"
    electoral_levels ||--|{ electoral_lists : "clasifica"
    departments ||--o{ electoral_lists : "delimita"
    provinces ||--o{ electoral_lists : "delimita"
    districts ||--o{ electoral_lists : "delimita"
    
    candidates ||--|{ candidacies : "postula en"
    electoral_lists ||--|{ candidacies : "integra"
    
    roles ||--|{ users : "asigna"
    users ||--o| personeros : "es"
    personeros ||--|{ devices : "registra"
    personeros ||--|{ personero_polling_station : "asigna"
    polling_stations ||--|{ personero_polling_station : "asigna"
    
    elections ||--|{ acts : "corresponde"
    electoral_levels ||--|{ acts : "evalua"
    polling_stations ||--|{ acts : "registra"
    personeros ||--|{ acts : "captura"
    
    acts ||--|| act_totals : "consolida"
    acts ||--|{ act_results : "desglosa"
    political_organizations ||--o{ act_results : "recibe"
    electoral_lists ||--o{ act_results : "recibe"
    candidates ||--o{ act_results : "recibe"
    
    acts ||--|{ act_evidence : "respalda"
    devices ||--o{ act_evidence : "captura"
    acts ||--o{ ocr_ai_extractions : "procesa"
    act_evidence ||--o{ ocr_ai_extractions : "analiza"
    
    personeros ||--o{ sync_operations : "sincroniza"
    devices ||--o{ sync_operations : "envia"
    users ||--o{ audit_logs : "audita"

    departments {
        string code PK
        string name
        timestamp created_at
        timestamp updated_at
    }

    provinces {
        string code PK
        string department_code FK
        string name
        timestamp created_at
        timestamp updated_at
    }

    districts {
        string code PK
        string province_code FK
        string department_code FK
        string name
        timestamp created_at
        timestamp updated_at
    }

    electoral_locations {
        bigint id PK
        string district_code FK
        string name
        string address
        decimal latitude
        decimal longitude
        timestamp created_at
        timestamp updated_at
    }

    polling_stations {
        bigint id PK
        bigint electoral_location_id FK
        string code
        int registered_voters
        string status
        string odpe
        string pdf_file
        int pdf_page
        string department_name
        string province_name
        string district_name
        timestamp created_at
        timestamp updated_at
    }

    elections {
        bigint id PK
        string code
        string name
        date date
        string status
        int jee_proceso_electoral_id
        timestamp created_at
        timestamp updated_at
    }

    electoral_levels {
        bigint id PK
        bigint election_id FK
        string code
        string name
        boolean has_preferential_vote
        timestamp created_at
        timestamp updated_at
    }

    political_organizations {
        bigint id PK
        int jee_id
        string name
        string short_name
        string org_type
        text logo_url
        text local_logo_url
        timestamp created_at
        timestamp updated_at
    }

    electoral_lists {
        bigint id PK
        int jee_solicitud_id
        bigint political_organization_id FK
        bigint electoral_level_id FK
        string department_code FK
        string province_code FK
        string district_code FK
        string status
        timestamp created_at
        timestamp updated_at
    }

    candidates {
        bigint id PK
        int jee_candidate_id
        string id_hoja_vida
        string document_number
        string full_name
        text photo_url
        text local_photo_url
        timestamp created_at
        timestamp updated_at
    }

    candidacies {
        bigint id PK
        bigint electoral_list_id FK
        bigint candidate_id FK
        string position
        int list_number
        string status
        timestamp created_at
        timestamp updated_at
    }

    roles {
        bigint id PK
        string name
        string display_name
        text description
        timestamp created_at
        timestamp updated_at
    }

    users {
        bigint id PK
        bigint role_id FK
        string name
        string email
        timestamp email_verified_at
        string password
        string role
        boolean is_active
        string remember_token
        timestamp created_at
        timestamp updated_at
    }

    personeros {
        bigint id PK
        bigint user_id FK
        bigint election_id FK
        bigint political_organization_id FK
        string document_number
        string full_name
        string first_name
        string email
        string personero_type
        int id_tipo_personero
        string phone_number
        string status
        string expediente_ext
        string codigo_declara
        int jee_personero_declara_id
        string political_organization_name
        string jee_name
        int jee_id
        string department_name
        string province_name
        string district_name
        string abogado_responsable
        timestamp created_at
        timestamp updated_at
    }

    devices {
        bigint id PK
        bigint personero_id FK
        string device_uuid
        string device_model
        string os_version
        string app_version
        timestamp last_active_at
        timestamp created_at
        timestamp updated_at
    }

    personero_polling_station {
        bigint id PK
        bigint personero_id FK
        bigint polling_station_id FK
        timestamp assigned_at
    }

    acts {
        bigint id PK
        bigint election_id FK
        bigint electoral_level_id FK
        bigint polling_station_id FK
        string act_code
        string status
        bigint captured_by_personero_id FK
        timestamp captured_at
        timestamp confirmed_at
        timestamp created_at
        timestamp updated_at
    }

    act_totals {
        bigint id PK
        bigint act_id FK
        int registered_voters
        int voters_who_voted
        int total_votes
        int blank_votes
        int null_votes
        int challenged_votes
        boolean is_valid_total
        timestamp created_at
        timestamp updated_at
    }

    act_results {
        bigint id PK
        bigint act_id FK
        bigint political_organization_id FK
        bigint electoral_list_id FK
        bigint candidate_id FK
        int votes
        string source
        decimal confidence
        timestamp created_at
        timestamp updated_at
    }

    act_evidence {
        bigint id PK
        bigint act_id FK
        bigint device_id FK
        string storage_provider
        text object_key
        string file_mime
        bigint file_size_bytes
        string sha256_hash
        int width_px
        int height_px
        timestamp captured_at
        timestamp created_at
        timestamp updated_at
    }

    ocr_ai_extractions {
        bigint id PK
        bigint act_id FK
        bigint act_evidence_id FK
        string provider_name
        jsonb raw_response_json
        jsonb extracted_data_json
        timestamp processed_at
    }

    sync_operations {
        bigint id PK
        uuid client_operation_id
        bigint device_id FK
        bigint personero_id FK
        string entity_type
        string entity_id
        string operation
        jsonb payload
        int attempts
        string status
        text last_error
        timestamp processed_at
        timestamp created_at
        timestamp updated_at
    }

    audit_logs {
        bigint id PK
        bigint user_id FK
        string action
        string entity_type
        string entity_id
        string ip_address
        text user_agent
        jsonb payload
        timestamp created_at
    }
```

### Entidades Identificadas por Dominio:

1. **Dominio Geográfico (Ubigeo Electoral):**
   - `departments`: Departamentos / Regiones del Perú.
   - `provinces`: Provincias.
   - `districts`: Distritos.
   - `electoral_locations`: Locales de votación (colegios, escuelas, recintos).
   - `polling_stations`: Mesas de sufragio (código de 6 dígitos ej: `030390`).

2. **Dominio Catálogo Electoral & Candidaturas:**
   - `elections`: Procesos electorales (ej. ERM 2026).
   - `electoral_levels`: Niveles de elección (Gobernador, Consejero, Alcalde Provincial, Regidor Provincial, Alcalde Distrital, Regidor Distrital).
   - `political_organizations`: Organizaciones políticas (partidos, movimientos regionales).
   - `candidates`: Personas naturales candidatas.
   - `electoral_lists`: Listas de candidatos presentadas ante el JEE.
   - `candidacies`: Relación asociativa candidato-lista-cargo-posición (voto preferencial/regiduria).

3. **Dominio Ingesta, Actas y Evidencia (Fase 1):**
   - `acts`: Encabezado de acta por mesa, elección y nivel electoral.
   - `act_results`: Desglose de votos por lista electoral / candidato / votos nulos / blancos / impugnados.
   - `act_totals`: Totales de control del acta (electores hábiles, ciudadanos que votaron, total votos emitidos).
   - `act_evidence`: Fotografía del acta y metadatos de almacenamiento (Cloudflare R2 / S3, SHA-256).
   - `ocr_ai_extractions`: Registro de propuestas extraídas por OCR/IA con nivel de confianza.

4. **Dominio Usuarios, Roles, Personeros, Dispositivos e Idempotencia:**
   - `roles`: Roles del sistema (`ADMIN`, `DIRECTOR`, `PERSONERO`) con integridad referencial.
   - `users`: Usuarios del sistema con FK `role_id` hacia `roles` y columna `role` para acceso rápido.
   - `personeros`: Perfil de personero de mesa/centro de votación (solo usuarios con rol `PERSONERO`).
   - `devices`: Dispositivos móviles registrados (asociados a un personero).
   - `personero_polling_station`: Asignación de personeros a mesas.
   - `sync_operations`: Log de sincronización idempotente offline-to-online.
   - `audit_logs`: Trazabilidad de auditoría de todas las acciones.

---

## 3. Fase de Diseño: Modelo Lógico (3FN)

El modelo lógico normaliza las entidades a Tercera Forma Normal (3FN), asegurando integridad referencial con claves primarias y foráneas bien definidas.

### Resumen del Esquema de Tablas:

| Tabla | Descripción | PK / Clave Primaria | Claves Foráneas (FK) |
|---|---|---|---|
| `departments` | Departamentos | `code` (VARCHAR 5) | — |
| `provinces` | Provincias | `code` (VARCHAR 5) | `department_code` |
| `districts` | Distritos | `code` (VARCHAR 6) | `department_code`, `province_code` |
| `electoral_locations` | Locales de votación | `id` (BIGINT) | `district_code` |
| `polling_stations` | Mesas de votación | `id` (BIGINT) / `code` (VARCHAR 10) | `electoral_location_id` |
| `elections` | Procesos Electorales | `id` (BIGINT) | — |
| `electoral_levels` | Niveles Electorales | `id` (BIGINT) | `election_id` |
| `political_organizations` | Partidos / Movimientos | `id` (BIGINT) | — |
| `electoral_lists` | Listas Electorales | `id` (BIGINT) | `political_organization_id`, `electoral_level_id`, Ubigeo FKs |
| `candidates` | Candidatos (Personas) | `id` (BIGINT) | — |
| `candidacies` | Postulación Candidato | `id` (BIGINT) | `electoral_list_id`, `candidate_id` |
| **`roles`** | **Roles del sistema** | `id` (BIGINT) | — |
| `users` | Usuarios API | `id` (BIGINT) | **`role_id` → `roles`** |
| `personeros` | Personeros de Mesa | `id` (BIGINT) | `user_id` |
| `devices` | Dispositivos Móviles | `id` (BIGINT) | `personero_id` |
| `personero_polling_station` | Asignación Mesa-Personero | `id` (BIGINT) | `personero_id`, `polling_station_id` |
| `acts` | Actas Electorales | `id` (BIGINT) | `election_id`, `electoral_level_id`, `polling_station_id`, `captured_by_personero_id` |
| `act_totals` | Totales del Acta | `id` (BIGINT) | `act_id` |
| `act_results` | Resultados de Votos | `id` (BIGINT) | `act_id`, `political_organization_id`, `electoral_list_id`, `candidate_id` |
| `act_evidence` | Evidencia Fotográfica | `id` (BIGINT) | `act_id`, `device_id` |
| `sync_operations` | Operaciones Offline | `id` (BIGINT) | `device_id` (nullable), `personero_id` |
| `audit_logs` | Auditoría de Cambios | `id` (BIGINT) | `user_id` |

---

## 4. Fase de Diseño Físico (PostgreSQL 16+)

En el diseño físico se especifican los tipos de datos nativos de PostgreSQL 16+, restricciones `CHECK`, índices `BTREE`/`GIN`, campos `TIMESTAMPTZ` y funciones/triggers de actualización de `updated_at`.

### Reglas de Negocio Físicas Implementadas:
- `CHECK (voters_who_voted <= registered_voters)` en `act_totals`.
- `CHECK (total_votes >= 0, blank_votes >= 0, null_votes >= 0, challenged_votes >= 0)` en `act_totals`.
- Restricción de unicidad `UNIQUE (polling_station_id, election_id, electoral_level_id)` en `acts` para evitar doble registro de acta.
- Restricción `UNIQUE (client_operation_id)` en `sync_operations` para garantizar la idempotencia de reintentos de red.
- Índices `BTREE` en claves foráneas para búsquedas de alta performance en consolidación.

---

## 5. Mapeo desde SQLite (erm2026.db) / JEE JSON

La base de datos original `database/erm2026.db` (proveniente del JEE) se mapea hacia la arquitectura limpia PostgreSQL de la siguiente manera:

- `departments` (SQLite: `code`, `name`) ➔ `departments` (PG)
- `provinces` (SQLite: `code`, `name`, `department_code`) ➔ `provinces` (PG)
- `districts` (SQLite: `code`, `name`, `department_code`, `province_code`) ➔ `districts` (PG)
- `political_organizations` (SQLite: `id`, `name`, `short_name`, `logo_url`) ➔ `political_organizations` (PG)
- `electoral_lists` (SQLite: `id_solicitud_lista`, `organization_id`, `election_type`, ubigeos) ➔ `electoral_lists` (PG)
- `candidates` (SQLite: `id`, `id_solicitud_lista`, `id_hoja_vida`, `full_name`, `position`) ➔ `candidates` + `candidacies` (PG)

---

## 6. Fuente de Verdad del Esquema

El esquema físico de PostgreSQL está definido y versionado mediante **migraciones Laravel** en `api/database/migrations/`. Son la única fuente de verdad del esquema.

| Migración | Descripción |
|-----------|-------------|
| `2026_08_09_165708_create_conteoya_tables` | Esquema completo: geografía, catálogo electoral, personeros, actas, sync, auditoría |
| `2026_08_10_102628_create_roles_table` | Tabla `roles` + FK `role_id` en `users` |
| `2026_08_10_220000_make_device_id_nullable_in_sync_operations_table` | `sync_operations.device_id` pasa a ser nullable |
| `2026_08_13_153500_make_personero_id_nullable_in_sync_operations_table` | `sync_operations.personero_id` pasa a ser nullable |
| `2026_08_14_120000_add_odpe_and_pdf_fields_to_polling_stations_table` | Soporte directo de ubigeos, ODPE y PDF en `polling_stations` |
| `2026_08_17_130000_create_electoral_ballot_views_and_procedures` | Vistas SQL (`v_polling_stations_ubigeo`, `v_electoral_ballot_lists`) y función almacenada (`fn_get_polling_station_ballot`) |

---

## 7. Vistas SQL y Funciones Almacenadas (PostgreSQL 16)

### `v_polling_stations_ubigeo`
Vista normalizada que desacopla la mesa de sufragio de la necesidad de un registro en `electoral_locations`. Combina dinámicamente ubigeos normalizados por código o por nombre con fallback a las columnas directas de `polling_stations`.

### `v_electoral_ballot_lists`
Vista relacional que cruza cada mesa de sufragio (`polling_stations`) con las listas electorales (`electoral_lists`), organizaciones políticas (`political_organizations`) y candidatos (`candidates`/`candidacies`) que postulan en dicha circunscripción según el tipo de nivel electoral (Regional, Provincial, Distrital).

### `fn_get_polling_station_ballot(p_station_code VARCHAR, p_level_id BIGINT)`
Función almacenada (`PL/pgSQL`, `STABLE`) que computa y retorna en formato `JSONB` de alto rendimiento toda la estructura de la cédula de votación lista para ingesta de actas electorales:
- Datos de la mesa (`id`, `code`, `registered_voters`, `status`, ubigeos).
- Datos del nivel electoral (`id`, `code`, `name`, `has_preferential_vote`).
- Array de organizaciones políticas participantes, listas oficiales y sus candidatos ordenados por número de lista.

Para aplicar el esquema desde cero:

```bash
cd api/
php artisan migrate:fresh --seed
```

