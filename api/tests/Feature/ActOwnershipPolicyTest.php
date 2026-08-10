<?php

namespace Tests\Feature;

use App\Models\Department;
use App\Models\District;
use App\Models\Election;
use App\Models\ElectoralLevel;
use App\Models\ElectoralLocation;
use App\Models\Personero;
use App\Models\PoliticalOrganization;
use App\Models\PollingStation;
use App\Models\Province;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ActOwnershipPolicyTest extends TestCase
{
    use RefreshDatabase;

    protected User $personeroUser;
    protected Personero $personero;
    protected PollingStation $assignedStation;
    protected PollingStation $unassignedStation;
    protected Election $election;
    protected ElectoralLevel $level;
    protected PoliticalOrganization $org;

    protected function setUp(): void
    {
        parent::setUp();

        Role::create(['id' => 1, 'name' => 'ADMIN', 'display_name' => 'Administrador']);
        Role::create(['id' => 2, 'name' => 'DIRECTOR', 'display_name' => 'Director']);
        Role::create(['id' => 3, 'name' => 'PERSONERO', 'display_name' => 'Personero']);

        $department = Department::create(['code' => '15', 'name' => 'LIMA']);
        $province   = Province::create(['code' => '1501', 'department_code' => '15', 'name' => 'LIMA']);
        $district   = District::create(['code' => '150101', 'province_code' => '1501', 'department_code' => '15', 'name' => 'LIMA']);

        $location = ElectoralLocation::create([
            'district_code' => '150101',
            'name'          => 'COLEGIO GUADALUPE',
        ]);

        $this->assignedStation = PollingStation::create([
            'electoral_location_id' => $location->id,
            'code'                  => '030390',
            'registered_voters'     => 300,
        ]);

        $this->unassignedStation = PollingStation::create([
            'electoral_location_id' => $location->id,
            'code'                  => '999999',
            'registered_voters'     => 300,
        ]);

        $this->election = Election::create([
            'code'   => 'ERM2026',
            'name'   => 'Elecciones Regionales 2026',
            'date'   => '2026-10-04',
            'status' => 'ACTIVE',
        ]);

        $this->level = ElectoralLevel::create([
            'election_id'           => $this->election->id,
            'code'                  => 'REGIONAL_GOBERNADOR',
            'name'                  => 'Gobernador Regional',
            'has_preferential_vote' => false,
        ]);

        $this->org = PoliticalOrganization::create([
            'name'       => 'PARTIDO NACIONAL',
            'short_name' => 'PN',
        ]);

        $this->personeroUser = User::create([
            'name'      => 'Pedro Personero',
            'email'     => 'pedro@conteoya.pe',
            'password'  => bcrypt('Secret123!'),
            'role'      => 'PERSONERO',
            'role_id'   => 3,
            'is_active' => true,
        ]);

        $this->personero = Personero::create([
            'user_id'         => $this->personeroUser->id,
            'document_number' => '11223344',
        ]);

        // Asignar solo la mesa 030390
        $this->personero->pollingStations()->attach($this->assignedStation->id);
    }

    public function test_personero_cannot_create_act_for_unassigned_polling_station(): void
    {
        Sanctum::actingAs($this->personeroUser);

        $payload = [
            'polling_station_code' => '999999', // Mesa no asignada
            'election_id'          => $this->election->id,
            'electoral_level_id'   => $this->level->id,
            'totals'               => [
                'registered_voters' => 300,
                'voters_who_voted'  => 200,
                'total_votes'       => 200,
            ],
            'results'              => [
                [
                    'political_organization_id' => $this->org->id,
                    'votes'                     => 200,
                ],
            ],
        ];

        $response = $this->postJson('/api/v1/acts', $payload);

        // Debe retornar 403 Forbidden
        $response->assertStatus(403);
    }
}
