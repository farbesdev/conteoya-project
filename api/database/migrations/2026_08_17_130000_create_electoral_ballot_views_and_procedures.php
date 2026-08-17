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
            // 1. Vista de normalización de mesas con Ubigeo en PostgreSQL
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
                    COALESCE(d.department_code, p_direct.department_code, ps.department_name) AS department_code,
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
                     OR (ps.district_name IS NOT NULL AND LOWER(TRIM(d.name)) = LOWER(TRIM(ps.district_name)))
                LEFT JOIN provinces prov ON prov.code = d.province_code
                     OR (ps.province_name IS NOT NULL AND LOWER(TRIM(prov.name)) = LOWER(TRIM(ps.province_name)))
                LEFT JOIN provinces p_direct ON ps.province_name IS NOT NULL AND LOWER(TRIM(p_direct.name)) = LOWER(TRIM(ps.province_name))
                LEFT JOIN departments dep ON dep.code = COALESCE(d.department_code, p_direct.department_code)
                     OR (ps.department_name IS NOT NULL AND LOWER(TRIM(dep.name)) = LOWER(TRIM(ps.department_name)))
            ");

            // 2. Vista de listas electorales y partidos asignables a cada mesa por nivel electoral
            DB::statement("
                CREATE OR REPLACE VIEW v_electoral_ballot_lists AS
                SELECT 
                    vps.polling_station_id,
                    vps.polling_station_code,
                    el.id AS electoral_level_id,
                    el.code AS electoral_level_code,
                    el.name AS electoral_level_name,
                    el.has_preferential_vote,
                    lis.id AS electoral_list_id,
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
                FROM v_polling_stations_ubigeo vps
                CROSS JOIN electoral_levels el
                INNER JOIN electoral_lists lis ON lis.electoral_level_id = el.id
                    AND (
                        -- Nivel Regional: coincide el departamento
                        (el.code IN ('REGIONAL_GOBERNADOR', 'REGIONAL_CONSEJERO') 
                         AND (lis.department_code IS NULL OR lis.department_code = vps.department_code))
                        OR
                        -- Nivel Provincial: coincide la provincia
                        (el.code IN ('MUNICIPAL_PROVINCIAL', 'PROVINCIAL_ALCALDE', 'PROVINCIAL_REGIDOR') 
                         AND (lis.province_code IS NULL OR lis.province_code = vps.province_code))
                        OR
                        -- Nivel Distrital: coincide el distrito
                        (el.code IN ('MUNICIPAL_DISTRITAL', 'DISTRITAL_ALCALDE', 'DISTRITAL_REGIDOR') 
                         AND (lis.district_code IS NULL OR lis.district_code = vps.district_code))
                    )
                INNER JOIN political_organizations po ON po.id = lis.political_organization_id
                LEFT JOIN candidacies c ON c.electoral_list_id = lis.id
                LEFT JOIN candidates cand ON cand.id = c.candidate_id
                WHERE lis.status = 'INSCRITO'
            ");

            // 3. Procedimiento Almacenado / Función en PostgreSQL 16 para obtener el template JSON del acta
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
                    v_result JSONB;
                BEGIN
                    SELECT jsonb_build_object(
                        'station', (
                            SELECT jsonb_build_object(
                                'id', vps.polling_station_id,
                                'code', vps.polling_station_code,
                                'registered_voters', vps.registered_voters,
                                'status', vps.station_status,
                                'department_code', vps.department_code,
                                'department_name', vps.department_name,
                                'province_code', vps.province_code,
                                'province_name', vps.province_name,
                                'district_code', vps.district_code,
                                'district_name', vps.district_name,
                                'location_name', vps.electoral_location_name
                            )
                            FROM v_polling_stations_ubigeo vps
                            WHERE vps.polling_station_code = p_station_code
                            LIMIT 1
                        ),
                        'electoral_level', (
                            SELECT jsonb_build_object(
                                'id', el.id,
                                'code', el.code,
                                'name', el.name,
                                'has_preferential_vote', el.has_preferential_vote
                            )
                            FROM electoral_levels el
                            WHERE el.id = p_level_id
                            LIMIT 1
                        ),
                        'lists', COALESCE((
                            SELECT jsonb_agg(
                                jsonb_build_object(
                                    'electoral_list_id', q.electoral_list_id,
                                    'political_organization_id', q.political_organization_id,
                                    'political_organization_name', q.political_organization_name,
                                    'political_organization_short_name', q.political_organization_short_name,
                                    'logo_url', q.logo_url,
                                    'local_logo_url', q.local_logo_url,
                                    'candidates', q.candidates
                                )
                            )
                            FROM (
                                SELECT 
                                    vbl.electoral_list_id,
                                    vbl.political_organization_id,
                                    vbl.political_organization_name,
                                    vbl.political_organization_short_name,
                                    vbl.logo_url,
                                    vbl.local_logo_url,
                                    COALESCE(
                                        jsonb_agg(
                                            jsonb_build_object(
                                                'candidate_id', vbl.candidate_id,
                                                'candidate_name', vbl.candidate_name,
                                                'candidate_document', vbl.candidate_document,
                                                'photo_url', vbl.candidate_photo_url,
                                                'local_photo_url', vbl.candidate_local_photo_url,
                                                'position', vbl.candidacy_position,
                                                'list_number', vbl.candidacy_list_number
                                            ) ORDER BY vbl.candidacy_list_number ASC
                                        ) FILTER (WHERE vbl.candidate_id IS NOT NULL),
                                        '[]'::jsonb
                                    ) AS candidates
                                FROM v_electoral_ballot_lists vbl
                                WHERE vbl.polling_station_code = p_station_code
                                  AND vbl.electoral_level_id = p_level_id
                                GROUP BY 
                                    vbl.electoral_list_id,
                                    vbl.political_organization_id,
                                    vbl.political_organization_name,
                                    vbl.political_organization_short_name,
                                    vbl.logo_url,
                                    vbl.local_logo_url
                            ) q
                        ), '[]'::jsonb)
                    ) INTO v_result;

                    RETURN v_result;
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
                    vps.polling_station_id,
                    vps.polling_station_code,
                    el.id AS electoral_level_id,
                    el.code AS electoral_level_code,
                    el.name AS electoral_level_name,
                    el.has_preferential_vote,
                    lis.id AS electoral_list_id,
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
                FROM v_polling_stations_ubigeo vps
                CROSS JOIN electoral_levels el
                INNER JOIN electoral_lists lis ON lis.electoral_level_id = el.id
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
        }
        DB::statement("DROP VIEW IF EXISTS v_electoral_ballot_lists");
        DB::statement("DROP VIEW IF EXISTS v_polling_stations_ubigeo");
    }
};
