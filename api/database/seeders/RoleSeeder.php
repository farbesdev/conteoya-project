<?php

namespace Database\Seeders;

use App\Models\Role;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    /**
     * Roles predefinidos del sistema ConteoYA.
     *
     * - ADMIN:     Administrador del sistema. Acceso total.
     * - DIRECTOR:  Director de campaña / supervisor de sede. Puede gestionar personeros y ver resultados consolidados.
     * - PERSONERO: Personero de mesa. Captura actas desde la aplicación móvil.
     */
    public function run(): void
    {
        $roles = [
            [
                'name'         => Role::ADMIN,
                'display_name' => 'Administrador',
                'description'  => 'Acceso total al sistema. Gestiona elecciones, usuarios y configuración.',
            ],
            [
                'name'         => Role::DIRECTOR,
                'display_name' => 'Director',
                'description'  => 'Supervisor de sede electoral. Gestiona personeros asignados y consulta resultados en tiempo real.',
            ],
            [
                'name'         => Role::PERSONERO,
                'display_name' => 'Personero',
                'description'  => 'Personero de mesa. Captura y envía actas electorales desde la aplicación móvil.',
            ],
        ];

        foreach ($roles as $roleData) {
            Role::updateOrCreate(
                ['name' => $roleData['name']],
                $roleData
            );
        }

        $this->command->info('✅  Roles creados: ADMIN, DIRECTOR, PERSONERO.');
    }
}
