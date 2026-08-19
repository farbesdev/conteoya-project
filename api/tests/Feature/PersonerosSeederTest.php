<?php

namespace Tests\Feature;

use App\Models\Election;
use App\Models\Personero;
use App\Models\PoliticalOrganization;
use App\Models\Role;
use App\Models\User;
use Database\Seeders\PersonerosSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PersonerosSeederTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(RoleSeeder::class);
    }

    public function test_personeros_seeder_imports_and_consolidates_jee_records(): void
    {
        // 1. Crear organización política de prueba para el mapeo
        PoliticalOrganization::create([
            'name'       => 'ACCION POPULAR',
            'short_name' => 'AP',
            'jee_id'     => 4,
        ]);

        // 2. Ejecutar Seeder
        $this->seed(PersonerosSeeder::class);

        // 3. Verificar Elección ERM 2026 actualizada con el proceso JNE 126
        $election = Election::where('code', 'ERM2026')->first();
        $this->assertNotNull($election);
        $this->assertEquals(126, $election->jee_proceso_electoral_id);

        // 4. Verificar que se importaron personeros
        $totalPersoneros = Personero::count();
        $this->assertGreaterThan(1000, $totalPersoneros);

        // 5. Verificar personero específico (Josei Antonio Espinoza Silva)
        $personero = Personero::where('document_number', '42275934')->first();
        $this->assertNotNull($personero);
        $this->assertEquals('JOSEI ANTONIO ESPINOZA SILVA', $personero->full_name);
        $this->assertEquals('ACCION POPULAR', $personero->political_organization_name);
        $this->assertEquals('PERSONERO TÉCNICO TITULAR', $personero->personero_type);
        $this->assertEquals('RECONOCIDO', $personero->status);
        $this->assertNotNull($personero->user_id);

        // 6. Verificar que su usuario User nace inactivo (is_active = false) por defecto
        $user = $personero->user;
        $this->assertNotNull($user);
        $this->assertFalse($user->is_active);
        $this->assertEquals(Role::PERSONERO, $user->role);
    }

    public function test_admin_can_list_and_search_paginated_personeros(): void
    {
        $adminRole = Role::where('name', Role::ADMIN)->first();
        $admin = User::factory()->create([
            'role'      => Role::ADMIN,
            'role_id'   => $adminRole->id,
            'is_active' => true,
        ]);

        PoliticalOrganization::create([
            'name'       => 'ACCION POPULAR',
            'short_name' => 'AP',
            'jee_id'     => 4,
        ]);

        $this->seed(PersonerosSeeder::class);

        // 1. Listar página 1 con 10 personeros
        $response = $this->actingAs($admin)->getJson('/api/v1/personeros?per_page=10&page=1');
        $response->assertStatus(200)
            ->assertJsonStructure([
                'message',
                'data',
                'meta' => [
                    'current_page',
                    'last_page',
                    'per_page',
                    'total',
                    'has_more',
                ],
            ]);
        $this->assertCount(10, $response->json('data'));

        // 2. Buscar por DNI
        $searchDni = $this->actingAs($admin)->getJson('/api/v1/personeros?search=42275934');
        $searchDni->assertStatus(200);
        $this->assertGreaterThanOrEqual(1, count($searchDni->json('data')));
        $this->assertEquals('42275934', $searchDni->json('data.0.dni'));

        // 3. Buscar por Nombre en Mayúsculas
        $searchNameUpper = $this->actingAs($admin)->getJson('/api/v1/personeros?search=ESPINOZA');
        $searchNameUpper->assertStatus(200);
        $this->assertGreaterThanOrEqual(1, count($searchNameUpper->json('data')));

        // 4. Buscar por Apellido en Minúsculas (case-insensitive)
        $searchNameLower = $this->actingAs($admin)->getJson('/api/v1/personeros?search=espinoza');
        $searchNameLower->assertStatus(200);
        $this->assertGreaterThanOrEqual(1, count($searchNameLower->json('data')));
        $this->assertTrue(collect($searchNameLower->json('data'))->contains(fn($p) => str_contains($p['dni'], '42275934')));

        // 5. Buscar por Múltiples Palabras (Nombre y Apellido compuestos)
        $searchMulti = $this->actingAs($admin)->getJson('/api/v1/personeros?search=josei+silva');
        $searchMulti->assertStatus(200);
        $this->assertGreaterThanOrEqual(1, count($searchMulti->json('data')));
        $this->assertTrue(collect($searchMulti->json('data'))->contains(fn($p) => str_contains($p['dni'], '42275934')));
    }
}
