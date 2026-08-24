<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'pgsql') {
            // 0. Índices de cobertura B-Tree para consultas de alta concurrencia O(1)
            DB::statement("CREATE INDEX IF NOT EXISTS idx_polling_stations_code_lookup ON polling_stations(code)");
            DB::statement("CREATE INDEX IF NOT EXISTS idx_electoral_lists_perf_lookup ON electoral_lists(electoral_level_id, status, department_code, province_code, district_code)");
            DB::statement("CREATE INDEX IF NOT EXISTS idx_candidacies_perf_lookup ON candidacies(electoral_list_id, list_number, status)");

            // 1. Vista indexable y liviana de normalización de mesas con Ubigeo (sin joins por string difuso)
            DB::statement("
                CREATE OR REPLACE VIEW v_polling_stations_ubigeo AS
                SELECT
                    ps.id AS polling_station_id,
                    ps.code AS polling_station_code,
                    ps.registered_voters,
                    ps.status AS station_status,
                    ps.odpe,
                    ps.pdf_file,
                    ps.pdf_page,
                    dep.code AS department_code,
                    ps.department_name,
                    prov.code AS province_code,
                    ps.province_name,
                    dist.code AS district_code,
                    ps.district_name,
                    el.id AS electoral_location_id,
                    el.name AS electoral_location_name,
                    el.address AS electoral_location_address
                FROM polling_stations ps
                INNER JOIN departments dep ON UPPER(TRIM(dep.name)) = UPPER(TRIM(ps.department_name))
                INNER JOIN provinces prov ON UPPER(TRIM(prov.name)) = UPPER(TRIM(ps.province_name))
                INNER JOIN districts dist ON UPPER(TRIM(dist.name)) = UPPER(TRIM(ps.district_name))
                LEFT JOIN electoral_locations el ON el.id = ps.electoral_location_id
            ");

            // 2. Vista optimizada de listas electorales con sus partidos y candidatos (sin CROSS JOIN)
            DB::statement("
                CREATE OR REPLACE VIEW v_electoral_ballot_lists AS
                SELECT
                    lis.id AS electoral_list_id,
                    lis.electoral_level_id,
                    el.code AS electoral_level_code,
                    el.name AS electoral_level_name,
                    el.has_preferential_vote,
                    lis.department_code,
                    lis.province_code,
                    lis.district_code,
                    lis.status AS list_status,
                    po.id AS political_organization_id,
                    po.jee_id,
                    po.name AS political_organization_name,
                    po.short_name AS political_organization_short_name,
                    po.logo_url,
                    po.local_logo_url,
                    cand.id AS candidate_id,
                    cand.full_name AS candidate_name,
                    cand.document_number AS candidate_document,
                    cand.photo_url AS candidate_photo_url,
                    cand.local_photo_url AS candidate_local_photo_url,
                    c.position AS candidacy_position,
                    c.list_number AS candidacy_list_number
                FROM electoral_lists lis
                INNER JOIN electoral_levels el ON el.id = lis.electoral_level_id
                INNER JOIN political_organizations po ON po.id = lis.political_organization_id
                LEFT JOIN candidacies c ON c.electoral_list_id = lis.id AND c.status::text = 'INSCRITO'::text
                LEFT JOIN candidates cand ON cand.id = c.candidate_id
                WHERE lis.status::text = 'INSCRITO'
                  AND c.position::text IN ('GOBERNADOR REGIONAL', 'ALCALDE PROVINCIAL', 'ALCALDE DISTRITAL')
            ");

            // 3. Stored Procedure O(1) de alto rendimiento en PostgreSQL 16 con búsquedas directas
            DB::statement("
                CREATE OR REPLACE FUNCTION fn_get_polling_station_ballot(
                    p_station_code VARCHAR,
                    p_level_id BIGINT
                )
                RETURNS JSONB
                LANGUAGE plpgsql
                STABLE
                AS \$\$
                DECLARE
                    v_station RECORD;
                    v_level RECORD;
                    v_lists JSONB;
                BEGIN
                    -- 1. Búsqueda directa O(1) de la mesa por código (Unique Index Seek)
                    SELECT 
                        ps.id,
                        ps.code,
                        ps.registered_voters,
                        ps.status,
                        COALESCE(d.department_code, ps.department_name) AS department_code,
                        COALESCE(dep.name, ps.department_name) AS department_name,
                        COALESCE(d.province_code, ps.province_name) AS province_code,
                        COALESCE(prov.name, ps.province_name) AS province_name,
                        COALESCE(d.code, ps.district_name) AS district_code,
                        COALESCE(d.name, ps.district_name) AS district_name,
                        COALESCE(el.name, 'LOCAL DE VOTACIÓN') AS location_name
                    INTO v_station
                    FROM polling_stations ps
                    LEFT JOIN electoral_locations el ON el.id = ps.electoral_location_id
                    LEFT JOIN districts d ON d.code = el.district_code
                    LEFT JOIN provinces prov ON prov.code = d.province_code
                    LEFT JOIN departments dep ON dep.code = d.department_code
                    WHERE ps.code = p_station_code
                    LIMIT 1;

                    IF NOT FOUND THEN
                        RETURN NULL;
                    END IF;

                    -- 2. Búsqueda directa O(1) del nivel electoral por PK
                    SELECT id, code, name, has_preferential_vote
                    INTO v_level
                    FROM electoral_levels
                    WHERE id = p_level_id
                    LIMIT 1;

                    IF NOT FOUND THEN
                        RETURN NULL;
                    END IF;

                    -- 3. Búsqueda y agregación JSON directa indexada de listas y candidatos aplicables
                    SELECT COALESCE(
                        jsonb_agg(
                            jsonb_build_object(
                                'electoral_list_id', q.electoral_list_id,
                                'political_organization_id', q.political_organization_id,
                                'political_organization_name', q.political_organization_name,
                                'political_organization_short_name', q.political_organization_short_name,
                                'logo_url', q.logo_url,
                                'local_logo_url', q.local_logo_url,
                                'candidates', q.candidates
                            )
                        ), '[]'::jsonb
                    )
                    INTO v_lists
                    FROM (
                        SELECT 
                            lis.id AS electoral_list_id,
                            po.id AS political_organization_id,
                            po.name AS political_organization_name,
                            po.short_name AS political_organization_short_name,
                            po.logo_url,
                            po.local_logo_url,
                            COALESCE(
                                (
                                    SELECT jsonb_agg(
                                        jsonb_build_object(
                                            'candidate_id', cand.id,
                                            'candidate_name', cand.full_name,
                                            'candidate_document', cand.document_number,
                                            'photo_url', cand.photo_url,
                                            'local_photo_url', cand.local_photo_url,
                                            'position', c.position,
                                            'list_number', c.list_number
                                        ) ORDER BY c.list_number ASC
                                    )
                                    FROM candidacies c
                                    INNER JOIN candidates cand ON cand.id = c.candidate_id
                                    WHERE c.electoral_list_id = lis.id
                                      AND c.status = 'INSCRITO'
                                ), '[]'::jsonb
                            ) AS candidates
                        FROM electoral_lists lis
                        INNER JOIN political_organizations po ON po.id = lis.political_organization_id
                        WHERE lis.electoral_level_id = p_level_id
                          AND lis.status = 'INSCRITO'
                          AND (
                              (v_level.code IN ('REGIONAL_GOBERNADOR', 'REGIONAL_CONSEJERO') 
                               AND (lis.department_code IS NULL OR lis.department_code = v_station.department_code))
                              OR
                              (v_level.code IN ('MUNICIPAL_PROVINCIAL', 'PROVINCIAL_ALCALDE', 'PROVINCIAL_REGIDOR') 
                               AND (lis.province_code IS NULL OR lis.province_code = v_station.province_code))
                              OR
                              (v_level.code IN ('MUNICIPAL_DISTRITAL', 'DISTRITAL_ALCALDE', 'DISTRITAL_REGIDOR') 
                               AND (lis.district_code IS NULL OR lis.district_code = v_station.district_code))
                          )
                        ORDER BY po.name ASC
                    ) q;

                    -- 4. Construcción final de JSONB estructurado
                    RETURN jsonb_build_object(
                        'station', jsonb_build_object(
                            'id', v_station.id,
                            'code', v_station.code,
                            'registered_voters', v_station.registered_voters,
                            'status', v_station.status,
                            'department_code', v_station.department_code,
                            'department_name', v_station.department_name,
                            'province_code', v_station.province_code,
                            'province_name', v_station.province_name,
                            'district_code', v_station.district_code,
                            'district_name', v_station.district_name,
                            'location_name', v_station.location_name
                        ),
                        'electoral_level', jsonb_build_object(
                            'id', v_level.id,
                            'code', v_level.code,
                            'name', v_level.name,
                            'has_preferential_vote', v_level.has_preferential_vote
                        ),
                        'lists', v_lists
                    );
                END;
                \$\$;
            ");
        } else {
            // SQLite (usado en tests y entorno local liviano)
            DB::statement("
                CREATE VIEW IF NOT EXISTS v_polling_stations_ubigeo AS
                SELECT 
                    ps.id AS polling_station_id,
                    ps.code AS polling_station_code,
                    ps.registered_voters,
                    ps.status AS station_status,
                    ps.odpe,
                    ps.pdf_file,
                    ps.pdf_page,
                    COALESCE(d.department_code, ps.department_name) AS department_code,
                    COALESCE(dep.name, ps.department_name) AS department_name,
                    COALESCE(d.province_code, ps.province_name) AS province_code,
                    COALESCE(prov.name, ps.province_name) AS province_name,
                    COALESCE(d.code, ps.district_name) AS district_code,
                    COALESCE(d.name, ps.district_name) AS district_name,
                    el.id AS electoral_location_id,
                    el.name AS electoral_location_name,
                    el.address AS electoral_location_address
                FROM polling_stations ps
                LEFT JOIN electoral_locations el ON el.id = ps.electoral_location_id
                LEFT JOIN districts d ON d.code = el.district_code
                LEFT JOIN provinces prov ON prov.code = d.province_code
                LEFT JOIN departments dep ON dep.code = d.department_code
            ");

            DB::statement("
                CREATE VIEW IF NOT EXISTS v_electoral_ballot_lists AS
                SELECT 
                    lis.id AS electoral_list_id,
                    lis.electoral_level_id,
                    el.code AS electoral_level_code,
                    el.name AS electoral_level_name,
                    el.has_preferential_vote,
                    lis.department_code,
                    lis.province_code,
                    lis.district_code,
                    lis.status AS list_status,
                    po.id AS political_organization_id,
                    po.jee_id,
                    po.name AS political_organization_name,
                    po.short_name AS political_organization_short_name,
                    po.logo_url,
                    po.local_logo_url,
                    cand.id AS candidate_id,
                    cand.full_name AS candidate_name,
                    cand.document_number AS candidate_document,
                    cand.photo_url AS candidate_photo_url,
                    cand.local_photo_url AS candidate_local_photo_url,
                    c.position AS candidacy_position,
                    c.list_number AS candidacy_list_number
                FROM electoral_lists lis
                INNER JOIN electoral_levels el ON el.id = lis.electoral_level_id
                INNER JOIN political_organizations po ON po.id = lis.political_organization_id
                LEFT JOIN candidacies c ON c.electoral_list_id = lis.id
                LEFT JOIN candidates cand ON cand.id = c.candidate_id
                WHERE lis.status = 'INSCRITO'
            ");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        $driver = DB::getDriverName();
        if ($driver === 'pgsql') {
            DB::statement("DROP FUNCTION IF EXISTS fn_get_polling_station_ballot(VARCHAR, BIGINT)");
            DB::statement("DROP INDEX IF EXISTS idx_candidacies_perf_lookup");
            DB::statement("DROP INDEX IF EXISTS idx_electoral_lists_perf_lookup");
            DB::statement("DROP INDEX IF EXISTS idx_polling_stations_code_lookup");
        }
        DB::statement("DROP VIEW IF EXISTS v_electoral_ballot_lists");
        DB::statement("DROP VIEW IF EXISTS v_polling_stations_ubigeo");
    }
};
