<?php

namespace Tests\Feature;

use App\Models\Personero;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PersoneroAccessTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->seed(\Database\Seeders\RoleSeeder::class);
    }

    public function test_admin_can_toggle_personero_access_and_revokes_tokens(): void
    {
        $adminRole = Role::where('name', Role::ADMIN)->first();
        $admin = User::factory()->create([
            'role'      => Role::ADMIN,
            'role_id'   => $adminRole->id,
            'is_active' => true,
        ]);

        $personeroRole = Role::where('name', Role::PERSONERO)->first();
        $personeroUser = User::factory()->create([
            'role'      => Role::PERSONERO,
            'role_id'   => $personeroRole->id,
            'is_active' => true,
        ]);

        $personero = Personero::create([
            'user_id'         => $personeroUser->id,
            'document_number' => '88776655',
            'phone_number'    => '999888777',
        ]);

        // Crear token activo para el personero
        $token = $personeroUser->createToken('MobileDevice')->plainTextToken;
        $this->assertCount(1, $personeroUser->tokens);

        // El personero puede consultar /me
        $responseMe = $this->withToken($token)->getJson('/api/v1/me');
        $responseMe->assertStatus(200);

        // Admin desactiva al personero
        $adminToken = $admin->createToken('AdminDevice')->plainTextToken;
        $responseToggle = $this->withToken($adminToken)->patchJson("/api/v1/personeros/{$personero->id}/toggle-access");
        $responseToggle->assertStatus(200)
            ->assertJson([
                'is_active' => false,
            ]);

        // Tokens deben haber sido eliminados
        $personeroUser->refresh();
        $this->assertFalse($personeroUser->is_active);
        $this->assertCount(0, $personeroUser->tokens);

        // El token anterior del personero ya no es válido (retorna 401 Unauthenticated)
        $this->app['auth']->forgetGuards();
        $responseUnauthorized = $this->withToken($token)->getJson('/api/v1/me');
        $responseUnauthorized->assertStatus(401);
    }

    public function test_inactive_user_cannot_access_protected_routes(): void
    {
        $personeroRole = Role::where('name', Role::PERSONERO)->first();
        $personeroUser = User::factory()->create([
            'role'      => Role::PERSONERO,
            'role_id'   => $personeroRole->id,
            'is_active' => false,
        ]);

        $token = $personeroUser->createToken('MobileDevice')->plainTextToken;

        // Intentar consultar ruta protegida debe retornar 403 y revocar el token
        $response = $this->withToken($token)->getJson('/api/v1/me');
        $response->assertStatus(403)
            ->assertJson([
                'message' => 'Su cuenta se encuentra inhabilitada. Comuníquese con el Administrador.',
            ]);

        $this->assertCount(0, $personeroUser->fresh()->tokens);
    }

    public function test_user_can_login_with_email_or_dni_and_assigned_password(): void
    {
        $personeroRole = Role::where('name', Role::PERSONERO)->first();
        $personeroUser = User::factory()->create([
            'email'     => 'juan.perez@conteoya.pe',
            'password'  => \Illuminate\Support\Facades\Hash::make('42275934!'),
            'role'      => Role::PERSONERO,
            'role_id'   => $personeroRole->id,
            'is_active' => true,
        ]);

        Personero::create([
            'user_id'         => $personeroUser->id,
            'document_number' => '42275934',
            'full_name'       => 'JUAN PEREZ',
        ]);

        // 1. Iniciar sesión usando DNI y contraseña "42275934!"
        $responseDni = $this->postJson('/api/v1/login', [
            'email'    => '42275934',
            'password' => '42275934!',
        ]);

        $responseDni->assertStatus(200)
            ->assertJsonStructure([
                'access_token',
                'token_type',
                'user' => ['id', 'email', 'role'],
            ]);

        // 2. Iniciar sesión usando Correo Electrónico
        $responseEmail = $this->postJson('/api/v1/login', [
            'email'    => 'juan.perez@conteoya.pe',
            'password' => '42275934!',
        ]);

        $responseEmail->assertStatus(200)
            ->assertJsonStructure(['access_token']);
    }

    public function test_admin_can_delete_personero_and_associated_user(): void
    {
        $adminRole = Role::where('name', Role::ADMIN)->first();
        $admin = User::factory()->create([
            'role'      => Role::ADMIN,
            'role_id'   => $adminRole->id,
            'is_active' => true,
        ]);
        $adminToken = $admin->createToken('AdminDevice')->plainTextToken;

        $personeroRole = Role::where('name', Role::PERSONERO)->first();
        $personeroUser = User::factory()->create([
            'role'      => Role::PERSONERO,
            'role_id'   => $personeroRole->id,
            'is_active' => true,
        ]);

        $personero = Personero::create([
            'user_id'         => $personeroUser->id,
            'document_number' => '12345678',
            'full_name'       => 'Juan Pérez Demo',
        ]);

        $response = $this->withToken($adminToken)->deleteJson("/api/v1/personeros/{$personero->id}");
        $response->assertStatus(200)
            ->assertJson(['message' => 'Personero eliminado exitosamente del sistema.']);

        $this->assertDatabaseMissing('personeros', ['id' => $personero->id]);
        $this->assertDatabaseMissing('users', ['id' => $personeroUser->id]);
    }
}
