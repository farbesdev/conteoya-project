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
        $roleAdmin = Role::where('name', 'ADMIN')->first();
        $admin = User::factory()->create(['role' => Role::ADMIN, 'role_id' => $roleAdmin->id]);

        $response = $this->actingAs($admin)
            ->getJson('/api/v1/users');

        $response->assertStatus(200);
    }

    public function test_admin_can_create_personero_user()
    {
        $roleAdmin = Role::where('name', 'ADMIN')->first();
        $admin = User::factory()->create(['role' => Role::ADMIN, 'role_id' => $roleAdmin->id]);

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

    public function test_admin_can_reset_user_password()
    {
        $roleAdmin = Role::where('name', 'ADMIN')->first();
        $admin = User::factory()->create(['role' => Role::ADMIN, 'role_id' => $roleAdmin->id]);
        $targetUser = User::factory()->create(['role' => Role::PERSONERO, 'password' => \Illuminate\Support\Facades\Hash::make('OldPassword123!')]);

        $response = $this->actingAs($admin)
            ->postJson("/api/v1/users/{$targetUser->id}/reset-password", [
                'password' => 'NewPassword123!',
            ]);

        $response->assertStatus(200)
            ->assertJson([
                'user_id' => $targetUser->id,
                'new_password' => 'NewPassword123!',
            ]);

        $this->assertTrue(\Illuminate\Support\Facades\Hash::check('NewPassword123!', $targetUser->fresh()->password));
    }
}
