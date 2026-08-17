<?php

namespace Database\Seeders;

use App\Models\Personero;
use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Crea un usuario de prueba por cada rol del sistema ConteoYA.
     *
     * Credenciales de acceso (solo para desarrollo/staging):
     *
     *   ADMIN     → admin@conteoya.pe         / password: Admin123!
     *   DIRECTOR  → director@conteoya.pe      / password: Director123!
     *   PERSONERO → personero@conteoya.pe     / password: Personero123!
     *
     * El usuario con rol PERSONERO también crea un perfil en la tabla `personeros`
     * para poder probar los endpoints protegidos de captura de actas.
     */
    public function run(): void
    {
        // ─── ADMIN ──────────────────────────────────────────────────────────
        $adminRole = Role::where('name', Role::ADMIN)->firstOrFail();

        User::updateOrCreate(
            ['email' => 'admin@conteoya.pe'],
            [
                'name'      => 'Administrador ConteoYA',
                'password'  => Hash::make('Admin123!'),
                'role'      => Role::ADMIN,
                'role_id'   => $adminRole->id,
                'is_active' => true,
            ]
        );

        $this->command->info('✅  Usuario ADMIN creado: admin@conteoya.pe / Admin123!');

        // ─── DIRECTOR ────────────────────────────────────────────────────────
        $directorRole = Role::where('name', Role::DIRECTOR)->firstOrFail();

        User::updateOrCreate(
            ['email' => 'director@conteoya.pe'],
            [
                'name'      => 'Director Electoral Demo',
                'password'  => Hash::make('Director123!'),
                'role'      => Role::DIRECTOR,
                'role_id'   => $directorRole->id,
                'is_active' => true,
            ]
        );

        $this->command->info('✅  Usuario DIRECTOR creado: director@conteoya.pe / Director123!');

        // ─── PERSONERO ───────────────────────────────────────────────────────
        $personeroRole = Role::where('name', Role::PERSONERO)->firstOrFail();

        $personeroUser = User::updateOrCreate(
            ['email' => 'personero@conteoya.pe'],
            [
                'name'      => 'Juan Pérez Demo',
                'password'  => Hash::make('Personero123!'),
                'role'      => Role::PERSONERO,
                'role_id'   => $personeroRole->id,
                'is_active' => true,
            ]
        );

        // Crear perfil de personero asociado
        $personeroDemo = Personero::updateOrCreate(
            ['user_id' => $personeroUser->id],
            [
                'document_number' => '12345678',
                'phone_number'    => '+51 987 654 321',
            ]
        );

        // ─── MESA LIMA CERCADO (Mesa 030390 para personero demo) ─────────────
        // Asegurar que existan los registros geográficos necesarios
        \Illuminate\Support\Facades\DB::table('departments')->updateOrInsert(
            ['code' => '15'],
            ['name' => 'LIMA', 'updated_at' => now(), 'created_at' => now()]
        );
        \Illuminate\Support\Facades\DB::table('provinces')->updateOrInsert(
            ['code' => '1501'],
            ['department_code' => '15', 'name' => 'LIMA', 'updated_at' => now(), 'created_at' => now()]
        );
        \Illuminate\Support\Facades\DB::table('districts')->updateOrInsert(
            ['code' => '150101'],
            ['province_code' => '1501', 'department_code' => '15', 'name' => 'LIMA', 'updated_at' => now(), 'created_at' => now()]
        );

        $electoralLocationDemo = \App\Models\ElectoralLocation::firstOrCreate(
            ['name' => 'I.E. NUESTRA SEÑORA DE GUADALUPE', 'district_code' => '150101'],
            ['address' => 'Jr. Azángaro 1075, Lima Cercado']
        );

        $mesaLima = \App\Models\PollingStation::firstOrCreate(
            ['code' => '030390'],
            [
                'electoral_location_id' => $electoralLocationDemo->id,
                'registered_voters'     => 300,
                'status'                => 'ACTIVE',
            ]
        );

        $personeroDemo->pollingStations()->sync([$mesaLima->id]);

        $this->command->info('✅  Mesa 030390 asignada al personero demo: personero@conteoya.pe');

        // ─── PERSONERO PUERTO INCA (YUYAPICHIS) ──────────────────────────────
        $puertoIncaUser = User::updateOrCreate(
            ['email' => 'personero.puertoinca@conteoya.pe'],
            [
                'name'      => 'Personero Puerto Inca - Yuyapichis',
                'password'  => Hash::make('Puertoinca123!'),
                'role'      => Role::PERSONERO,
                'role_id'   => $personeroRole->id,
                'is_active' => true,
            ]
        );

        $puertoIncaPersonero = Personero::updateOrCreate(
            ['user_id' => $puertoIncaUser->id],
            [
                'document_number' => '44001122',
                'phone_number'    => '+51 962 111 222',
            ]
        );

        // ─── MESA YUYAPICHIS (PUERTO INCA) ──────────────────────────────────
        // 1. Asegurar la existencia de Departamento, Provincia y Distrito para Yuyapichis
        \Illuminate\Support\Facades\DB::table('departments')->updateOrInsert(
            ['code' => '10'],
            ['name' => 'HUANUCO', 'updated_at' => now(), 'created_at' => now()]
        );
        \Illuminate\Support\Facades\DB::table('provinces')->updateOrInsert(
            ['code' => '1009'],
            ['department_code' => '10', 'name' => 'PUERTO INCA', 'updated_at' => now(), 'created_at' => now()]
        );
        \Illuminate\Support\Facades\DB::table('districts')->updateOrInsert(
            ['code' => '100905'],
            ['province_code' => '1009', 'department_code' => '10', 'name' => 'YUYAPICHIS', 'updated_at' => now(), 'created_at' => now()]
        );

        // 2. Obtener o crear la ElectoralLocation vinculada al distrito de Yuyapichis
        $electoralLocation = \App\Models\ElectoralLocation::firstOrCreate(
            ['name' => 'I.E. YUYAPICHIS', 'district_code' => '100905'],
            [
                'address' => 'Av. Principal s/n, Yuyapichis',
            ]
        );

        // 3. Crear o recuperar la Mesa 040104 vinculada a la ElectoralLocation válida
        $mesaYuyapichis = \App\Models\PollingStation::firstOrCreate(
            ['code' => '040104'],
            [
                'electoral_location_id' => $electoralLocation->id,
                'registered_voters'     => 305,
                'status'                => 'ACTIVE',
            ]
        );

        $puertoIncaPersonero->pollingStations()->sync([$mesaYuyapichis->id]);

        $this->command->info('✅  Usuario PERSONERO PUERTO INCA creado: personero.puertoinca@conteoya.pe / Puertoinca123!');
        $this->command->newLine();
        $this->command->warn('⚠️   Cambiar contraseñas antes de pasar a producción.');
    }
}
