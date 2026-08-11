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
        Personero::updateOrCreate(
            ['user_id' => $personeroUser->id],
            [
                'document_number' => '12345678',
                'phone_number'    => '+51 987 654 321',
            ]
        );

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

        // Asignar Mesa 040104 (Yuyapichis) si la mesa existe en la BD
        $mesaYuyapichis = \App\Models\PollingStation::where('code', '040104')->first();
        if ($mesaYuyapichis) {
            $puertoIncaPersonero->pollingStations()->sync([$mesaYuyapichis->id]);
        }

        $this->command->info('✅  Usuario PERSONERO PUERTO INCA creado: personero.puertoinca@conteoya.pe / Puertoinca123!');
        $this->command->newLine();
        $this->command->warn('⚠️   Cambiar contraseñas antes de pasar a producción.');
    }
}
