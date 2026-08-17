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

        $station = PollingStation::create([
            'code' => '030390',
            'registered_voters' => 300,
            'status' => 'ACTIVE',
            'department_name' => 'LIMA',
            'province_name' => 'LIMA',
            'district_name' => 'LIMA'
        ]);

        $org = PoliticalOrganization::create([
            'name' => 'PARTIDO TEST',
            'short_name' => 'PT',
        ]);

        $list = ElectoralList::create([
            'political_organization_id' => $org->id,
            'electoral_level_id' => $level->id,
            'status' => 'INSCRITO',
            'department_code' => null
        ]);

        $response = $this->actingAs($user, 'sanctum')
            ->getJson("/api/v1/ballot-template?polling_station_code=030390&electoral_level_id={$level->id}");

        $response->assertStatus(200)
            ->assertJsonPath('data.station.code', '030390')
            ->assertJsonPath('data.electoral_level.code', 'REGIONAL_GOBERNADOR')
            ->assertJsonCount(1, 'data.lists');
    }
}
