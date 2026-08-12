<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     *
     * Orden de ejecución:
     *  1. RoleSeeder     → Crea los 3 roles del sistema (ADMIN, DIRECTOR, PERSONERO)
     *  2. UserSeeder     → Crea un usuario de prueba por cada rol
     *  3. JeeDatabaseSeeder → Carga datos JEE (departamentos, provincias, distritos, elecciones…)
     */
    public function run(): void
    {
        $this->call([
            RoleSeeder::class,
            JeeDatabaseSeeder::class,
            UserSeeder::class,
        ]);
    }
}
