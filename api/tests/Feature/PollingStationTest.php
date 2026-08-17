<?php

namespace Tests\Feature;

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
