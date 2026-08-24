<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use App\Models\Role;
use App\Models\Election;
use App\Models\ElectoralLevel;
use App\Models\PoliticalOrganization;
use App\Models\ElectoralList;
use App\Models\PollingStation;
use App\Models\District;
use App\Models\Department;
use App\Models\Province;
use Illuminate\Foundation\Testing\RefreshDatabase;

class BallotTemplateTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_fetch_ballot_template_for_polling_station(): void
    {
        $role = Role::create(['name' => Role::ADMIN, 'display_name' => 'Admin']);
        $user = User::factory()->create(['role' => Role::ADMIN, 'role_id' => $role->id]);

        $election = Election::create([
            'code' => 'ERM2026',
            'name' => 'Elecciones 2026',
            'date' => '2026-10-04',
            'status' => 'ACTIVE'
        ]);

        $level = ElectoralLevel::create([
            'election_id' => $election->id,
            'code' => 'REGIONAL_GOBERNADOR',
            'name' => 'Gobernador Regional',
            'has_preferential_vote' => false
        ]);

        // Crear catálogo de ubigeo mínimo para la resolución de department_code
        Department::insert(['code' => '14', 'name' => 'LIMA']);
        Province::insert(['code' => '1401', 'department_code' => '14', 'name' => 'LIMA']);
        District::insert([
            'code' => '140101',
            'province_code' => '1401',
            'department_code' => '14',
            'name' => 'LIMA',
        ]);

        // La mesa incluye department_code directamente (estrategia 1 — primaria)
        // Esto refleja cómo el sistema funciona post-migración.
        $station = PollingStation::create([
            'code'              => '030390',
            'registered_voters' => 300,
            'status'            => 'ACTIVE',
            'department_name'   => 'LIMA',
            'province_name'     => 'LIMA',
            'district_name'     => 'LIMA',
            'department_code'   => '14', // ← campo nuevo que resuelve el bug
        ]);

        $org = PoliticalOrganization::create([
            'name'       => 'PARTIDO TEST',
            'short_name' => 'PT',
        ]);

        $list = ElectoralList::create([
            'political_organization_id' => $org->id,
            'electoral_level_id'        => $level->id,
            'status'                    => 'INSCRITO',
            'department_code'           => '14',  // ← coincide con el dept de la mesa
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/ballot-template?polling_station_code=030390&electoral_level_id={$level->id}");

        $response->assertStatus(200)
            ->assertJsonPath('data.station.code', '030390')
            ->assertJsonPath('data.electoral_level.code', 'REGIONAL_GOBERNADOR')
            ->assertJsonCount(1, 'data.lists');
    }

    public function test_ballot_template_returns_404_when_department_cannot_be_resolved(): void
    {
        // Prueba que la guardia funciona: mesa sin district ni department_code → 404
        $role = Role::create(['name' => Role::ADMIN, 'display_name' => 'Admin']);
        $user = User::factory()->create(['role' => Role::ADMIN, 'role_id' => $role->id]);

        $election = Election::create([
            'code' => 'ERM2026',
            'name' => 'Elecciones 2026',
            'date' => '2026-10-04',
            'status' => 'ACTIVE',
        ]);

        $level = ElectoralLevel::create([
            'election_id'        => $election->id,
            'code'               => 'REGIONAL_GOBERNADOR',
            'name'               => 'Gobernador Regional',
            'has_preferential_vote' => false,
        ]);

        // Mesa sin department_code y sin catálogo de ubigeo → debe retornar 404
        PollingStation::create([
            'code'              => '999999',
            'registered_voters' => 300,
            'status'            => 'ACTIVE',
            'department_name'   => 'DEPARTAMENTO_INEXISTENTE',
            'province_name'     => 'PROVINCIA_INEXISTENTE',
            'district_name'     => 'DISTRITO_INEXISTENTE',
            'department_code'   => null,
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/ballot-template?polling_station_code=999999&electoral_level_id={$level->id}");

        // La guardia debe retornar 404 en lugar de listas vacías o de otro departamento
        $response->assertStatus(404);
    }
}
