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

        // ─── PERSONERO PUERTO INCA (YUYAPICHIS) ──────────────────────────────
        $personeroRole = Role::where('name', Role::PERSONERO)->firstOrFail();

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

        // ─── MESA YUYAPICHIS (PUERTO INCA, HUÁNUCO) ────────────────────────
        // Obtener o crear la ElectoralLocation vinculada al distrito real de Yuyapichis (090805)
        $electoralLocation = \App\Models\ElectoralLocation::firstOrCreate(
            ['name' => 'I.E. YUYAPICHIS', 'district_code' => '090805'],
            [
                'address' => 'Av. Principal s/n, Yuyapichis',
            ]
        );

        // Obtener o crear la Mesa 021038 (Yuyapichis, Huánuco)
        $mesaYuyapichis = \App\Models\PollingStation::firstOrCreate(
            ['code' => '021038'],
            [
                'electoral_location_id' => $electoralLocation->id,
                'registered_voters'     => 305,
                'status'                => 'ACTIVE',
                'department_code'       => '09',
                'department_name'       => 'HUANUCO',
                'province_name'         => 'PUERTO INCA',
                'district_name'         => 'YUYAPICHIS',
            ]
        );

        $puertoIncaPersonero->pollingStations()->sync([$mesaYuyapichis->id]);

        $this->command->info('✅  Usuario PERSONERO PUERTO INCA creado: personero.puertoinca@conteoya.pe / Puertoinca123!');

        // ─── TERCER PERSONERO (INACTIVO POR DEFECTO) ─────────────────────────
        $inactiveUser = User::updateOrCreate(
            ['email' => 'personero.inactivo@conteoya.pe'],
            [
                'name'      => 'Personero Inactivo Demo',
                'password'  => Hash::make('Personero123!'),
                'role'      => Role::PERSONERO,
                'role_id'   => $personeroRole->id,
                'is_active' => false,
            ]
        );

        $inactivePersonero = Personero::updateOrCreate(
            ['user_id' => $inactiveUser->id],
            [
                'document_number' => '11223344',
                'phone_number'    => '+51 900 000 000',
            ]
        );
        
        $inactivePersonero->pollingStations()->sync([$mesaYuyapichis->id]);
        $this->command->info('✅  Usuario PERSONERO INACTIVO creado: personero.inactivo@conteoya.pe / Personero123!');

        $this->command->newLine();
        $this->command->warn('⚠️   Cambiar contraseñas antes de pasar a producción.');
    }
}
