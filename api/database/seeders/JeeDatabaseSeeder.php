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
            'REGIONAL' => $levelRegionalGov->id,
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
                $filename = $row['id'] . '.webp';
                $disk     = Storage::disk('political_organizationals');

                if ($disk->exists($filename)) {
                    // Archivo ya descargado previamente — reutilizar sin volver a descargar
                    $localLogoUrl = $filename;
                } else {
                    try {
                        $rawContent = @file_get_contents($row['logo_url']);
                        if ($rawContent !== false && $rawContent !== '') {
                            $image = @imagecreatefromstring($rawContent);
                            if ($image !== false) {
                                ob_start();
                                imagewebp($image, null, 85);
                                $webpData = ob_get_clean();
                                imagedestroy($image);

                                $disk->put($filename, $webpData);
                                $localLogoUrl = $filename;
                            }
                        }
                    } catch (\Throwable $e) {
                        $this->command->warn("Error logo org " . $row['id'] . ": " . $e->getMessage());
                    }
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
        $this->command->info("Cargando Listas Electorales y clasificando por nivel (Gobernador / Consejero / Municipal)...");
        
        // Mapear qué listas tienen candidatos a Gobernador/Vicegobernador para asignar nivel exacto
        $govListsStmt = $sqlite->query("SELECT DISTINCT id_solicitud_lista FROM candidates WHERE position IN ('GOBERNADOR REGIONAL', 'VICEGOBERNADOR REGIONAL')");
        $govListsSet = array_flip($govListsStmt->fetchAll(\PDO::FETCH_COLUMN));

        $stmt = $sqlite->query("SELECT id_solicitud_lista, organization_id, election_type, department_code, province_code, district_code, status FROM electoral_lists");
        $electoralListsRows = [];

        while ($row = $stmt->fetch(\PDO::FETCH_ASSOC)) {
            $orgId = $orgMap[$row['organization_id']] ?? null;
            $type = strtoupper(trim($row['election_type'] ?? ''));

            if ($type === 'REGIONAL' || $type === 'GOBERNADOR REGIONAL') {
                // Si la lista regional no presenta fórmula ejecutiva (solo consejeros), asignar a Consejero Regional
                $levelId = isset($govListsSet[$row['id_solicitud_lista']]) 
                    ? $levelRegionalGov->id 
                    : $levelRegionalCons->id;
            } else {
                $levelId = $levelsMap[$type] ?? $levelDistrital->id;
            }

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
        $this->command->info("Cargando Candidatos y Candidacias de todas las listas...");
        $stmt = $sqlite->query("SELECT id, id_solicitud_lista, id_hoja_vida, full_name, position, status, list_number, photo_url FROM candidates");
        
        $candidatesRows = [];
        $candidaciesRaw = [];
        $chunkLimit = 2000;
        $totalProcessed = 0;

        $diskCandidates = Storage::disk('candidates');
        $candidatesStoragePath = storage_path('app/public/candidates');

        while ($row = $stmt->fetch(\PDO::FETCH_ASSOC)) {
            $docNumber = $row['id_hoja_vida'] ?: ('JEE_' . $row['id']);
            $expectedFilename = "$docNumber/foto.webp";

            // Si el archivo ya existe físicamente en el storage local, asignarlo directamente
            $localPhotoUrl = null;
            if (file_exists($candidatesStoragePath . '/' . $expectedFilename) || file_exists($candidatesStoragePath . "/$docNumber/foto.png") || file_exists($candidatesStoragePath . "/$docNumber/foto.jpg")) {
                $localPhotoUrl = $expectedFilename;
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

            if (count($candidatesRows) >= $chunkLimit) {
                $this->batchInsertOrUpdate(
                    'candidates',
                    ['jee_candidate_id', 'id_hoja_vida', 'document_number', 'full_name', 'photo_url', 'local_photo_url', 'created_at', 'updated_at'],
                    $candidatesRows,
                    ['matchColumns' => ['jee_candidate_id'], 'updateColumns' => ['id_hoja_vida', 'document_number', 'full_name', 'photo_url', 'local_photo_url', 'updated_at'], 'verbose' => false]
                );
                $totalProcessed += count($candidatesRows);
                $this->command->info("  [candidates] procesados: {$totalProcessed}...");
                $candidatesRows = [];
            }
        }

        if (!empty($candidatesRows)) {
            $this->batchInsertOrUpdate(
                'candidates',
                ['jee_candidate_id', 'id_hoja_vida', 'document_number', 'full_name', 'photo_url', 'local_photo_url', 'created_at', 'updated_at'],
                $candidatesRows,
                ['matchColumns' => ['jee_candidate_id'], 'updateColumns' => ['id_hoja_vida', 'document_number', 'full_name', 'photo_url', 'local_photo_url', 'updated_at'], 'verbose' => false]
            );
            $totalProcessed += count($candidatesRows);
            $this->command->info("  [candidates] total final: {$totalProcessed} candidatos insertados.");
        }

        // 8. CANDIDACIAS
        $this->command->info("Vinculando Candidacias (candidacies)...");
        $candidateMap = DB::table('candidates')->pluck('id', 'jee_candidate_id')->toArray();

        $candidaciesRows = [];
        $totalCandidacies = 0;
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

                if (count($candidaciesRows) >= $chunkLimit) {
                    $this->batchInsertOrUpdate(
                        'candidacies',
                        ['electoral_list_id', 'candidate_id', 'position', 'list_number', 'status', 'created_at', 'updated_at'],
                        $candidaciesRows,
                        ['matchColumns' => ['electoral_list_id', 'candidate_id'], 'updateColumns' => ['position', 'list_number', 'status', 'updated_at'], 'verbose' => false]
                    );
                    $totalCandidacies += count($candidaciesRows);
                    $this->command->info("  [candidacies] procesadas: {$totalCandidacies}...");
                    $candidaciesRows = [];
                }
            }
        }

        if (!empty($candidaciesRows)) {
            $this->batchInsertOrUpdate(
                'candidacies',
                ['electoral_list_id', 'candidate_id', 'position', 'list_number', 'status', 'created_at', 'updated_at'],
                $candidaciesRows,
                ['matchColumns' => ['electoral_list_id', 'candidate_id'], 'updateColumns' => ['position', 'list_number', 'status', 'updated_at'], 'verbose' => false]
            );
            $totalCandidacies += count($candidaciesRows);
            $this->command->info("  [candidacies] total final: {$totalCandidacies} candidacias vinculadas.");
        }

        // 9. HOJAS DE VIDA DE CANDIDATOS (candidate_cvs)
        $this->command->info("Cargando Hojas de Vida de Candidatos (candidate_cvs)...");
        $cvRows = [];
        $csvPath = base_path('../database/files/candidate_cvs.csv');

        // Mapear por documento (DNI) e id_hoja_vida a candidate.id
        $candDocMap = DB::table('candidates')->whereNotNull('document_number')->pluck('id', 'document_number')->toArray();

        // Prioridad 1: Cargar desde CSV sincronizado previamente (en database/files/candidate_cvs.csv)
        if (file_exists($csvPath) && ($handle = @fopen($csvPath, 'r')) !== false) {
            $this->command->info("→ Encontrado archivo CSV sincronizado ($csvPath). Cargando...");
            $header = fgetcsv($handle); // descartar cabeceras
            while (($data = fgetcsv($handle)) !== false) {
                if (!empty($data[0])) {
                    $idHojaVida = (string) $data[0];
                    $rawCandId  = $data[1] ?? null;
                    // Mapear al ID real de candidate
                    $candId = $candidateMap[$rawCandId] ?? ($candDocMap[$idHojaVida] ?? null);

                    if ($candId) {
                        $cvRows[] = [
                            'id_hoja_vida'         => $idHojaVida,
                            'candidate_id'         => $candId,
                            'general_data'         => !empty($data[2]) ? $data[2] : null,
                            'academic_data'        => !empty($data[3]) ? $data[3] : null,
                            'work_experience'      => !empty($data[4]) ? $data[4] : null,
                            'political_trajectory' => !empty($data[5]) ? $data[5] : null,
                            'sworn_declaration'    => !empty($data[6]) ? $data[6] : null,
                            'penal_sentences'      => !empty($data[7]) ? $data[7] : null,
                            'additional_info'      => !empty($data[8]) ? $data[8] : null,
                            'created_at'           => $now,
                            'updated_at'           => $now,
                        ];
                    }
                }
            }
            fclose($handle);
        }

        if (!empty($cvRows)) {
            foreach (array_chunk($cvRows, 1000) as $cvChunk) {
                $this->batchInsertOrUpdate(
                    'candidate_cvs',
                    ['id_hoja_vida', 'candidate_id', 'general_data', 'academic_data', 'work_experience', 'political_trajectory', 'sworn_declaration', 'penal_sentences', 'additional_info', 'created_at', 'updated_at'],
                    $cvChunk,
                    ['matchColumns' => ['id_hoja_vida'], 'updateColumns' => ['candidate_id', 'general_data', 'academic_data', 'work_experience', 'political_trajectory', 'sworn_declaration', 'penal_sentences', 'additional_info', 'updated_at'], 'verbose' => false]
                );
            }
            $this->command->info("  [candidate_cvs] " . count($cvRows) . " hojas de vida cargadas.");
        }

        // 9. USUARIO DEMO & MESA DEMO
        $this->command->info("Creando Usuario Personero Demo y Mesa...");
        $userId = $this->firstOrInsertGetId('users', [
            'name' => 'Personero Demo ERM',
            'email' => 'personero@conteoya.pe',
            'password' => bcrypt('77889900!'),
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

        $firstDistrictCode = DB::table('districts')->where('code', '150101')->value('code') 
            ?? DB::table('districts')->value('code') 
            ?? '150101';

        $locationId = $this->firstOrInsertGetId('electoral_locations', [
            'district_code' => $firstDistrictCode,
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
