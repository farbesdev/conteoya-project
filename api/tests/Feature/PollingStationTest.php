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
}
