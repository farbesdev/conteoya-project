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

    public function test_admin_can_assign_multiple_polling_stations_to_personero(): void
    {
        $adminRole = Role::where('name', Role::ADMIN)->first();
        $admin = User::factory()->create([
            'role'      => Role::ADMIN,
            'role_id'   => $adminRole->id,
            'is_active' => true,
        ]);

        $personeroUser = User::factory()->create(['role' => Role::PERSONERO]);
        $personero = Personero::create([
            'user_id'         => $personeroUser->id,
            'document_number' => '99887766',
        ]);

        // Crear 3 mesas con jerarquía geográfica válida
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

        $loc = \App\Models\ElectoralLocation::firstOrCreate(
            ['name' => 'COLEGIO NACIONAL TEST', 'district_code' => '150101'],
            ['address' => 'Av. Central 123']
        );

        $m1 = \App\Models\PollingStation::firstOrCreate(['code' => '900001'], ['electoral_location_id' => $loc->id, 'registered_voters' => 300, 'status' => 'ACTIVE']);
        $m2 = \App\Models\PollingStation::firstOrCreate(['code' => '900002'], ['electoral_location_id' => $loc->id, 'registered_voters' => 300, 'status' => 'ACTIVE']);
        $m3 = \App\Models\PollingStation::firstOrCreate(['code' => '900003'], ['electoral_location_id' => $loc->id, 'registered_voters' => 300, 'status' => 'ACTIVE']);

        // Asignar las 3 mesas vía API
        $response = $this->actingAs($admin)->postJson("/api/v1/personeros/{$personero->id}/polling-stations", [
            'polling_station_codes' => ['900001', '900002', '900003'],
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'message'               => 'Mesas asignadas exitosamente al personero.',
                'personero_id'          => $personero->id,
                'polling_station_codes' => ['900001', '900002', '900003'],
                'assigned_count'        => 3,
            ]);

        $this->assertEquals(3, $personero->fresh()->pollingStations()->count());
    }
}
