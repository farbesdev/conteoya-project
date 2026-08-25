<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Corrige la corrupción de ubigeo:
     * 1. El departamento code='10' debe ser 'ICA' (no HUANUCO).
     * 2. Re-enlazar electoral_locations con district_code='100905' al código real '090805' (YUYAPICHIS, PUERTO INCA, HUANUCO).
     * 3. Eliminar distrito 100905 y provincia fantasma 1009.
     * 4. Asignar department_code ('01'..'25') oficial de RENIEC a todas las mesas de polling_stations.
     */
    public function up(): void
    {
        // ── 1. Corregir nombre del departamento code='10' → ICA ──────────────────
        DB::table('departments')
            ->where('code', '10')
            ->update(['name' => 'ICA', 'updated_at' => now()]);

        // ── 2. Re-enlazar locales electorales con código corrupto 100905 a 090805 ──
        DB::table('electoral_locations')
            ->where('district_code', '100905')
            ->update(['district_code' => '090805']);

        DB::table('electoral_lists')
            ->where('district_code', '100905')
            ->update(['district_code' => '090805']);

        DB::table('electoral_lists')
            ->where('province_code', '1009')
            ->update(['province_code' => '0908']);

        // ── 3. Eliminar distrito y provincia fantasma code='1009' ─────────────────
        DB::table('districts')
            ->where('code', '100905')
            ->orWhere('province_code', '1009')
            ->delete();

        DB::table('provinces')
            ->where('code', '1009')
            ->delete();

        // ── 4. Asignar department_code a todos los polling_stations ───────────────
        $nameToCode = [
            'AMAZONAS'      => '01',
            'ANCASH'        => '02',
            'APURIMAC'      => '03',
            'AREQUIPA'      => '04',
            'AYACUCHO'      => '05',
            'CAJAMARCA'     => '06',
            'CUSCO'         => '07',
            'HUANCAVELICA'  => '08',
            'HUANUCO'       => '09',
            'ICA'           => '10',
            'JUNIN'         => '11',
            'LA LIBERTAD'   => '12',
            'LAMBAYEQUE'    => '13',
            'LIMA'          => '14',
            'LORETO'        => '15',
            'MADRE DE DIOS' => '16',
            'MOQUEGUA'      => '17',
            'PASCO'         => '18',
            'PIURA'         => '19',
            'PUNO'          => '20',
            'SAN MARTIN'    => '21',
            'TACNA'         => '22',
            'TUMBES'        => '23',
            'CALLAO'        => '24',
            'UCAYALI'       => '25',
        ];

        foreach ($nameToCode as $deptName => $deptCode) {
            DB::table('polling_stations')
                ->where('department_name', $deptName)
                ->update(['department_code' => $deptCode]);
        }
    }

    public function down(): void
    {
        DB::table('departments')
            ->where('code', '10')
            ->update(['name' => 'HUANUCO', 'updated_at' => now()]);
    }
};
