<?php

namespace Tests\Feature;

use App\Models\Role;
use App\Models\User;
use App\Models\Personero;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserCrudTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(\Database\Seeders\RoleSeeder::class);
    }

    public function test_admin_can_list_users()
    {
        $admin = User::factory()->create(['role' => Role::ADMIN, 'role_id' => 1]);

        $response = $this->actingAs($admin)
            ->getJson('/api/v1/users');

        $response->assertStatus(200);
    }

    public function test_admin_can_create_personero_user()
    {
        $admin = User::factory()->create(['role' => Role::ADMIN, 'role_id' => 1]);

        $response = $this->actingAs($admin)
            ->postJson('/api/v1/users', [
                'name' => 'Carlos Personero',
                'email' => 'carlos@conteoya.pe',
                'password' => 'Secret123!',
                'role' => 'PERSONERO',
                'document_number' => '44556677',
                'phone_number' => '987123456',
            ]);

        $response->assertStatus(211);
        $this->assertDatabaseHas('users', ['email' => 'carlos@conteoya.pe', 'role' => 'PERSONERO']);
        $this->assertDatabaseHas('personeros', ['document_number' => '44556677']);
    }
}
