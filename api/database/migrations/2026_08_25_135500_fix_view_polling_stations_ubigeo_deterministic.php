<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Recrea v_polling_stations_ubigeo y fn_get_polling_station_ballot con
     * resolución de ubigeo determinista: ancla los JOINs de districts/provinces
     * al campo department_code (VARCHAR 2) ya poblado en polling_stations,
     * eliminando la ambigüedad de distritos con nombre duplicado entre departamentos
     * (ej: "COMAS" en Lima dept=14 y "COMAS" en Junín dept=11).
     */
    public function up(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        // DROP con CASCADE para eliminar la vista y su dependencia en la función
        DB::statement('DROP VIEW IF EXISTS v_polling_stations_ubigeo CASCADE');

        // Recrear vista determinista
        DB::statement("
            CREATE VIEW v_polling_stations_ubigeo AS
            SELECT
                ps.id                                            AS polling_station_id,
                ps.code                                          AS polling_station_code,
                ps.registered_voters,
                ps.status                                        AS station_status,
                ps.odpe,
                ps.pdf_file,
                ps.pdf_page,
                ps.department_code,
                ps.department_name,
                COALESCE(loc_dist.province_code, name_prov.code) AS province_code,
                ps.province_name,
                COALESCE(el.district_code, name_dist.code)       AS district_code,
                ps.district_name,
                el.id                                            AS electoral_location_id,
                el.name                                          AS electoral_location_name,
                el.address                                       AS electoral_location_address
            FROM polling_stations ps
            LEFT JOIN electoral_locations el
                ON el.id = ps.electoral_location_id
            LEFT JOIN districts loc_dist
                ON loc_dist.code = el.district_code
            LEFT JOIN provinces name_prov
                ON UPPER(TRIM(name_prov.name)) = UPPER(TRIM(ps.province_name))
               AND name_prov.department_code = ps.department_code
            LEFT JOIN districts name_dist
                ON UPPER(TRIM(name_dist.name)) = UPPER(TRIM(ps.district_name))
               AND name_dist.province_code = COALESCE(loc_dist.province_code, name_prov.code)
        ");

        // Recrear función con misma lógica determinista
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
                v_level   RECORD;
                v_lists   JSONB;
            BEGIN
                SELECT
                    ps.id,
                    ps.code,
                    ps.registered_voters,
                    ps.status,
                    ps.department_code,
                    ps.department_name,
                    COALESCE(loc_d.province_code, np.code)  AS province_code,
                    ps.province_name,
                    COALESCE(el.district_code, nd.code)     AS district_code,
                    ps.district_name,
                    COALESCE(el.name, 'LOCAL DE VOTACION')  AS location_name
                INTO v_station
                FROM polling_stations ps
                LEFT JOIN electoral_locations el
                    ON el.id = ps.electoral_location_id
                LEFT JOIN districts loc_d
                    ON loc_d.code = el.district_code
                LEFT JOIN provinces np
                    ON UPPER(TRIM(np.name)) = UPPER(TRIM(ps.province_name))
                   AND np.department_code = ps.department_code
                LEFT JOIN districts nd
                    ON UPPER(TRIM(nd.name)) = UPPER(TRIM(ps.district_name))
                   AND nd.province_code = COALESCE(loc_d.province_code, np.code)
                WHERE ps.code = p_station_code
                LIMIT 1;

                IF NOT FOUND THEN RETURN NULL; END IF;

                SELECT id, code, name, has_preferential_vote
                INTO v_level
                FROM electoral_levels
                WHERE id = p_level_id
                LIMIT 1;

                IF NOT FOUND THEN RETURN NULL; END IF;

                SELECT COALESCE(
                    jsonb_agg(
                        jsonb_build_object(
                            'electoral_list_id',                 q.electoral_list_id,
                            'political_organization_id',         q.political_organization_id,
                            'political_organization_name',       q.political_organization_name,
                            'political_organization_short_name', q.political_organization_short_name,
                            'logo_url',                          q.logo_url,
                            'local_logo_url',                    q.local_logo_url,
                            'candidates',                        q.candidates
                        )
                    ),
                    '[]'::jsonb
                )
                INTO v_lists
                FROM (
                    SELECT
                        lis.id            AS electoral_list_id,
                        po.id             AS political_organization_id,
                        po.name           AS political_organization_name,
                        po.short_name     AS political_organization_short_name,
                        po.logo_url,
                        po.local_logo_url,
                        COALESCE(
                            (
                                SELECT jsonb_agg(
                                    jsonb_build_object(
                                        'candidate_id',       cand.id,
                                        'candidate_name',     cand.full_name,
                                        'candidate_document', cand.document_number,
                                        'photo_url',          cand.photo_url,
                                        'local_photo_url',    cand.local_photo_url,
                                        'position',           c.position,
                                        'list_number',        c.list_number
                                    )
                                    ORDER BY
                                        CASE WHEN c.position IN (
                                            'GOBERNADOR REGIONAL','ALCALDE PROVINCIAL','ALCALDE DISTRITAL'
                                        ) THEN 0 ELSE 1 END,
                                        c.list_number ASC
                                )
                                FROM candidacies c
                                INNER JOIN candidates cand ON cand.id = c.candidate_id
                                WHERE c.electoral_list_id = lis.id
                                  AND c.status IN ('INSCRITO', 'ADMITIDO')
                            ),
                            '[]'::jsonb
                        ) AS candidates
                    FROM electoral_lists lis
                    INNER JOIN political_organizations po ON po.id = lis.political_organization_id
                    WHERE lis.electoral_level_id = p_level_id
                      AND lis.status IN ('INSCRITO', 'ADMITIDO')
                      AND (
                          (v_level.code IN ('REGIONAL_GOBERNADOR','REGIONAL_CONSEJERO')
                           AND lis.department_code IS NOT NULL
                           AND lis.department_code = v_station.department_code)
                          OR
                          (v_level.code IN ('MUNICIPAL_PROVINCIAL','PROVINCIAL_ALCALDE','PROVINCIAL_REGIDOR')
                           AND lis.province_code IS NOT NULL
                           AND lis.province_code = v_station.province_code)
                          OR
                          (v_level.code IN ('MUNICIPAL_DISTRITAL','DISTRITAL_ALCALDE','DISTRITAL_REGIDOR')
                           AND lis.district_code IS NOT NULL
                           AND lis.district_code = v_station.district_code)
                      )
                    ORDER BY po.name ASC
                ) q;

                RETURN jsonb_build_object(
                    'station', jsonb_build_object(
                        'id',                v_station.id,
                        'code',              v_station.code,
                        'registered_voters', v_station.registered_voters,
                        'status',            v_station.status,
                        'department_code',   v_station.department_code,
                        'department_name',   v_station.department_name,
                        'province_code',     v_station.province_code,
                        'province_name',     v_station.province_name,
                        'district_code',     v_station.district_code,
                        'district_name',     v_station.district_name,
                        'location_name',     v_station.location_name
                    ),
                    'electoral_level', jsonb_build_object(
                        'id',                    v_level.id,
                        'code',                  v_level.code,
                        'name',                  v_level.name,
                        'has_preferential_vote', v_level.has_preferential_vote
                    ),
                    'lists', v_lists
                );
            END;
            \$\$;
        ");
    }

    public function down(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }
        DB::statement('DROP VIEW IF EXISTS v_polling_stations_ubigeo CASCADE');
        DB::statement("
            CREATE VIEW v_polling_stations_ubigeo AS
            SELECT
                ps.id AS polling_station_id, ps.code AS polling_station_code,
                ps.registered_voters, ps.status AS station_status,
                ps.odpe, ps.pdf_file, ps.pdf_page,
                COALESCE(dist.department_code, dep.code) AS department_code,
                ps.department_name,
                COALESCE(dist.province_code, prov.code) AS province_code,
                ps.province_name, dist.code AS district_code, ps.district_name,
                el.id AS electoral_location_id, el.name AS electoral_location_name,
                el.address AS electoral_location_address
            FROM polling_stations ps
            LEFT JOIN electoral_locations el ON el.id = ps.electoral_location_id
            LEFT JOIN districts dist ON dist.code = el.district_code
                OR UPPER(TRIM(dist.name)) = UPPER(TRIM(ps.district_name))
            LEFT JOIN provinces prov ON prov.code = dist.province_code
                OR UPPER(TRIM(prov.name)) = UPPER(TRIM(ps.province_name))
            LEFT JOIN departments dep ON dep.code = dist.department_code
                OR UPPER(TRIM(dep.name)) = UPPER(TRIM(ps.department_name))
        ");
    }
};
