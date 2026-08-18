<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use App\Models\Election;
use App\Models\PoliticalOrganization;
use App\Models\Role;
use App\Models\User;
use App\Support\CSVProcessor;

class PersonerosSeeder extends Seeder
{
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

        // 5. Procesar e insertar registros
        $processed = 0;
        $activeCount = 0;
        $inactiveCount = 0;

        foreach ($personerosByDni as $dni => $row) {
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

            // Normalizar email
            $rawEmail = strtolower(trim((string)($row['strcorreoprincipal'] ?? $row['strCorreoPrincipal'] ?? '')));
            $email = (!empty($rawEmail) && filter_var($rawEmail, FILTER_VALIDATE_EMAIL))
                ? $rawEmail
                : "personero_{$dni}@conteoya.pe";

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

            // Crear o sincronizar User para el login con contraseña "{$dni}!" (inactivo por defecto)
            $user = User::updateOrCreate(
                ['email' => $email],
                [
                    'name'       => $fullName ?: "Personero DNI $dni",
                    'password'   => Hash::make("{$dni}!"),
                    'role'       => Role::PERSONERO,
                    'role_id'    => $personeroRole->id,
                    'is_active'  => false,
                ]
            );

            // Crear o sincronizar Personero
            \App\Models\Personero::updateOrCreate(
                ['document_number' => $dni],
                [
                    'user_id'                    => $user->id,
                    'election_id'                => $election->id,
                    'political_organization_id'  => $orgId,
                    'full_name'                  => $fullName,
                    'first_name'                 => $firstName,
                    'email'                      => $email,
                    'personero_type'             => $cargo,
                    'id_tipo_personero'          => $idTipoPersonero,
                    'phone_number'               => $phone,
                    'status'                     => $status,
                    'expediente_ext'             => $expedienteExt,
                    'codigo_declara'             => $codigoDeclara,
                    'jee_personero_declara_id'   => $idPersoneroDeclara,
                    'political_organization_name'=> $orgName,
                    'jee_name'                   => $jeeName,
                    'jee_id'                     => $jeeId,
                    'department_name'            => $deptName,
                    'province_name'              => $provName,
                    'district_name'              => $distName,
                    'abogado_responsable'        => $abogado,
                ]
            );

            $processed++;
            if ($processed % 250 === 0) {
                $this->command?->info("Procesados $processed de $totalUnique personeros...");
            }
        }

        $this->command?->info("✅ Personeros importados con éxito: $processed totales ($activeCount RECONOCIDOS activos, $inactiveCount inactivos)");
    }
}
