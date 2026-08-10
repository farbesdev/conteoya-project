<?php

namespace Tests\Feature;

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

class OcrRecognitionTest extends TestCase
{
    use RefreshDatabase;

    protected User $user;
    protected Personero $personero;
    protected PollingStation $station;

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

        $this->user = User::create([
            'name'      => 'Carmen OCR',
            'email'     => 'carmen@conteoya.pe',
            'password'  => bcrypt('Secret123!'),
            'role'      => 'PERSONERO',
            'role_id'   => 3,
            'is_active' => true,
        ]);

        $this->personero = Personero::create([
            'user_id'         => $this->user->id,
            'document_number' => '77665544',
        ]);

        $this->personero->pollingStations()->attach($this->station->id);
    }

    public function test_ocr_recognition_returns_structured_results_with_confidence_mapping(): void
    {
        Sanctum::actingAs($this->user);

        $payload = [
            'polling_station_code' => '030390',
        ];

        $response = $this->postJson('/api/v1/acts/recognize', $payload);

        $response->assertStatus(200)
            ->assertJsonPath('data.polling_station_code', '030390')
            ->assertJsonStructure([
                'message',
                'data' => [
                    'provider_name',
                    'polling_station_code',
                    'registered_voters',
                    'voters_who_voted',
                    'total_votes',
                    'blank_votes',
                    'null_votes',
                    'challenged_votes',
                    'results',
                    'confidence_map',
                    'has_low_confidence',
                ],
            ]);
    }
}
