-- ==============================================================================
-- ConteoYA — Schema DDL PostgreSQL 16+
-- Especificación de Base de Datos para Fase 0 (Foundation) y Fase 1 (Ingesta)
-- ==============================================================================

-- Habilitar extensión pgcrypto para UUID e hashing si fuese necesario
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. DOMINIO GEOGRÁFICO (UBIGEO ELECTORAL)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS departments (
    code VARCHAR(5) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS provinces (
    code VARCHAR(5) PRIMARY KEY,
    department_code VARCHAR(5) NOT NULL REFERENCES departments(code) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS districts (
    code VARCHAR(6) PRIMARY KEY,
    province_code VARCHAR(5) NOT NULL REFERENCES provinces(code) ON DELETE RESTRICT,
    department_code VARCHAR(5) NOT NULL REFERENCES departments(code) ON DELETE RESTRICT,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS electoral_locations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    district_code VARCHAR(6) NOT NULL REFERENCES districts(code) ON DELETE RESTRICT,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255),
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS polling_stations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    electoral_location_id BIGINT NOT NULL REFERENCES electoral_locations(id) ON DELETE RESTRICT,
    code VARCHAR(10) NOT NULL UNIQUE, -- Código de mesa (ej. 030390)
    registered_voters INT NOT NULL DEFAULT 0 CHECK (registered_voters >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- 2. DOMINIO CATÁLOGO ELECTORAL & CANDIDATURAS
-- ==============================================================================

CREATE TABLE IF NOT EXISTS elections (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE, -- ej. ERM2026
    name VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PLANNED' CHECK (status IN ('PLANNED', 'ACTIVE', 'FINISHED', 'ARCHIVED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS electoral_levels (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    election_id BIGINT NOT NULL REFERENCES elections(id) ON DELETE CASCADE,
    code VARCHAR(50) NOT NULL, -- ej. REGIONAL_GOBERNADOR, PROVINCIAL_ALCALDE, DISTRITAL_ALCALDE
    name VARCHAR(100) NOT NULL,
    has_preferential_vote BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_election_level UNIQUE (election_id, code)
);

CREATE TABLE IF NOT EXISTS political_organizations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    jee_id INT UNIQUE, -- ID proveniente de JEE / SQLite original
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(50),
    org_type VARCHAR(50),
    logo_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS electoral_lists (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    jee_solicitud_id INT UNIQUE, -- ID solicitud JEE original
    political_organization_id BIGINT NOT NULL REFERENCES political_organizations(id) ON DELETE RESTRICT,
    electoral_level_id BIGINT NOT NULL REFERENCES electoral_levels(id) ON DELETE RESTRICT,
    department_code VARCHAR(5) REFERENCES departments(code) ON DELETE RESTRICT,
    province_code VARCHAR(5) REFERENCES provinces(code) ON DELETE RESTRICT,
    district_code VARCHAR(6) REFERENCES districts(code) ON DELETE RESTRICT,
    status VARCHAR(50) NOT NULL DEFAULT 'INSCRITO',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS candidates (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    jee_candidate_id INT UNIQUE,
    id_hoja_vida VARCHAR(100),
    document_number VARCHAR(20),
    full_name VARCHAR(255) NOT NULL,
    photo_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS candidacies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    electoral_list_id BIGINT NOT NULL REFERENCES electoral_lists(id) ON DELETE CASCADE,
    candidate_id BIGINT NOT NULL REFERENCES candidates(id) ON DELETE CASCADE,
    position VARCHAR(100) NOT NULL, -- ej. GOBERNADOR REGIONAL, ALCALDE DISTRITAL, REGIDOR 1
    list_number INT DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'INSCRITO',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_list_candidate UNIQUE (electoral_list_id, candidate_id)
);

-- ==============================================================================
-- 3. DOMINIO USUARIOS, PERSONEROS Y DISPOSITIVOS
-- ==============================================================================

CREATE TABLE IF NOT EXISTS users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'PERSONERO' CHECK (role IN ('ADMIN', 'SUPERVISOR', 'PERSONERO')),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS personeros (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    document_number VARCHAR(20) NOT NULL UNIQUE,
    phone_number VARCHAR(20),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS devices (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    personero_id BIGINT NOT NULL REFERENCES personeros(id) ON DELETE CASCADE,
    device_uuid VARCHAR(100) NOT NULL UNIQUE,
    device_model VARCHAR(100),
    os_version VARCHAR(50),
    app_version VARCHAR(50),
    last_active_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS personero_polling_station (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    personero_id BIGINT NOT NULL REFERENCES personeros(id) ON DELETE CASCADE,
    polling_station_id BIGINT NOT NULL REFERENCES polling_stations(id) ON DELETE CASCADE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_personero_station UNIQUE (personero_id, polling_station_id)
);

-- ==============================================================================
-- 4. DOMINIO INGESTA, ACTAS, RESULTADOS Y EVIDENCIA (FASE 1)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS acts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    election_id BIGINT NOT NULL REFERENCES elections(id) ON DELETE RESTRICT,
    electoral_level_id BIGINT NOT NULL REFERENCES electoral_levels(id) ON DELETE RESTRICT,
    polling_station_id BIGINT NOT NULL REFERENCES polling_stations(id) ON DELETE RESTRICT,
    act_code VARCHAR(20), -- Código de barra del acta si aplica
    status VARCHAR(30) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'PENDING_REVIEW', 'CONFIRMED', 'OBSERVED', 'REJECTED')),
    captured_by_personero_id BIGINT NOT NULL REFERENCES personeros(id) ON DELETE RESTRICT,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_act_station_level UNIQUE (polling_station_id, election_id, electoral_level_id)
);

CREATE TABLE IF NOT EXISTS act_totals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    act_id BIGINT NOT NULL UNIQUE REFERENCES acts(id) ON DELETE CASCADE,
    registered_voters INT NOT NULL CHECK (registered_voters >= 0),
    voters_who_voted INT NOT NULL CHECK (voters_who_voted >= 0),
    total_votes INT NOT NULL CHECK (total_votes >= 0),
    blank_votes INT NOT NULL DEFAULT 0 CHECK (blank_votes >= 0),
    null_votes INT NOT NULL DEFAULT 0 CHECK (null_votes >= 0),
    challenged_votes INT NOT NULL DEFAULT 0 CHECK (challenged_votes >= 0),
    is_valid_total BOOLEAN NOT NULL DEFAULT TRUE, -- Resultado de la validación matemática de consistencia
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_voters_limit CHECK (voters_who_voted <= registered_voters)
);

CREATE TABLE IF NOT EXISTS act_results (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    act_id BIGINT NOT NULL REFERENCES acts(id) ON DELETE CASCADE,
    political_organization_id BIGINT REFERENCES political_organizations(id) ON DELETE RESTRICT,
    electoral_list_id BIGINT REFERENCES electoral_lists(id) ON DELETE RESTRICT,
    candidate_id BIGINT REFERENCES candidates(id) ON DELETE RESTRICT, -- Para voto preferencial / regidores si aplica
    votes INT NOT NULL DEFAULT 0 CHECK (votes >= 0),
    source VARCHAR(20) NOT NULL DEFAULT 'MANUAL' CHECK (source IN ('MANUAL', 'OCR', 'AI', 'IMPORTED')),
    confidence NUMERIC(5, 4) CHECK (confidence >= 0 AND confidence <= 1.0000), -- Grado de confianza OCR/IA
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS act_evidence (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    act_id BIGINT NOT NULL REFERENCES acts(id) ON DELETE CASCADE,
    device_id BIGINT REFERENCES devices(id) ON DELETE SET NULL,
    storage_provider VARCHAR(50) NOT NULL DEFAULT 'R2', -- Cloudflare R2 / S3
    object_key TEXT NOT NULL,
    file_mime VARCHAR(50) NOT NULL DEFAULT 'image/jpeg',
    file_size_bytes BIGINT NOT NULL,
    sha256_hash VARCHAR(64) NOT NULL,
    width_px INT,
    height_px INT,
    captured_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ocr_ai_extractions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    act_id BIGINT NOT NULL REFERENCES acts(id) ON DELETE CASCADE,
    act_evidence_id BIGINT NOT NULL REFERENCES act_evidence(id) ON DELETE CASCADE,
    provider_name VARCHAR(50) NOT NULL, -- ej. AWS Rekognition, Azure OCR, OpenAI
    raw_response_json JSONB NOT NULL,
    extracted_data_json JSONB NOT NULL,
    processed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- 5. DOMINIO OFFLINE, SINCRONIZACIÓN & AUDITORÍA
-- ==============================================================================

CREATE TABLE IF NOT EXISTS sync_operations (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_operation_id UUID NOT NULL UNIQUE, -- Idempotency Key única desde el dispositivo móvil
    device_id BIGINT NOT NULL REFERENCES devices(id) ON DELETE RESTRICT,
    personero_id BIGINT NOT NULL REFERENCES personeros(id) ON DELETE RESTRICT,
    entity_type VARCHAR(50) NOT NULL, -- ej. ACT, EVIDENCE
    entity_id VARCHAR(100) NOT NULL,
    operation VARCHAR(20) NOT NULL CHECK (operation IN ('CREATE', 'UPDATE', 'CONFIRM')),
    payload JSONB NOT NULL,
    attempts INT NOT NULL DEFAULT 1,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSED', 'FAILED', 'CONFLICT')),
    last_error TEXT,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    payload JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ==============================================================================
-- 6. ÍNDICES DE ALTO RENDIMIENTO
-- ==============================================================================

CREATE INDEX IF NOT EXISTS idx_provinces_department ON provinces(department_code);
CREATE INDEX IF NOT EXISTS idx_districts_province ON districts(province_code);
CREATE INDEX IF NOT EXISTS idx_polling_stations_location ON polling_stations(electoral_location_id);

CREATE INDEX IF NOT EXISTS idx_electoral_lists_org ON electoral_lists(political_organization_id);
CREATE INDEX IF NOT EXISTS idx_electoral_lists_level ON electoral_lists(electoral_level_id);
CREATE INDEX IF NOT EXISTS idx_candidacies_list ON candidacies(electoral_list_id);
CREATE INDEX IF NOT EXISTS idx_candidacies_candidate ON candidacies(candidate_id);

CREATE INDEX IF NOT EXISTS idx_acts_station ON acts(polling_station_id);
CREATE INDEX IF NOT EXISTS idx_acts_election_level ON acts(election_id, electoral_level_id);
CREATE INDEX IF NOT EXISTS idx_acts_status ON acts(status);

CREATE INDEX IF NOT EXISTS idx_act_results_act ON act_results(act_id);
CREATE INDEX IF NOT EXISTS idx_act_results_org ON act_results(political_organization_id);

CREATE INDEX IF NOT EXISTS idx_sync_ops_client_op ON sync_operations(client_operation_id);
CREATE INDEX IF NOT EXISTS idx_sync_ops_device ON sync_operations(device_id);
CREATE INDEX IF NOT EXISTS idx_sync_ops_status ON sync_operations(status);

-- ==============================================================================
-- 7. TRIGGERS PARA UPDATED_AT AUTOMÁTICO
-- ==============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trg_update_departments_modtime BEFORE UPDATE ON departments FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER trg_update_provinces_modtime BEFORE UPDATE ON provinces FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER trg_update_districts_modtime BEFORE UPDATE ON districts FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER trg_update_polling_stations_modtime BEFORE UPDATE ON polling_stations FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER trg_update_acts_modtime BEFORE UPDATE ON acts FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER trg_update_act_totals_modtime BEFORE UPDATE ON act_totals FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER trg_update_act_results_modtime BEFORE UPDATE ON act_results FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
