<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use App\Models\Election;
use App\Models\PoliticalOrganization;
use App\Models\Role;
use App\Support\CSVProcessor;
use App\Traits\MigrationSeedingMethod;

class PersonerosSeeder extends Seeder
{
    use MigrationSeedingMethod;

    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $csvPath = base_path('../files/personeros_todos_jee_erm2026.csv');
        if (!file_exists($csvPath)) {
            $csvPath = base_path('files/personeros_todos_jee_erm2026.csv');
        }

        if (!file_exists($csvPath)) {
            $this->command?->error("Archivo CSV no encontrado en: $csvPath");
            return;
        }

        $this->command?->info("Cargando Personeros desde $csvPath...");

        $rows = CSVProcessor::file($csvPath)->getRowsAsLazyCollection();
        if ($rows->isEmpty()) {
            $this->command?->error("El archivo CSV no contiene registros.");
            return;
        }

        // 1. Elección ERM 2026 y proceso JNE
        $election = Election::firstOrCreate(
            ['code' => 'ERM2026'],
            [
                'name'                     => 'Elecciones Regionales y Municipales 2026',
                'date'                     => '2026-10-04',
                'status'                   => 'ACTIVE',
                'jee_proceso_electoral_id' => 126,
            ]
        );
        if ($election->jee_proceso_electoral_id !== 126) {
            $election->update(['jee_proceso_electoral_id' => 126]);
        }

        // 2. Mapeo de Organizaciones Políticas en memoria
        $orgMap = PoliticalOrganization::all()->mapWithKeys(function ($org) {
            return [mb_strtoupper(trim($org->name), 'UTF-8') => $org->id];
        });

        // 3. Rol Personero
        $personeroRole = Role::firstOrCreate(
            ['name' => Role::PERSONERO],
            ['display_name' => 'Personero']
        );

        // 4. Agrupar registros por DNI (priorizando estado RECONOCIDO si hay duplicados)
        $this->command?->info("Consolidando registros de personeros por DNI...");
        $personerosByDni = [];

        foreach ($rows as $row) {
            $dni = trim((string)($row['strdocumentoidentidad'] ?? $row['strDocumentoIdentidad'] ?? ''));
            if (empty($dni)) {
                continue;
            }

            $currentStatus = strtoupper(trim((string)($row['strestado'] ?? $row['strEstado'] ?? '')));

            if (!isset($personerosByDni[$dni])) {
                $personerosByDni[$dni] = $row;
            } else {
                $prevStatus = strtoupper(trim((string)($personerosByDni[$dni]['strestado'] ?? $personerosByDni[$dni]['strEstado'] ?? '')));
                // Si el nuevo registro es RECONOCIDO y el anterior no lo era, se prioriza el reconocido
                if ($currentStatus === 'RECONOCIDO' && $prevStatus !== 'RECONOCIDO') {
                    $personerosByDni[$dni] = $row;
                }
            }
        }

        $totalUnique = count($personerosByDni);
        $this->command?->info("Total de personeros únicos a procesar: $totalUnique");

        $now = now()->toDateTimeString();
        $defaultHashedPassword = Hash::make('password123');
        $userColumns = [
            'name',
            'email',
            'password',
            'role',
            'role_id',
            'is_active',
            'created_at',
            'updated_at',
        ];

        $personeroColumns = [
            'user_id',
            'election_id',
            'political_organization_id',
            'document_number',
            'full_name',
            'first_name',
            'email',
            'personero_type',
            'id_tipo_personero',
            'phone_number',
            'status',
            'expediente_ext',
            'codigo_declara',
            'jee_personero_declara_id',
            'political_organization_name',
            'jee_name',
            'jee_id',
            'department_name',
            'province_name',
            'district_name',
            'abogado_responsable',
            'created_at',
            'updated_at',
        ];

        $usedEmails = [];
        $chunks = array_chunk($personerosByDni, 1000, true);
        $processed = 0;
        $activeCount = 0;
        $inactiveCount = 0;

        foreach ($chunks as $chunkIndex => $chunk) {
            $parsedPersoneros = [];
            $userBatch = [];

            foreach ($chunk as $dni => $row) {
                $fullName = trim((string)($row['strnombrecompleto'] ?? $row['strNombreCompleto'] ?? ''));
                $firstName = trim((string)($row['strnombres'] ?? $row['strNombres'] ?? ''));
                if (empty($firstName) && !empty($fullName)) {
                    $parts = explode(' ', $fullName);
                    $firstName = $parts[0];
                }

                // Normalizar celular
                $rawPhone = trim((string)($row['strcelularprincipal'] ?? $row['strCelularPrincipal'] ?? ''));
                $phone = preg_replace('/\.0+$/', '', $rawPhone);
                $phone = !empty($phone) ? preg_replace('/[^0-9+]/', '', $phone) : null;
                if ($phone && strlen($phone) === 9 && strpos($phone, '+') !== 0) {
                    $phone = '+51 ' . $phone;
                }

                // Normalizar email garantizando unicidad
                $rawEmail = strtolower(trim((string)($row['strcorreoprincipal'] ?? $row['strCorreoPrincipal'] ?? '')));
                $email = (!empty($rawEmail) && filter_var($rawEmail, FILTER_VALIDATE_EMAIL))
                    ? $rawEmail
                    : "personero_{$dni}@conteoya.pe";

                if (isset($usedEmails[$email])) {
                    $email = "personero_{$dni}@conteoya.pe";
                }
                $usedEmails[$email] = true;

                $status = strtoupper(trim((string)($row['strestado'] ?? $row['strEstado'] ?? 'RECONOCIDO')));
                $isRecognized = ($status === 'RECONOCIDO');

                if ($isRecognized) {
                    $activeCount++;
                } else {
                    $inactiveCount++;
                }

                // Organización política
                $orgName = trim((string)($row['strorganizacionpolitica'] ?? $row['strOrganizacionPolitica'] ?? ''));
                $orgId = $orgMap->get(mb_strtoupper($orgName, 'UTF-8'));

                // Expediente y JEE
                $expedienteExt = !empty($row['strcodexpedienteext'] ?? $row['strCodExpedienteExt'] ?? null)
                    ? trim((string)($row['strcodexpedienteext'] ?? $row['strCodExpedienteExt']))
                    : null;
                $codigoDeclara = !empty($row['strcodigodeclara'] ?? $row['strCodigoDeclara'] ?? null)
                    ? trim((string)($row['strcodigodeclara'] ?? $row['strCodigoDeclara']))
                    : null;
                $idPersoneroDeclara = !empty($row['idpersonerodeclara'] ?? $row['idPersoneroDeclara'] ?? null)
                    ? (int)($row['idpersonerodeclara'] ?? $row['idPersoneroDeclara'])
                    : null;
                $cargo = !empty($row['strcargoeleccion'] ?? $row['strCargoEleccion'] ?? null)
                    ? trim((string)($row['strcargoeleccion'] ?? $row['strCargoEleccion']))
                    : null;
                $rawTipo = $row['idtipopersonero'] ?? $row['idTipoPersonero'] ?? null;
                $idTipoPersonero = ($rawTipo !== null && $rawTipo !== '') ? (int)$rawTipo : null;

                $jeeName = !empty($row['strjuradoelectoral'] ?? $row['strJuradoElectoral'] ?? null)
                    ? trim((string)($row['strjuradoelectoral'] ?? $row['strJuradoElectoral']))
                    : (!empty($row['_jeeconsultado'] ?? $row['_jeeConsultado'] ?? null) ? trim((string)($row['_jeeconsultado'] ?? $row['_jeeConsultado'])) : null);
                $rawJeeId = $row['_idjuradoconsultado'] ?? $row['_idJuradoConsultado'] ?? null;
                $jeeId = ($rawJeeId !== null && $rawJeeId !== '') ? (int)$rawJeeId : null;

                $deptName = !empty($row['strdepartamento'] ?? $row['strDepartamento'] ?? null)
                    ? trim((string)($row['strdepartamento'] ?? $row['strDepartamento']))
                    : null;
                $provName = !empty($row['strprovincia'] ?? $row['strProvincia'] ?? null)
                    ? trim((string)($row['strprovincia'] ?? $row['strProvincia']))
                    : null;
                $distName = !empty($row['strdistrito'] ?? $row['strDistrito'] ?? null)
                    ? trim((string)($row['strdistrito'] ?? $row['strDistrito']))
                    : null;
                $abogado = !empty($row['strabogadoresponsable'] ?? $row['strAbogadoResponsable'] ?? null)
                    ? trim((string)($row['strabogadoresponsable'] ?? $row['strAbogadoResponsable']))
                    : null;

                // Preparar User para inserción en lote
                $userBatch[] = [
                    'name'       => $fullName ?: "Personero DNI $dni",
                    'email'      => $email,
                    'password'   => Hash::make("{$dni}!"),
                    'role'       => Role::PERSONERO,
                    'role_id'    => $personeroRole->id,
                    'is_active'  => false,
                    'created_at' => $now,
                    'updated_at' => $now,
                ];

                $parsedPersoneros[] = [
                    'dni'                         => $dni,
                    'full_name'                   => $fullName,
                    'first_name'                  => $firstName,
                    'email'                       => $email,
                    'personero_type'              => $cargo,
                    'id_tipo_personero'           => $idTipoPersonero,
                    'phone_number'                => $phone,
                    'status'                      => $status,
                    'expediente_ext'              => $expedienteExt,
                    'codigo_declara'              => $codigoDeclara,
                    'jee_personero_declara_id'    => $idPersoneroDeclara,
                    'political_organization_name' => $orgName,
                    'political_organization_id'   => $orgId,
                    'jee_name'                    => $jeeName,
                    'jee_id'                      => $jeeId,
                    'department_name'             => $deptName,
                    'province_name'               => $provName,
                    'district_name'               => $distName,
                    'abogado_responsable'         => $abogado,
                ];
            }

            // 5.1 Insertar o actualizar Users del lote
            if (!empty($userBatch)) {
                $this->batchInsertOrUpdate(
                    'users',
                    $userColumns,
                    $userBatch,
                    [
                        'matchColumns'  => ['email'],
                        'updateColumns' => ['name', 'password', 'role', 'role_id', 'is_active', 'updated_at'],
                        'chunkSize'     => 1000,
                        'verbose'       => false,
                    ]
                );
            }

            // 5.2 Mapear emails -> user_id
            $chunkEmails = array_column($userBatch, 'email');
            $userIdMap = DB::table('users')
                ->whereIn('email', $chunkEmails)
                ->pluck('id', 'email')
                ->toArray();

            // 5.3 Preparar e insertar Personeros del lote
            $personeroBatch = [];
            foreach ($parsedPersoneros as $p) {
                $userId = $userIdMap[$p['email']] ?? null;

                $personeroBatch[] = [
                    'user_id'                     => $userId,
                    'election_id'                 => $election->id,
                    'political_organization_id'   => $p['political_organization_id'],
                    'document_number'             => $p['dni'],
                    'full_name'                   => $p['full_name'],
                    'first_name'                  => $p['first_name'],
                    'email'                       => $p['email'],
                    'personero_type'              => $p['personero_type'],
                    'id_tipo_personero'           => $p['id_tipo_personero'],
                    'phone_number'                => $p['phone_number'],
                    'status'                      => $p['status'],
                    'expediente_ext'              => $p['expediente_ext'],
                    'codigo_declara'              => $p['codigo_declara'],
                    'jee_personero_declara_id'    => $p['jee_personero_declara_id'],
                    'political_organization_name' => $p['political_organization_name'],
                    'jee_name'                    => $p['jee_name'],
                    'jee_id'                      => $p['jee_id'],
                    'department_name'             => $p['department_name'],
                    'province_name'               => $p['province_name'],
                    'district_name'               => $p['district_name'],
                    'abogado_responsable'         => $p['abogado_responsable'],
                    'created_at'                  => $now,
                    'updated_at'                  => $now,
                ];
            }

            if (!empty($personeroBatch)) {
                $this->batchInsertOrUpdate(
                    'personeros',
                    $personeroColumns,
                    $personeroBatch,
                    [
                        'matchColumns'  => ['document_number'],
                        'updateColumns' => [
                            'user_id',
                            'election_id',
                            'political_organization_id',
                            'full_name',
                            'first_name',
                            'email',
                            'personero_type',
                            'id_tipo_personero',
                            'phone_number',
                            'status',
                            'expediente_ext',
                            'codigo_declara',
                            'jee_personero_declara_id',
                            'political_organization_name',
                            'jee_name',
                            'jee_id',
                            'department_name',
                            'province_name',
                            'district_name',
                            'abogado_responsable',
                            'updated_at',
                        ],
                        'chunkSize'     => 1000,
                        'verbose'       => false,
                    ]
                );
            }

            $processed += count($chunk);
            $this->command?->info("Procesados $processed de $totalUnique personeros...");
        }

        $this->command?->info("✅ Personeros importados con éxito: $processed totales ($activeCount RECONOCIDOS activos, $inactiveCount inactivos)");
    }
}

