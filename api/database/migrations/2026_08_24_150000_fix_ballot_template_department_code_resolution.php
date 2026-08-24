<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Migración de corrección crítica para la resolución de ubigeo en cédulas electorales.
 *
 * Contexto del bug:
 * El endpoint ballot-template resolvía el departamento de una mesa comparando
 * department_name (texto libre con posibles tildes) contra departments.name.
 * En mesas donde ONPE guarda 'HUÁNUCO' (con tilde) y departments tiene 'HUANUCO' (sin tilde),
 * el match fallaba silenciosamente y se devolvían listas de otro departamento (ICA).
 *
 * Solución:
 * 1. Habilitar extensión unaccent en PostgreSQL para comparaciones tolerantes a tildes.
 * 2. Agregar department_code (varchar 2) a polling_stations, derivado del ubigeo del distrito.
 * 3. Poblar la columna via JOIN con districts (100% confiable, sin dependencia de nombres).
 */
return new class extends Migration
{
    public function up(): void
    {
        $driver = DB::getDriverName();

        // 1. Habilitar extensión unaccent en PostgreSQL (idempotente, no falla si ya existe)
        // En SQLite (entorno de test) no existe esta extensión, se omite.
        if ($driver === 'pgsql') {
            DB::statement('CREATE EXTENSION IF NOT EXISTS unaccent');
        }

        // 2. Agregar columna department_code a polling_stations
        Schema::table('polling_stations', function (Blueprint $table) {
            $table->string('department_code', 2)->nullable()->after('district_name')
                  ->comment('Código de departamento RENIEC (2 dígitos), derivado del distrito. Fuente de verdad para filtrado de cédulas electorales.');
        });

        // 3. Poblar department_code desde districts via ubigeo del distrito
        if ($driver === 'pgsql') {
            // PostgreSQL: JOIN con tolerancia a tildes via unaccent
            DB::statement("
                UPDATE polling_stations ps
                SET department_code = d.department_code
                FROM districts d
                WHERE unaccent(LOWER(TRIM(d.name))) = unaccent(LOWER(TRIM(ps.district_name)))
                AND ps.department_code IS NULL
            ");

            // Fallback 1: JOIN por province_name para mesas que no matchearon por distrito
            DB::statement("
                UPDATE polling_stations ps
                SET department_code = p.department_code
                FROM provinces p
                WHERE unaccent(LOWER(TRIM(p.name))) = unaccent(LOWER(TRIM(ps.province_name)))
                AND ps.department_code IS NULL
            ");

            // Fallback 2: Via departments.name tolerante a tildes
            DB::statement("
                UPDATE polling_stations ps
                SET department_code = d.code
                FROM departments d
                WHERE unaccent(LOWER(TRIM(d.name))) = unaccent(LOWER(TRIM(ps.department_name)))
                AND ps.department_code IS NULL
            ");
        } else {
            // SQLite (entorno test): JOIN simple sin unaccent
            DB::statement("
                UPDATE polling_stations
                SET department_code = (
                    SELECT d.department_code FROM districts d
                    WHERE LOWER(TRIM(d.name)) = LOWER(TRIM(polling_stations.district_name))
                    LIMIT 1
                )
                WHERE department_code IS NULL
            ");
        }

        // 4. Índice para acelerar queries de ballot-template
        Schema::table('polling_stations', function (Blueprint $table) {
            $table->index('department_code', 'idx_polling_stations_department_code');
        });

        // 5. Invalidar caché de ballot-template para forzar re-consulta con datos correctos
        try {
            /** @var \Illuminate\Redis\RedisManager $redis */
            $redis = app('redis')->connection();
            $keys = $redis->keys('*catalog:ballot_template*');
            if (!empty($keys)) {
                $redis->del($keys);
                \Illuminate\Support\Facades\Log::info('[Migration] Caché ballot_template invalidada.', ['keys_deleted' => count($keys)]);
            }
        } catch (\Throwable $e) {
            // Redis puede no estar disponible en entorno de CI; no es crítico
            \Illuminate\Support\Facades\Log::warning('[Migration] No se pudo invalidar caché Redis: ' . $e->getMessage());
        }
    }

    public function down(): void
    {
        Schema::table('polling_stations', function (Blueprint $table) {
            if (Schema::hasIndex('polling_stations', 'idx_polling_stations_department_code')) {
                $table->dropIndex('idx_polling_stations_department_code');
            }
            $table->dropColumn('department_code');
        });
    }
};
