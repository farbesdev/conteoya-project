<?php

namespace Tests\Feature;

use App\Events\ActConfirmedEvent;
use App\Models\Act;
use App\Models\ActResult;
use App\Models\ActTotal;
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
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

class ResultsApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $adminUser;
    protected Election $election;
    protected ElectoralLevel $level;
    protected PollingStation $station1;
    protected PollingStation $station2;
    protected PoliticalOrganization $org1;
    protected PoliticalOrganization $org2;

    protected function setUp(): void
    {
        parent::setUp();

        $adminRole = Role::firstOrCreate(['name' => 'ADMIN'], ['description' => 'Administrator']);
        $this->adminUser = User::factory()->create([
            'role_id'   => $adminRole->id,
            'role'      => 'ADMIN',
            'is_active' => true,
        ]);

        $this->election = Election::create([
            'code' => 'ERM2026',
            'name' => 'Elecciones Regionales y Municipales 2026',
            'date' => '2026-10-04',
        ]);

        $this->level = ElectoralLevel::create([
            'election_id' => $this->election->id,
            'code'        => 'REGIONAL_GOBERNADOR',
            'name'        => 'Gobernador Regional',
        ]);

        $dept = Department::firstOrCreate(['code' => '15'], ['name' => 'LIMA']);
        $prov = Province::firstOrCreate(['code' => '1501'], ['name' => 'LIMA', 'department_code' => '15']);
        $dist = District::firstOrCreate(['code' => '150101'], ['name' => 'LIMA', 'province_code' => '1501', 'department_code' => '15']);

        $location = ElectoralLocation::create([
            'code'          => '150101-01',
            'name'          => 'COLEGIO NACIONAL GUADALUPE',
            'address'       => 'AV. ALFONSO UGARTE 1227',
            'district_code' => $dist->code,
        ]);

        $this->station1 = PollingStation::create([
            'code'                  => '030001',
            'electoral_location_id' => $location->id,
            'registered_voters'     => 300,
            'status'                => 'ACTIVE',
            'department_name'       => 'LIMA',
            'province_name'         => 'LIMA',
            'district_name'         => 'LIMA',
        ]);

        $this->station2 = PollingStation::create([
            'code'                  => '030002',
            'electoral_location_id' => $location->id,
            'registered_voters'     => 200,
            'status'                => 'ACTIVE',
            'department_name'       => 'LIMA',
            'province_name'         => 'LIMA',
            'district_name'         => 'LIMA',
        ]);

        $this->org1 = PoliticalOrganization::create([
            'jee_id'     => 1,
            'name'       => 'PARTIDO DEMOCRATICO PERUANO',
            'short_name' => 'PDP',
            'org_type'   => 'PARTIDO_POLITICO',
        ]);

        $this->org2 = PoliticalOrganization::create([
            'jee_id'     => 2,
            'name'       => 'MOVIMIENTO REGIONAL AVANZA',
            'short_name' => 'MRA',
            'org_type'   => 'MOVIMIENTO_REGIONAL',
        ]);
        $personeroRole = Role::firstOrCreate(['name' => 'PERSONERO'], ['description' => 'Personero']);
        $personeroUser = User::factory()->create([
            'role_id'   => $personeroRole->id,
            'role'      => 'PERSONERO',
            'is_active' => true,
        ]);

        $this->personero = Personero::create([
            'user_id'         => $personeroUser->id,
            'document_number' => '44556677',
            'phone_number'    => '999888777',
        ]);
    }

    public function test_public_can_get_results_summary(): void
    {
        // Crear acta confirmada en mesa 1
        $act = Act::create([
            'election_id'              => $this->election->id,
            'electoral_level_id'       => $this->level->id,
            'polling_station_id'       => $this->station1->id,
            'act_code'                 => 'ACT-030001',
            'status'                   => 'CONFIRMED',
            'captured_by_personero_id' => $this->personero->id,
            'confirmed_at'             => now(),
        ]);

        ActTotal::create([
            'act_id'            => $act->id,
            'registered_voters' => 300,
            'voters_who_voted'  => 250,
            'total_votes'       => 250,
            'blank_votes'       => 10,
            'null_votes'        => 15,
            'challenged_votes'  => 5,
            'is_valid_total'    => true,
        ]);

        ActResult::create([
            'act_id'                    => $act->id,
            'political_organization_id' => $this->org1->id,
            'votes'                     => 140,
            'source'                    => 'MANUAL',
        ]);

        ActResult::create([
            'act_id'                    => $act->id,
            'political_organization_id' => $this->org2->id,
            'votes'                     => 80,
            'source'                    => 'MANUAL',
        ]);

        $response = $this->getJson('/api/v1/results/summary');

        $response->assertStatus(200)
            ->assertJsonPath('data.total_stations', 2)
            ->assertJsonPath('data.processed_stations', 1)
            ->assertJsonPath('data.pending_stations', 1)
            ->assertJsonPath('data.coverage_percentage', 50)
            ->assertJsonPath('data.registered_voters', 500)
            ->assertJsonPath('data.voters_who_voted', 250)
            ->assertJsonPath('data.total_votes', 250)
            ->assertJsonPath('data.valid_votes', 220)
            ->assertJsonPath('data.blank_votes', 10)
            ->assertJsonPath('data.null_votes', 15)
            ->assertJsonPath('data.challenged_votes', 5);
    }

    public function test_public_can_get_election_results_ranking(): void
    {
        $act = Act::create([
            'election_id'              => $this->election->id,
            'electoral_level_id'       => $this->level->id,
            'polling_station_id'       => $this->station1->id,
            'act_code'                 => 'ACT-030001',
            'status'                   => 'CONFIRMED',
            'captured_by_personero_id' => $this->personero->id,
            'confirmed_at'             => now(),
        ]);

        ActTotal::create([
            'act_id'            => $act->id,
            'registered_voters' => 300,
            'voters_who_voted'  => 250,
            'total_votes'       => 250,
            'blank_votes'       => 10,
            'null_votes'        => 15,
            'challenged_votes'  => 5,
            'is_valid_total'    => true,
        ]);

        ActResult::create([
            'act_id'                    => $act->id,
            'political_organization_id' => $this->org1->id,
            'votes'                     => 140,
            'source'                    => 'MANUAL',
        ]);

        ActResult::create([
            'act_id'                    => $act->id,
            'political_organization_id' => $this->org2->id,
            'votes'                     => 80,
            'source'                    => 'MANUAL',
        ]);

        $response = $this->getJson("/api/v1/results/elections/{$this->election->id}");

        $response->assertStatus(200)
            ->assertJsonPath('data.organizations.0.political_organization_id', $this->org1->id)
            ->assertJsonPath('data.organizations.0.votes', 140)
            ->assertJsonPath('data.organizations.0.percentage_valid_votes', 63.64)
            ->assertJsonPath('data.organizations.1.political_organization_id', $this->org2->id)
            ->assertJsonPath('data.organizations.1.votes', 80)
            ->assertJsonPath('data.organizations.1.percentage_valid_votes', 36.36);
    }

    public function test_public_can_get_polling_station_results(): void
    {
        $act = Act::create([
            'election_id'              => $this->election->id,
            'electoral_level_id'       => $this->level->id,
            'polling_station_id'       => $this->station1->id,
            'act_code'                 => 'ACT-030001',
            'status'                   => 'CONFIRMED',
            'captured_by_personero_id' => $this->personero->id,
            'confirmed_at'             => now(),
        ]);

        ActTotal::create([
            'act_id'            => $act->id,
            'registered_voters' => 300,
            'voters_who_voted'  => 250,
            'total_votes'       => 250,
            'blank_votes'       => 10,
            'null_votes'        => 15,
            'challenged_votes'  => 5,
            'is_valid_total'    => true,
        ]);

        $response = $this->getJson("/api/v1/results/polling-stations/{$this->station1->code}");

        $response->assertStatus(200)
            ->assertJsonPath('data.polling_station.code', '030001')
            ->assertJsonPath('data.acts.0.act_code', 'ACT-030001');
    }

    public function test_admin_can_list_acts_paginated(): void
    {
        Act::create([
            'election_id'              => $this->election->id,
            'electoral_level_id'       => $this->level->id,
            'polling_station_id'       => $this->station1->id,
            'act_code'                 => 'ACT-030001',
            'status'                   => 'CONFIRMED',
            'captured_by_personero_id' => $this->personero->id,
        ]);

        $response = $this->actingAs($this->adminUser)->getJson('/api/v1/acts');

        $response->assertStatus(200)
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.act_code', 'ACT-030001');
    }
}
