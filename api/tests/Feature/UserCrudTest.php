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

    public function test_admin_can_search_users_case_insensitively_by_name_email_and_dni()
    {
        $roleAdmin = Role::where('name', 'ADMIN')->first();
        $admin = User::factory()->create(['role' => Role::ADMIN, 'role_id' => $roleAdmin->id]);

        $personeroUser = User::factory()->create([
            'name' => 'JUAN CARLOS FLORES',
            'email' => 'juan.flores@conteoya.pe',
            'role' => Role::PERSONERO,
        ]);

        Personero::create([
            'user_id' => $personeroUser->id,
            'document_number' => '87654321',
            'full_name' => 'JUAN CARLOS FLORES',
            'first_name' => 'JUAN CARLOS',
        ]);

        // 1. Buscar por nombre en minúsculas
        $resName = $this->actingAs($admin)->getJson('/api/v1/users?search=carlos');
        $resName->assertStatus(200);
        $this->assertCount(1, $resName->json('data'));
        $this->assertEquals('juan.flores@conteoya.pe', $resName->json('data.0.email'));

        // 2. Buscar por DNI
        $resDni = $this->actingAs($admin)->getJson('/api/v1/users?search=87654321');
        $resDni->assertStatus(200);
        $this->assertCount(1, $resDni->json('data'));

        // 3. Buscar por email en mayúsculas
        $resEmail = $this->actingAs($admin)->getJson('/api/v1/users?search=JUAN.FLORES');
        $resEmail->assertStatus(200);
        $this->assertCount(1, $resEmail->json('data'));
    }

    public function test_admin_can_reset_personero_password_by_id_and_dni()
    {
        $roleAdmin = Role::where('name', 'ADMIN')->first();
        $admin = User::factory()->create(['role' => Role::ADMIN, 'role_id' => $roleAdmin->id]);

        $personeroUser = User::factory()->create([
            'name' => 'Maria Lopez',
            'email' => 'maria.personero@conteoya.pe',
            'role' => Role::PERSONERO,
            'password' => \Illuminate\Support\Facades\Hash::make('OldPassword123!'),
        ]);

        $personero = Personero::create([
            'user_id' => $personeroUser->id,
            'document_number' => '41947287',
            'full_name' => 'Maria Lopez',
            'first_name' => 'Maria',
        ]);

        // 1. Resetear por ID numérico de personero
        $res1 = $this->actingAs($admin)
            ->postJson("/api/v1/personeros/{$personero->id}/reset-password", [
                'password' => 'PassOne123!',
            ]);
        $res1->assertStatus(200)
            ->assertJson([
                'personero_id' => $personero->id,
                'user_id' => $personeroUser->id,
                'new_password' => 'PassOne123!',
            ]);
        $this->assertTrue(\Illuminate\Support\Facades\Hash::check('PassOne123!', $personeroUser->fresh()->password));

        // 2. Resetear por DNI
        $res2 = $this->actingAs($admin)
            ->postJson("/api/v1/personeros/41947287/reset-password", [
                'password' => '41947287!',
            ]);
        $res2->assertStatus(200);
        $this->assertTrue(\Illuminate\Support\Facades\Hash::check('41947287!', $personeroUser->fresh()->password));
        // Asegurarse de que el usuario Admin no fue afectado
        $this->assertFalse(\Illuminate\Support\Facades\Hash::check('41947287!', $admin->fresh()->password));

        // 3. Resetear sin enviar password (autogenerar default: [dni]!)
        $res3 = $this->actingAs($admin)
            ->postJson("/api/v1/personeros/41947287/reset-password");
        $res3->assertStatus(200)
            ->assertJson([
                'new_password' => '41947287!',
            ]);
        $this->assertTrue(\Illuminate\Support\Facades\Hash::check('41947287!', $personeroUser->fresh()->password));
    }
}
