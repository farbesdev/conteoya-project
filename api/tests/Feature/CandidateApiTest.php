<?php

namespace Tests\Feature;

use App\Models\Candidate;
use App\Models\PoliticalOrganization;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CandidateApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $adminUser;

    protected function setUp(): void
    {
        parent::setUp();

        $adminRole = Role::firstOrCreate(
            ['name' => 'ADMIN'],
            ['description' => 'Administrator with full system access']
        );

        $this->adminUser = User::factory()->create([
            'role_id' => $adminRole->id,
            'role'    => 'ADMIN',
        ]);
    }

    public function test_authenticated_user_can_list_candidates_paginated(): void
    {
        Candidate::create([
            'document_number' => '12345678',
            'full_name'       => 'CANDIDATO TEST 1',
        ]);

        $response = $this->actingAs($this->adminUser, 'sanctum')
            ->getJson('/api/v1/candidates?page=1&per_page=15');

        $response->assertOk()
            ->assertJsonStructure([
                'message',
                'data' => [
                    '*' => [
                        'id',
                        'document_number',
                        'full_name',
                        'position',
                        'status',
                    ],
                ],
                'meta' => [
                    'current_page',
                    'last_page',
                    'per_page',
                    'total',
                ],
            ]);
    }

    public function test_authenticated_user_can_start_and_check_cv_sync_status(): void
    {
        $startResponse = $this->actingAs($this->adminUser, 'sanctum')
            ->postJson('/api/v1/candidates/sync-cvs', [
                'chunk' => 10,
                'delay_ms' => 0,
                'limit' => 5,
            ]);

        $startResponse->assertStatus(202)
            ->assertJsonStructure([
                'message',
                'data' => [
                    'status',
                    'total',
                    'processed',
                ],
            ]);

        $statusResponse = $this->actingAs($this->adminUser, 'sanctum')
            ->getJson('/api/v1/candidates/sync-cvs/status');

        $statusResponse->assertOk()
            ->assertJsonStructure([
                'message',
                'data' => [
                    'status',
                    'total',
                    'processed',
                    'percentage',
                ],
            ]);
    }
}
