<?php

namespace App\Domain\Acts;

use App\Domain\Acts\DTOs\ActTotalsDTO;
use App\Domain\Evidence\EvidenceService;
use App\Models\Device;
use App\Models\Personero;
use App\Models\PollingStation;
use App\Models\SyncOperation;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class SyncService
{
    public function __construct(
        protected ActService $actService,
        protected EvidenceService $evidenceService
    ) {}

    /**
     * Procesa una operación de sincronización individual de manera idempotente.
     */
    public function processOperation(
        string $clientOperationId,
        ?Personero $personero,
        ?Device $device,
        string $entityType,
        string $entityId,
        string $operation,
        array $payload
    ): array {
        // 1. Verificar idempotencia en la base de datos
        $existingOp = SyncOperation::where('client_operation_id', $clientOperationId)->first();
        if ($existingOp && $existingOp->status === 'SYNCED') {
            return [
                'client_operation_id' => $clientOperationId,
                'status'              => 'SYNCED',
                'replayed'            => true,
                'processed_at'        => $existingOp->processed_at?->toIso8601String(),
                'entity_id'           => $existingOp->entity_id,
            ];
        }

        // Si no existe, crear registro en sync_operations
        $syncOp = $existingOp ?? SyncOperation::create([
            'client_operation_id' => $clientOperationId,
            'personero_id'        => $personero?->id,
            'device_id'           => $device?->id,
            'entity_type'         => $entityType,
            'entity_id'           => $entityId,
            'operation'           => $operation,
            'payload'             => $payload,
            'attempts'            => ($existingOp?->attempts ?? 0) + 1,
            'status'              => 'PROCESSING',
        ]);

        try {
            if ($personero && !in_array($entityType, ['acts', 'act_evidence'])) {
                throw new \Illuminate\Auth\Access\AuthorizationException(
                    "Un personero solo tiene autorización para sincronizar actas y evidencias de actas ('acts', 'act_evidence')."
                );
            }

            $result = match ($entityType) {
                'acts'             => $this->processActOperation($personero, $payload, $clientOperationId, $device?->id, $operation),
                'act_evidence'     => $this->processEvidenceOperation($payload, $device?->id),
                'personeros'       => $this->processPersoneroOperation($payload, $operation),
                'users'            => $this->processUserOperation($payload, $operation),
                'polling_stations' => $this->processPollingStationOperation($payload, $operation),
                default            => throw new \InvalidArgumentException("Tipo de entidad '{$entityType}' no soportada para sincronización."),
            };

            $syncOp->update([
                'status'       => 'SYNCED',
                'processed_at' => now(),
                'last_error'   => null,
            ]);

            return [
                'client_operation_id' => $clientOperationId,
                'status'              => 'SYNCED',
                'replayed'            => false,
                'processed_at'        => now()->toIso8601String(),
                'result'              => $result,
            ];
        } catch (\Throwable $e) {
            Log::error("Error procesando SyncOperation {$clientOperationId}: " . $e->getMessage(), [
                'exception' => $e,
            ]);

            $syncOp->update([
                'status'     => 'FAILED',
                'last_error' => $e->getMessage(),
                'attempts'   => $syncOp->attempts + 1,
            ]);

            throw $e;
        }
    }

    /**
     * Procesa un lote (batch) de operaciones de sincronización.
     */
    public function processBatch(
        ?Personero $personero,
        ?Device $device,
        array $operations
    ): array {
        $results = [];
        foreach ($operations as $op) {
            try {
                $res = $this->processOperation(
                    clientOperationId: $op['client_operation_id'],
                    personero: $personero,
                    device: $device,
                    entityType: $op['entity_type'],
                    entityId: (string)$op['entity_id'],
                    operation: $op['operation'] ?? 'CREATE',
                    payload: $op['payload'] ?? []
                );
                $results[] = $res;
            } catch (\Throwable $e) {
                $results[] = [
                    'client_operation_id' => $op['client_operation_id'] ?? null,
                    'status'              => 'FAILED',
                    'error'               => $e->getMessage(),
                ];
            }
        }

        return $results;
    }

    protected function processActOperation(?Personero $personero, array $payload, string $clientOpId, ?int $deviceId, string $operation = 'CREATE'): array
    {
        if ($operation === 'DELETE') {
            $act = null;
            if (!empty($payload['client_act_uuid'])) {
                $act = \App\Models\Act::where('client_operation_id', $payload['client_act_uuid'])->first();
            }
            if (!$act && !empty($payload['act_id'])) {
                $act = \App\Models\Act::find($payload['act_id']);
            }
            if ($act) {
                $act->evidence()->delete();
                $act->results()->delete();
                $act->totals()->delete();
                $act->delete();
            }
            return ['deleted' => true];
        }

        $station = PollingStation::where(function ($q) use ($payload) {
            if (!empty($payload['polling_station_id'])) {
                $q->where('id', $payload['polling_station_id']);
            }
            if (!empty($payload['polling_station_code'])) {
                $q->orWhere('code', $payload['polling_station_code']);
            }
        })->firstOrFail();

        // Validar ownership de mesa solo para rol PERSONERO
        if ($personero) {
            $hasStation = $personero->pollingStations()->where('polling_stations.id', $station->id)->exists();
            if (!$hasStation) {
                throw new \Illuminate\Auth\Access\AuthorizationException(
                    "El personero no tiene asignada la mesa {$station->code}."
                );
            }
        }

        $totalsDTO = ActTotalsDTO::fromArray($payload['totals'] ?? []);
        $results = $payload['results'] ?? [];
        $status = $payload['status'] ?? 'CONFIRMED';
        $electionId = (int)$payload['election_id'];
        $electoralLevelId = (int)$payload['electoral_level_id'];

        $created = $this->actService->createOrUpdateAct(
            electionId: $electionId,
            electoralLevelId: $electoralLevelId,
            station: $station,
            personero: $personero,
            totalsDTO: $totalsDTO,
            results: $results,
            actCode: $payload['act_code'] ?? null,
            status: $status,
            clientOperationId: $clientOpId,
            deviceId: $deviceId
        );

        return [
            'act_id'            => $created['act']->id,
            'status'            => $created['act']->status,
            'validation_result' => $created['validation_result']->toArray(),
        ];
    }

    protected function processEvidenceOperation(array $payload, ?int $deviceId): array
    {
        $act = \App\Models\Act::findOrFail($payload['act_id']);

        $evidence = $this->evidenceService->confirmEvidence(
            act: $act,
            objectKey: $payload['object_key'],
            sha256Hash: $payload['sha256_hash'],
            fileMime: $payload['file_mime'] ?? 'image/jpeg',
            fileSizeBytes: (int)($payload['file_size_bytes'] ?? 0),
            deviceId: $deviceId,
            widthPx: $payload['width_px'] ?? null,
            heightPx: $payload['height_px'] ?? null,
            capturedAt: $payload['captured_at'] ?? null
        );

        return [
            'evidence_id' => $evidence->id,
            'object_key'  => $evidence->object_key,
        ];
    }

    protected function processPersoneroOperation(array $payload, string $operation = 'CREATE'): array
    {
        return DB::transaction(function () use ($payload, $operation) {
            $docNumber = $payload['document_number'] ?? null;
            if (!$docNumber) {
                throw new \InvalidArgumentException("document_number es requerido para operaciones de personero.");
            }

            $personero = Personero::where('document_number', $docNumber)->first();

            if ($operation === 'DELETE') {
                if ($personero) {
                    $personero->pollingStations()->detach();
                    \App\Models\SyncOperation::where('personero_id', $personero->id)->update(['personero_id' => null]);
                    \App\Models\Device::where('personero_id', $personero->id)->delete();
                    $user = $personero->user;
                    $personero->delete();
                    if ($user) {
                        $user->tokens()->delete();
                        $user->delete();
                    }
                }
                return ['document_number' => $docNumber, 'deleted' => true];
            }

            $email = $payload['email'] ?? ($personero?->user?->email ?? "personero_{$docNumber}@conteoya.pe");
            $name = $payload['name'] ?? trim(($payload['first_name'] ?? '') . ' ' . ($payload['last_name'] ?? ''));
            if (empty($name) && $personero?->user) {
                $name = $personero->user->name;
            }

            $roleModel = \App\Models\Role::where('name', 'PERSONERO')->first();

            $user = \App\Models\User::updateOrCreate(
                ['email' => $email],
                [
                    'name'      => $name ?: "Personero $docNumber",
                    'password'  => \Illuminate\Support\Facades\Hash::make('Personero123!'),
                    'role'      => 'PERSONERO',
                    'role_id'   => $roleModel ? $roleModel->id : 3,
                    'is_active' => true,
                ]
            );

            if ($personero) {
                $personero->update([
                    'user_id'      => $user->id,
                    'phone_number' => $payload['phone_number'] ?? $personero->phone_number,
                ]);
            } else {
                $personero = Personero::create([
                    'document_number' => $docNumber,
                    'user_id'         => $user->id,
                    'phone_number'    => $payload['phone_number'] ?? null,
                ]);
            }

            $stationCodes = [];
            if (!empty($payload['polling_station_codes']) && is_array($payload['polling_station_codes'])) {
                $stationCodes = $payload['polling_station_codes'];
            } elseif (!empty($payload['polling_station_code'])) {
                $stationCodes = [$payload['polling_station_code']];
            }

            if (!empty($stationCodes)) {
                $locationId = \App\Models\ElectoralLocation::value('id') ?? 1;
                $stationIds = [];
                foreach ($stationCodes as $stCode) {
                    $station = PollingStation::firstOrCreate(
                        ['code' => $stCode],
                        [
                            'electoral_location_id' => $locationId,
                            'registered_voters'     => 300,
                            'status'                => 'ACTIVE',
                        ]
                    );
                    $stationIds[] = $station->id;
                }
                $personero->pollingStations()->sync($stationIds);
            }

            return [
                'personero_id'    => $personero->id,
                'user_id'         => $user->id,
                'document_number' => $personero->document_number,
            ];
        });
    }

    protected function processUserOperation(array $payload, string $operation = 'CREATE'): array
    {
        return DB::transaction(function () use ($payload, $operation) {
            $email = $payload['email'] ?? null;
            $userId = $payload['id'] ?? null;

            $user = null;
            if ($userId) {
                $user = \App\Models\User::find($userId);
            }
            if (!$user && $email) {
                $user = \App\Models\User::where('email', $email)->first();
            }

            if ($operation === 'DELETE') {
                if ($user) {
                    if ($user->personero) {
                        $user->personero->pollingStations()->detach();
                        $user->personero->delete();
                    }
                    $user->delete();
                }
                return ['email' => $email, 'deleted' => true];
            }

            if (!$user && !$email) {
                throw new \InvalidArgumentException("Email es requerido para operaciones de usuario.");
            }

            $role = strtoupper($payload['role'] ?? 'PERSONERO');
            $roleModel = \App\Models\Role::where('name', $role)->first();

            $userData = [
                'name'      => $payload['name'] ?? ($user?->name ?? 'Usuario'),
                'email'     => $email ?: $user->email,
                'role'      => $role,
                'role_id'   => $roleModel ? $roleModel->id : 3,
                'is_active' => $payload['is_active'] ?? ($user?->is_active ?? true),
            ];

            if (!empty($payload['password'])) {
                $userData['password'] = \Illuminate\Support\Facades\Hash::make($payload['password']);
            } elseif (!$user) {
                $userData['password'] = \Illuminate\Support\Facades\Hash::make('User123!');
            }

            if ($user) {
                $user->update($userData);
            } else {
                $user = \App\Models\User::create($userData);
            }

            if ($role === 'PERSONERO' || !empty($payload['document_number'])) {
                $docNumber = $payload['document_number'] ?? ('DNI' . str_pad((string)$user->id, 6, '0', STR_PAD_LEFT));
                $personero = Personero::updateOrCreate(
                    ['user_id' => $user->id],
                    [
                        'document_number' => $docNumber,
                        'phone_number'    => $payload['phone_number'] ?? null,
                    ]
                );

                if (!empty($payload['polling_station_code'])) {
                    $station = PollingStation::where('code', $payload['polling_station_code'])->first();
                    if ($station) {
                        $personero->pollingStations()->sync([$station->id]);
                    }
                }
            }

            return [
                'user_id' => $user->id,
                'email'   => $user->email,
                'role'    => $user->role,
            ];
        });
    }

    protected function processPollingStationOperation(array $payload, string $operation = 'CREATE'): array
    {
        $code = $payload['code'] ?? null;
        if (!$code) {
            throw new \InvalidArgumentException("code de mesa es requerido.");
        }

        $station = PollingStation::where('code', $code)->first();

        if ($operation === 'DELETE') {
            if ($station) {
                $station->personeros()->detach();
                $station->delete();
            }
            return ['code' => $code, 'deleted' => true];
        }

        $voters = (int)($payload['registered_voters'] ?? 300);
        $location = \App\Models\ElectoralLocation::first();
        if (!$location) {
            $department = \App\Models\Department::firstOrCreate(['code' => '15'], ['name' => 'LIMA']);
            $province = \App\Models\Province::firstOrCreate(['code' => '1501'], ['name' => 'LIMA', 'department_code' => '15']);
            $district = \App\Models\District::firstOrCreate(['code' => '150101'], ['name' => 'LIMA', 'province_code' => '1501', 'department_code' => '15']);
            $location = \App\Models\ElectoralLocation::create([
                'code'          => '150101-01',
                'name'          => $payload['location_name'] ?? 'LOCAL DE VOTACIÓN PRINCIPAL',
                'address'       => 'AV. PRINCIPAL 123',
                'district_code' => $district->code,
            ]);
        }

        if ($station) {
            $station->update([
                'registered_voters' => $voters,
                'status'            => $payload['status'] ?? $station->status,
            ]);
        } else {
            $station = PollingStation::create([
                'code'                  => $code,
                'electoral_location_id' => $location->id,
                'registered_voters'     => $voters,
                'status'                => $payload['status'] ?? 'ACTIVE',
            ]);
        }

        return [
            'polling_station_id' => $station->id,
            'code'               => $station->code,
        ];
    }
}
