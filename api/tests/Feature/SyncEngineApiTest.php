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
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SyncEngineApiTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Personero $personero;
    protected PollingStation $station;
    protected Election $election;
    protected ElectoralLevel $level;
    protected PoliticalOrganization $org;

    protected function setUp(): void
    {
        parent::setUp();

        Role::firstOrCreate(['id' => 1, 'name' => 'ADMIN'], ['display_name' => 'Administrador']);
        Role::firstOrCreate(['id' => 2, 'name' => 'DIRECTOR'], ['display_name' => 'Director']);
        Role::firstOrCreate(['id' => 3, 'name' => 'PERSONERO'], ['display_name' => 'Personero']);

        $department = Department::create(['code' => '15', 'name' => 'LIMA']);
        $province   = Province::create(['code' => '1501', 'department_code' => '15', 'name' => 'LIMA']);
        $district   = District::create(['code' => '150101', 'province_code' => '1501', 'department_code' => '15', 'name' => 'LIMA']);

        $location = ElectoralLocation::create([
            'district_code' => '150101',
            'name'          => 'COLEGIO GUADALUPE',
        ]);

        $this->station = PollingStation::create([
            'electoral_location_id' => $location->id,
            'code'                  => '030390',
            'registered_voters'     => 300,
        ]);

        $this->election = Election::create([
            'code'   => 'ERM2026',
            'name'   => 'Elecciones 2026',
            'date'   => '2026-10-04',
        ]);

        $this->level = ElectoralLevel::create([
            'election_id'           => $this->election->id,
            'code'                  => 'MUNICIPAL_PROVINCIAL',
            'name'                  => 'Municipal Provincial',
            'has_preferential_vote' => false,
        ]);

        $this->org = PoliticalOrganization::create([
            'name'       => 'PARTIDO DEMOCRATA',
            'short_name' => 'PD',
        ]);

        $this->user = User::create([
            'name'      => 'Luis Sync',
            'email'     => 'luis@conteoya.pe',
            'password'  => bcrypt('Secret123!'),
            'role'      => 'PERSONERO',
            'role_id'   => 3,
            'is_active' => true,
        ]);

        $this->personero = Personero::create([
            'user_id'         => $this->user->id,
            'document_number' => '99887766',
        ]);

        \App\Models\Device::create([
            'personero_id' => $this->personero->id,
            'device_uuid'  => 'test-device-uuid-1234',
            'device_model' => 'Pixel 8',
        ]);

        $this->personero->pollingStations()->attach($this->station->id);
    }

    public function test_sync_engine_processes_offline_operations_batch_idempotently(): void
    {
        Sanctum::actingAs($this->user);

        $clientOpId1 = Str::uuid()->toString();

        $payload = [
            'operations' => [
                [
                    'client_operation_id' => $clientOpId1,
                    'entity_type'         => 'acts',
                    'entity_id'           => 'local-act-uuid-1',
                    'operation'           => 'CREATE',
                    'payload'             => [
                        'polling_station_code' => '030390',
                        'election_id'          => $this->election->id,
                        'electoral_level_id'   => $this->level->id,
                        'status'               => 'CONFIRMED',
                        'totals'               => [
                            'registered_voters' => 300,
                            'voters_who_voted'  => 250,
                            'total_votes'       => 250,
                            'blank_votes'       => 10,
                            'null_votes'        => 5,
                            'challenged_votes'  => 0,
                        ],
                        'results'              => [
                            [
                                'political_organization_id' => $this->org->id,
                                'votes'                     => 235,
                                'source'                    => 'MANUAL',
                            ],
                        ],
                    ],
                ],
            ],
        ];

        // 1. Primer envío por sync
        $response1 = $this->postJson('/api/v1/sync', $payload);

        $response1->assertStatus(200)
            ->assertJsonPath('data.0.status', 'SYNCED')
            ->assertJsonPath('data.0.replayed', false);

        $this->assertDatabaseHas('acts', [
            'polling_station_id' => $this->station->id,
            'status'             => 'CONFIRMED',
        ]);

        // 2. Reintento idéntico del sync (mismo client_operation_id)
        $response2 = $this->postJson('/api/v1/sync', $payload);

        $response2->assertStatus(200)
            ->assertJsonPath('data.0.status', 'SYNCED')
            ->assertJsonPath('data.0.replayed', true);

        // Sin duplicados
        $this->assertDatabaseCount('acts', 1);
        $this->assertDatabaseCount('sync_operations', 1);
    }
}
