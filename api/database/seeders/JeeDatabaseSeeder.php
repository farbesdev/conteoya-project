<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use App\Traits\MigrationSeedingMethod;
use App\Models\ElectoralLevel;
use App\Models\Election;

class JeeDatabaseSeeder extends Seeder
{
    use MigrationSeedingMethod;

    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $sqlitePath = base_path('../database/erm2026.db');
        if (!file_exists($sqlitePath)) {
            $this->command->error("Base de datos SQLite $sqlitePath no encontrada.");
            return;
        }

        $sqlite = new \PDO("sqlite:" . $sqlitePath);
        $sqlite->setAttribute(\PDO::ATTR_ERRMODE, \PDO::ERRMODE_EXCEPTION);
        $now = now()->toDateTimeString();

        // 1. DEPARTAMENTOS
        $this->command->info("Cargando Departamentos...");
        $stmt = $sqlite->query("SELECT code, name FROM departments");
        $departments = [];
        while ($row = $stmt->fetch(\PDO::FETCH_ASSOC)) {
            $departments[] = [
                'code' => $row['code'],
                'name' => $row['name'],
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }
        $this->insertOnConflictDoNothing('departments', ['code', 'name', 'created_at', 'updated_at'], $departments, ['conflictColumns' => ['code']]);

        // 2. PROVINCIAS
        $this->command->info("Cargando Provincias...");
        $stmt = $sqlite->query("SELECT code, name, department_code FROM provinces");
        $provinces = [];
        while ($row = $stmt->fetch(\PDO::FETCH_ASSOC)) {
            $provinces[] = [
                'code' => $row['code'],
                'department_code' => $row['department_code'],
                'name' => $row['name'],
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }
        $this->insertOnConflictDoNothing('provinces', ['code', 'department_code', 'name', 'created_at', 'updated_at'], $provinces, ['conflictColumns' => ['code']]);

        // 3. DISTRITOS
        $this->command->info("Cargando Distritos...");
        $stmt = $sqlite->query("SELECT code, name, department_code, province_code FROM districts");
        $districts = [];
        while ($row = $stmt->fetch(\PDO::FETCH_ASSOC)) {
            $districts[] = [
                'code' => $row['code'],
                'province_code' => $row['province_code'],
                'department_code' => $row['department_code'],
                'name' => $row['name'],
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }
        $this->insertOnConflictDoNothing('districts', ['code', 'province_code', 'department_code', 'name', 'created_at', 'updated_at'], $districts, ['conflictColumns' => ['code']]);

        // 4. ELECCIÓN & NIVELES ELECTORALES
        $electionId = $this->firstOrInsertGetId('elections', [
            'code' => 'ERM2026',
            'name' => 'Elecciones Regionales y Municipales 2026',
            'date' => '2026-10-04',
            'status' => 'ACTIVE',
            'created_at' => $now,
            'updated_at' => $now,
        ], ['matchColumns' => ['code']]);

        $levelRegionalGov = ElectoralLevel::updateOrCreate(
            ['election_id' => $electionId, 'code' => 'REGIONAL_GOBERNADOR'],
            ['name' => 'Gobernador y Vicegobernador Regional', 'has_preferential_vote' => false]
        );
        $levelRegionalCons = ElectoralLevel::updateOrCreate(
            ['election_id' => $electionId, 'code' => 'REGIONAL_CONSEJERO'],
            ['name' => 'Consejero Regional', 'has_preferential_vote' => false]
        );
        $levelProvincial = ElectoralLevel::updateOrCreate(
            ['election_id' => $electionId, 'code' => 'MUNICIPAL_PROVINCIAL'],
            ['name' => 'Alcalde y Regidores Provinciales', 'has_preferential_vote' => false]
        );
        $levelDistrital = ElectoralLevel::updateOrCreate(
            ['election_id' => $electionId, 'code' => 'MUNICIPAL_DISTRITAL'],
            ['name' => 'Alcalde y Regidores Distritales', 'has_preferential_vote' => false]
        );

        $levelsMap = [
            'GOBERNADOR REGIONAL' => $levelRegionalGov->id,
            'CONSEJERO REGIONAL' => $levelRegionalCons->id,
            'MUNICIPAL PROVINCIAL' => $levelProvincial->id,
            'MUNICIPAL DISTRITAL' => $levelDistrital->id,
        ];

        // 5. ORGANIZACIONES POLÍTICAS & DESCARGA DE LOGOS
        $this->command->info("Cargando Organizaciones Políticas y descargando logos...");
        $stmt = $sqlite->query("SELECT id, name, short_name, org_type, logo_url FROM political_organizations");
        $politicalOrgsRows = [];

        while ($row = $stmt->fetch(\PDO::FETCH_ASSOC)) {
            $localLogoUrl = null;

            if (!empty($row['logo_url'])) {
                try {
                    $rawContent = @file_get_contents($row['logo_url']);
                    if ($rawContent) {
                        $image = @imagecreatefromstring($rawContent);
                        if ($image !== false) {
                            ob_start();
                            imagewebp($image, null, 85);
                            $webpData = ob_get_clean();
                            imagedestroy($image);

                            $filename = $row['id'] . '.webp';
                            Storage::disk('political_organizationals')->put($filename, $webpData);
                            // Guardar ruta relativa local
                            $localLogoUrl = $filename;
                        }
                    }
                } catch (\Throwable $e) {
                    $this->command->warn("Error logo org " . $row['id'] . ": " . $e->getMessage());
                }
            }

            $politicalOrgsRows[] = [
                'jee_id' => $row['id'],
                'name' => $row['name'],
                'short_name' => $row['short_name'],
                'org_type' => $row['org_type'],
                'logo_url' => $row['logo_url'],
                'local_logo_url' => $localLogoUrl,
                'created_at' => $now,
                'updated_at' => $now,
            ];
        }

        $this->batchInsertOrUpdate(
            'political_organizations',
            ['jee_id', 'name', 'short_name', 'org_type', 'logo_url', 'local_logo_url', 'created_at', 'updated_at'],
            $politicalOrgsRows,
            ['matchColumns' => ['jee_id'], 'updateColumns' => ['name', 'short_name', 'org_type', 'logo_url', 'local_logo_url', 'updated_at']]
        );

        // Mapear jee_id -> id relacional en PostgreSQL
        $orgMap = DB::table('political_organizations')->pluck('id', 'jee_id')->toArray();

        // 6. LISTAS ELECTORALES
        $this->command->info("Cargando Listas Electorales...");
        $stmt = $sqlite->query("SELECT id_solicitud_lista, organization_id, election_type, department_code, province_code, district_code, status FROM electoral_lists LIMIT 500");
        $electoralListsRows = [];

        while ($row = $stmt->fetch(\PDO::FETCH_ASSOC)) {
            $orgId = $orgMap[$row['organization_id']] ?? null;
            $levelId = $levelsMap[$row['election_type']] ?? $levelDistrital->id;

            if ($orgId) {
                $electoralListsRows[] = [
                    'jee_solicitud_id' => $row['id_solicitud_lista'],
                    'political_organization_id' => $orgId,
                    'electoral_level_id' => $levelId,
                    'department_code' => $row['department_code'],
                    'province_code' => $row['province_code'],
                    'district_code' => $row['district_code'],
                    'status' => $row['status'] ?: 'INSCRITO',
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
        }

        $this->batchInsertOrUpdate(
            'electoral_lists',
            ['jee_solicitud_id', 'political_organization_id', 'electoral_level_id', 'department_code', 'province_code', 'district_code', 'status', 'created_at', 'updated_at'],
            $electoralListsRows,
            ['matchColumns' => ['jee_solicitud_id'], 'updateColumns' => ['political_organization_id', 'electoral_level_id', 'department_code', 'province_code', 'district_code', 'status', 'updated_at']]
        );

        $listsMap = DB::table('electoral_lists')->pluck('id', 'jee_solicitud_id')->toArray();

        // 7. CANDIDATOS & FOTOGRAFÍAS
        $this->command->info("Cargando Candidatos y descargando fotografías...");
        $stmt = $sqlite->query("SELECT id, id_solicitud_lista, id_hoja_vida, full_name, position, status, list_number, photo_url FROM candidates LIMIT 500");
        
        $candidatesRows = [];
        $candidaciesRaw = [];

        while ($row = $stmt->fetch(\PDO::FETCH_ASSOC)) {
            $localPhotoUrl = null;
            $docNumber = $row['id_hoja_vida'] ?: ('JEE_' . $row['id']);

            if (!empty($row['photo_url'])) {
                try {
                    $rawContent = @file_get_contents($row['photo_url']);
                    if ($rawContent) {
                        $image = @imagecreatefromstring($rawContent);
                        if ($image !== false) {
                            ob_start();
                            imagewebp($image, null, 85);
                            $webpData = ob_get_clean();
                            imagedestroy($image);

                            $filename = "$docNumber/foto.webp";
                            Storage::disk('candidates')->put($filename, $webpData);
                            // Guardar ruta relativa local
                            $localPhotoUrl = $filename;
                        }
                    }
                } catch (\Throwable $e) {
                    $this->command->warn("Error foto candidato " . $row['id'] . ": " . $e->getMessage());
                }
            }

            $candidatesRows[] = [
                'jee_candidate_id' => $row['id'],
                'id_hoja_vida' => $row['id_hoja_vida'],
                'document_number' => $docNumber,
                'full_name' => $row['full_name'],
                'photo_url' => $row['photo_url'],
                'local_photo_url' => $localPhotoUrl,
                'created_at' => $now,
                'updated_at' => $now,
            ];

            if (isset($listsMap[$row['id_solicitud_lista']])) {
                $candidaciesRaw[] = [
                    'jee_candidate_id' => $row['id'],
                    'electoral_list_id' => $listsMap[$row['id_solicitud_lista']],
                    'position' => $row['position'] ?: 'CANDIDATO',
                    'list_number' => $row['list_number'] ?: 0,
                    'status' => $row['status'] ?: 'INSCRITO',
                ];
            }
        }

        $this->batchInsertOrUpdate(
            'candidates',
            ['jee_candidate_id', 'id_hoja_vida', 'document_number', 'full_name', 'photo_url', 'local_photo_url', 'created_at', 'updated_at'],
            $candidatesRows,
            ['matchColumns' => ['jee_candidate_id'], 'updateColumns' => ['id_hoja_vida', 'document_number', 'full_name', 'photo_url', 'local_photo_url', 'updated_at']]
        );

        $candidateMap = DB::table('candidates')->pluck('id', 'jee_candidate_id')->toArray();

        // 8. CANDIDACIAS
        $candidaciesRows = [];
        foreach ($candidaciesRaw as $cRaw) {
            $candId = $candidateMap[$cRaw['jee_candidate_id']] ?? null;
            if ($candId) {
                $candidaciesRows[] = [
                    'electoral_list_id' => $cRaw['electoral_list_id'],
                    'candidate_id' => $candId,
                    'position' => $cRaw['position'],
                    'list_number' => $cRaw['list_number'],
                    'status' => $cRaw['status'],
                    'created_at' => $now,
                    'updated_at' => $now,
                ];
            }
        }

        $this->batchInsertOrUpdate(
            'candidacies',
            ['electoral_list_id', 'candidate_id', 'position', 'list_number', 'status', 'created_at', 'updated_at'],
            $candidaciesRows,
            ['matchColumns' => ['electoral_list_id', 'candidate_id'], 'updateColumns' => ['position', 'list_number', 'status', 'updated_at']]
        );

        // 9. USUARIO DEMO & MESA DEMO
        $this->command->info("Creando Usuario Personero Demo y Mesa...");
        $userId = $this->firstOrInsertGetId('users', [
            'name' => 'Personero Demo ERM',
            'email' => 'personero@conteoya.pe',
            'password' => bcrypt('password123'),
            'role' => 'PERSONERO',
            'is_active' => true,
            'created_at' => $now,
            'updated_at' => $now,
        ], ['matchColumns' => ['email']]);

        $personeroId = $this->firstOrInsertGetId('personeros', [
            'user_id' => $userId,
            'document_number' => '77889900',
            'phone_number' => '987654321',
            'created_at' => $now,
            'updated_at' => $now,
        ], ['matchColumns' => ['user_id']]);

        $locationId = $this->firstOrInsertGetId('electoral_locations', [
            'district_code' => '000001',
            'name' => 'IE 1001 SAN MARTIN',
            'address' => 'Av. Principal 123',
            'created_at' => $now,
            'updated_at' => $now,
        ], ['matchColumns' => ['district_code', 'name']]);

        $stationId = $this->firstOrInsertGetId('polling_stations', [
            'electoral_location_id' => $locationId,
            'code' => '030390',
            'registered_voters' => 300,
            'status' => 'ACTIVE',
            'created_at' => $now,
            'updated_at' => $now,
        ], ['matchColumns' => ['code']]);

        $this->insertOnConflictDoNothing('personero_polling_station', [
            'personero_id', 'polling_station_id', 'assigned_at'
        ], [
            ['personero_id' => $personeroId, 'polling_station_id' => $stationId, 'assigned_at' => $now]
        ], ['conflictColumns' => ['personero_id', 'polling_station_id']]);

        $this->command->info("Seeder JEE completado exitosamente utilizando MigrationSeedingMethod trait.");
    }
}
