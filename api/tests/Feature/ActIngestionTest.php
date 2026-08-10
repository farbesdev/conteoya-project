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

class ActIngestionTest extends TestCase
{
    use RefreshDatabase;

    protected User $personeroUser;
    protected Personero $personero;
    protected PollingStation $pollingStation;
    protected Election $election;
    protected ElectoralLevel $level;
    protected PoliticalOrganization $orgA;
    protected PoliticalOrganization $orgB;

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
            'address'       => 'AV. ALFONSO UGARTE 1227',
        ]);

        $this->pollingStation = PollingStation::create([
            'electoral_location_id' => $location->id,
            'code'                  => '030390',
            'registered_voters'     => 300,
            'status'                => 'ACTIVE',
        ]);

        $this->election = Election::create([
            'code'   => 'ERM2026',
            'name'   => 'Elecciones Regionales y Municipales 2026',
            'date'   => '2026-10-04',
            'status' => 'ACTIVE',
        ]);

        $this->level = ElectoralLevel::create([
            'election_id'            => $this->election->id,
            'code'                   => 'MUNICIPAL_PROVINCIAL',
            'name'                   => 'Municipal Provincial',
            'has_preferential_vote'  => false,
        ]);

        $this->orgA = PoliticalOrganization::create([
            'name'       => 'PARTIDO DEMOCRATA',
            'short_name' => 'PD',
        ]);

        $this->orgB = PoliticalOrganization::create([
            'name'       => 'MOVIMIENTO REGIONAL FUTURO',
            'short_name' => 'MRF',
        ]);

        $this->personeroUser = User::create([
            'name'      => 'Juan Personero',
            'email'     => 'personero@conteoya.pe',
            'password'  => bcrypt('Secret123!'),
            'role'      => 'PERSONERO',
            'role_id'   => 3,
            'is_active' => true,
        ]);

        $this->personero = Personero::create([
            'user_id'         => $this->personeroUser->id,
            'document_number' => '44556677',
            'phone_number'    => '999888777',
        ]);

        // Asignar mesa al personero
        $this->personero->pollingStations()->attach($this->pollingStation->id);
    }

    public function test_personero_can_create_act_with_valid_totals(): void
    {
        Sanctum::actingAs($this->personeroUser);

        $clientOperationId = Str::uuid()->toString();

        $payload = [
            'client_operation_id'  => $clientOperationId,
            'polling_station_code' => '030390',
            'election_id'          => $this->election->id,
            'electoral_level_id'   => $this->level->id,
            'act_code'             => 'ACT-030390-MP',
            'status'               => 'DRAFT',
            'totals'               => [
                'registered_voters' => 300,
                'voters_who_voted'  => 280,
                'total_votes'       => 280,
                'blank_votes'       => 15,
                'null_votes'        => 10,
                'challenged_votes'  => 5,
            ],
            'results'              => [
                [
                    'political_organization_id' => $this->orgA->id,
                    'votes'                     => 150,
                    'source'                    => 'MANUAL',
                ],
                [
                    'political_organization_id' => $this->orgB->id,
                    'votes'                     => 100,
                    'source'                    => 'MANUAL',
                ],
            ],
        ];

        $response = $this->postJson('/api/v1/acts', $payload);

        $response->assertStatus(201)
            ->assertJsonPath('data.polling_station.code', '030390')
            ->assertJsonPath('data.totals.total_votes', 280)
            ->assertJsonPath('data.totals.is_valid_total', true)
            ->assertJsonPath('validation_result.is_valid_total', true)
            ->assertJsonCount(0, 'validation_result.warnings');

        $this->assertDatabaseHas('acts', [
            'polling_station_id' => $this->pollingStation->id,
            'election_id'        => $this->election->id,
            'status'             => 'DRAFT',
        ]);

        $this->assertDatabaseHas('act_totals', [
            'total_votes'    => 280,
            'is_valid_total' => true,
        ]);

        $this->assertDatabaseCount('act_results', 2);
    }

    public function test_act_creation_with_totals_mismatch_produces_warnings_without_blocking(): void
    {
        Sanctum::actingAs($this->personeroUser);

        $clientOperationId = Str::uuid()->toString();

        // Total declarado: 300, pero suma de votos da 150 + 100 + 10 + 10 = 270 (inconsistencia)
        $payload = [
            'client_operation_id'  => $clientOperationId,
            'polling_station_code' => '030390',
            'election_id'          => $this->election->id,
            'electoral_level_id'   => $this->level->id,
            'status'               => 'DRAFT',
            'totals'               => [
                'registered_voters' => 300,
                'voters_who_voted'  => 290,
                'total_votes'       => 300, // Discrepancia
                'blank_votes'       => 10,
                'null_votes'        => 10,
                'challenged_votes'  => 0,
            ],
            'results'              => [
                [
                    'political_organization_id' => $this->orgA->id,
                    'votes'                     => 150,
                    'source'                    => 'OCR',
                    'confidence'                => 0.95,
                ],
                [
                    'political_organization_id' => $this->orgB->id,
                    'votes'                     => 100,
                    'source'                    => 'AI',
                    'confidence'                => 0.82,
                ],
            ],
        ];

        $response = $this->postJson('/api/v1/acts', $payload);

        $response->assertStatus(201)
            ->assertJsonPath('data.totals.is_valid_total', false)
            ->assertJsonPath('validation_result.is_valid_total', false);

        $warnings = $response->json('validation_result.warnings');
        $this->assertNotEmpty($warnings);
        $this->assertEquals('TOTAL_MISMATCH', $warnings[0]['code']);
    }

    public function test_idempotency_prevents_duplicate_act_records_and_returns_cached_response(): void
    {
        Sanctum::actingAs($this->personeroUser);

        $clientOperationId = Str::uuid()->toString();

        $payload = [
            'client_operation_id'  => $clientOperationId,
            'polling_station_code' => '030390',
            'election_id'          => $this->election->id,
            'electoral_level_id'   => $this->level->id,
            'totals'               => [
                'registered_voters' => 300,
                'voters_who_voted'  => 200,
                'total_votes'       => 200,
                'blank_votes'       => 0,
                'null_votes'        => 0,
                'challenged_votes'  => 0,
            ],
            'results'              => [
                [
                    'political_organization_id' => $this->orgA->id,
                    'votes'                     => 200,
                    'source'                    => 'MANUAL',
                ],
            ],
        ];

        // Primer envío
        $response1 = $this->withHeader('Idempotency-Key', $clientOperationId)
            ->postJson('/api/v1/acts', $payload);
        $response1->assertStatus(201);

        $actId = $response1->json('data.id');

        // Segundo envío idéntico con la misma Idempotency-Key
        $response2 = $this->withHeader('Idempotency-Key', $clientOperationId)
            ->postJson('/api/v1/acts', $payload);

        $response2->assertStatus(201)
            ->assertHeader('X-Idempotent-Replayed', 'true')
            ->assertJsonPath('data.id', $actId);

        // Verificar que solo existe exactamente 1 acta en la base de datos
        $this->assertDatabaseCount('acts', 1);
    }

    public function test_personero_can_confirm_draft_act(): void
    {
        Sanctum::actingAs($this->personeroUser);

        // Crear acta en DRAFT
        $payload = [
            'polling_station_code' => '030390',
            'election_id'          => $this->election->id,
            'electoral_level_id'   => $this->level->id,
            'status'               => 'DRAFT',
            'totals'               => [
                'registered_voters' => 300,
                'voters_who_voted'  => 200,
                'total_votes'       => 200,
            ],
            'results'              => [
                [
                    'political_organization_id' => $this->orgA->id,
                    'votes'                     => 200,
                    'source'                    => 'MANUAL',
                ],
            ],
        ];

        $createRes = $this->postJson('/api/v1/acts', $payload);
        $actId = $createRes->json('data.id');

        // Confirmar acta
        $confirmRes = $this->postJson("/api/v1/acts/{$actId}/confirm");

        $confirmRes->assertStatus(200)
            ->assertJsonPath('data.status', 'CONFIRMED');

        $this->assertDatabaseHas('acts', [
            'id'     => $actId,
            'status' => 'CONFIRMED',
        ]);
    }
}
