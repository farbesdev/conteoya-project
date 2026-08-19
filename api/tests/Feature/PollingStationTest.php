<?php

namespace Tests\Feature;

use App\Models\ElectoralLocation;
use App\Models\PollingStation;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PollingStationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(\Database\Seeders\RoleSeeder::class);
    }

    public function test_authenticated_user_can_get_paginated_polling_stations()
    {
        $roleAdmin = Role::where('name', 'ADMIN')->first();
        $admin = User::factory()->create(['role' => Role::ADMIN, 'role_id' => $roleAdmin->id]);

        $response = $this->actingAs($admin)
            ->getJson('/api/v1/polling-stations?per_page=10&page=1');

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
                ]
            ]);
    }

    public function test_admin_can_create_update_and_delete_polling_station()
    {
        $roleAdmin = Role::where('name', 'ADMIN')->first();
        $admin = User::factory()->create(['role' => Role::ADMIN, 'role_id' => $roleAdmin->id]);

        // 1. Create (POST)
        $createRes = $this->actingAs($admin)
            ->postJson('/api/v1/polling-stations', [
                'code'              => '999999',
                'registered_voters' => 350,
                'status'            => 'ACTIVE',
            ]);

        $createRes->assertStatus(201)
            ->assertJsonPath('data.code', '999999');

        $stationId = $createRes->json('data.id');

        // 2. Read (GET)
        $getRes = $this->actingAs($admin)
            ->getJson("/api/v1/polling-stations/{$stationId}");

        $getRes->assertStatus(200)
            ->assertJsonPath('data.registered_voters', 350);

        // 3. Update (PUT)
        $updateRes = $this->actingAs($admin)
            ->putJson("/api/v1/polling-stations/{$stationId}", [
                'registered_voters' => 400,
            ]);

        $updateRes->assertStatus(200)
            ->assertJsonPath('data.registered_voters', 400);

        // 4. Delete (DELETE)
        $deleteRes = $this->actingAs($admin)
            ->deleteJson("/api/v1/polling-stations/{$stationId}");

        $deleteRes->assertStatus(200);

        $this->assertDatabaseMissing('polling_stations', ['id' => $stationId]);
    }

    public function test_personero_cannot_create_or_delete_polling_station()
    {
        $rolePersonero = Role::where('name', 'PERSONERO')->first();
        $personero = User::factory()->create(['role' => Role::PERSONERO, 'role_id' => $rolePersonero->id]);

        $createRes = $this->actingAs($personero)
            ->postJson('/api/v1/polling-stations', [
                'code'              => '888888',
                'registered_voters' => 300,
            ]);

        $createRes->assertStatus(403);
    }

    public function test_pull_sync_limits_polling_stations_for_admin()
    {
        $roleAdmin = Role::where('name', 'ADMIN')->first();
        $admin = User::factory()->create(['role' => Role::ADMIN, 'role_id' => $roleAdmin->id]);

        $response = $this->actingAs($admin)
            ->getJson('/api/v1/sync/pull');

        $response->assertStatus(200);
        $data = $response->json('data.polling_stations');
        $this->assertLessThanOrEqual(10, count($data));
    }

    public function test_search_polling_stations_by_code_odpe_and_location_fields()
    {
        $roleAdmin = Role::where('name', 'ADMIN')->first();
        $admin = User::factory()->create(['role' => Role::ADMIN, 'role_id' => $roleAdmin->id]);

        PollingStation::create([
            'code' => '030499',
            'registered_voters' => 280,
            'status' => 'ACTIVE',
            'odpe' => 'ODPE LIMA CENTRO',
            'department_name' => 'LIMA',
            'province_name' => 'LIMA',
            'district_name' => 'MIRAFLORES',
        ]);

        // 1. Buscar por ODPE en minúsculas
        $resOdpe = $this->actingAs($admin)->getJson('/api/v1/polling-stations?search=lima+centro');
        $resOdpe->assertStatus(200);
        $this->assertCount(1, $resOdpe->json('data'));
        $this->assertEquals('030499', $resOdpe->json('data.0.code'));

        // 2. Buscar por distrito en minúsculas
        $resDist = $this->actingAs($admin)->getJson('/api/v1/polling-stations?search=miraflores');
        $resDist->assertStatus(200);
        $this->assertCount(1, $resDist->json('data'));

        // 3. Buscar por código de mesa
        $resCode = $this->actingAs($admin)->getJson('/api/v1/polling-stations?search=030499');
        $resCode->assertStatus(200);
        $this->assertCount(1, $resCode->json('data'));

        // 4. Buscar por departamento (ej: TUMBES) a través de la jerarquía relacional
        \Illuminate\Support\Facades\DB::table('departments')->updateOrInsert(
            ['code' => '24'],
            ['name' => 'TUMBES', 'updated_at' => now(), 'created_at' => now()]
        );
        \Illuminate\Support\Facades\DB::table('provinces')->updateOrInsert(
            ['code' => '2401'],
            ['department_code' => '24', 'name' => 'TUMBES', 'updated_at' => now(), 'created_at' => now()]
        );
        \Illuminate\Support\Facades\DB::table('districts')->updateOrInsert(
            ['code' => '240101'],
            ['province_code' => '2401', 'department_code' => '24', 'name' => 'TUMBES', 'updated_at' => now(), 'created_at' => now()]
        );

        $locTumbes = \App\Models\ElectoralLocation::firstOrCreate(
            ['name' => 'I.E. 001 JOSE LISHNER TUDELA', 'district_code' => '240101'],
            ['address' => 'Av. Tumbes 123']
        );

        PollingStation::create([
            'code'                  => '080001',
            'electoral_location_id' => $locTumbes->id,
            'registered_voters'     => 290,
            'status'                => 'ACTIVE',
        ]);

        $resTumbes = $this->actingAs($admin)->getJson('/api/v1/polling-stations?search=tumbes');
        $resTumbes->assertStatus(200);
        $this->assertGreaterThanOrEqual(1, count($resTumbes->json('data')));
        $this->assertTrue(collect($resTumbes->json('data'))->contains(fn($m) => $m['code'] === '080001'));
    }
}
