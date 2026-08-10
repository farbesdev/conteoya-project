<?php

namespace Tests\Feature;

use App\Models\Act;
use App\Models\Department;
use App\Models\District;
use App\Models\Election;
use App\Models\ElectoralLevel;
use App\Models\ElectoralLocation;
use App\Models\Personero;
use App\Models\PollingStation;
use App\Models\Province;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class EvidenceUploadTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Personero $personero;
    protected PollingStation $station;
    protected Act $act;

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

        $election = Election::create([
            'code'   => 'ERM2026',
            'name'   => 'Elecciones 2026',
            'date'   => '2026-10-04',
        ]);

        $level = ElectoralLevel::create([
            'election_id'           => $election->id,
            'code'                  => 'MUNICIPAL_DISTRITAL',
            'name'                  => 'Municipal Distrital',
            'has_preferential_vote' => false,
        ]);

        $this->user = User::create([
            'name'      => 'Maria Personera',
            'email'     => 'maria@conteoya.pe',
            'password'  => bcrypt('Secret123!'),
            'role'      => 'PERSONERO',
            'role_id'   => 3,
            'is_active' => true,
        ]);

        $this->personero = Personero::create([
            'user_id'         => $this->user->id,
            'document_number' => '55667788',
        ]);

        $this->personero->pollingStations()->attach($this->station->id);

        $this->act = Act::create([
            'election_id'              => $election->id,
            'electoral_level_id'       => $level->id,
            'polling_station_id'       => $this->station->id,
            'status'                   => 'DRAFT',
            'captured_by_personero_id' => $this->personero->id,
        ]);
    }

    public function test_personero_can_request_presigned_upload_url(): void
    {
        Sanctum::actingAs($this->user);

        $sha256 = hash('sha256', 'mock_image_binary_content_2026');

        $payload = [
            'sha256_hash'     => $sha256,
            'file_mime'       => 'image/jpeg',
            'file_size_bytes' => 1024 * 500, // 500 KB
        ];

        $response = $this->postJson("/api/v1/acts/{$this->act->id}/evidence/upload-url", $payload);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'message',
                'data' => [
                    'upload_url',
                    'object_key',
                    'storage_provider',
                    'expires_in_sec',
                ],
            ]);

        $this->assertStringContainsString($sha256, $response->json('data.object_key'));
    }

    public function test_personero_can_confirm_uploaded_evidence(): void
    {
        Sanctum::actingAs($this->user);

        $sha256 = hash('sha256', 'mock_evidence_test_data');
        $objectKey = "evidence/election_1/station_030390/act_{$this->act->id}/{$sha256}.jpg";

        $payload = [
            'object_key'      => $objectKey,
            'sha256_hash'     => $sha256,
            'file_mime'       => 'image/jpeg',
            'file_size_bytes' => 204800,
            'width_px'        => 1920,
            'height_px'       => 1080,
        ];

        $response = $this->postJson("/api/v1/acts/{$this->act->id}/evidence/confirm", $payload);

        $response->assertStatus(201)
            ->assertJsonPath('data.act_id', $this->act->id)
            ->assertJsonPath('data.sha256_hash', $sha256)
            ->assertJsonPath('data.storage_provider', 'R2');

        $this->assertDatabaseHas('act_evidence', [
            'act_id'      => $this->act->id,
            'sha256_hash' => $sha256,
        ]);
    }
}
