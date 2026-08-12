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
            $result = match ($entityType) {
                'acts'         => $this->processActOperation($personero, $payload, $clientOperationId, $device?->id),
                'act_evidence' => $this->processEvidenceOperation($payload, $device?->id),
                'personeros'   => $this->processPersoneroOperation($payload),
                default        => throw new \InvalidArgumentException("Tipo de entidad '{$entityType}' no soportada para sincronización."),
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

    protected function processActOperation(?Personero $personero, array $payload, string $clientOpId, ?int $deviceId): array
    {
        $station = PollingStation::where('code', $payload['polling_station_code'])->firstOrFail();

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

    protected function processPersoneroOperation(array $payload): array
    {
        return DB::transaction(function () use ($payload) {
            $docNumber = $payload['document_number'];
            $email = $payload['email'] ?? "personero_{$docNumber}@conteoya.pe";
            $name = $payload['name'] ?? trim(($payload['first_name'] ?? '') . ' ' . ($payload['last_name'] ?? ''));

            $roleModel = \App\Models\Role::where('name', 'PERSONERO')->first();

            $user = \App\Models\User::firstOrCreate(
                ['email' => $email],
                [
                    'name'      => $name,
                    'password'  => \Illuminate\Support\Facades\Hash::make('Personero123!'),
                    'role'      => 'PERSONERO',
                    'role_id'   => $roleModel ? $roleModel->id : 3,
                    'is_active' => true,
                ]
            );

            $personero = Personero::firstOrCreate(
                ['document_number' => $docNumber],
                [
                    'user_id'      => $user->id,
                    'phone_number' => $payload['phone_number'] ?? null,
                ]
            );

            if (!empty($payload['polling_station_code'])) {
                $station = PollingStation::where('code', $payload['polling_station_code'])->first();
                if ($station) {
                    $personero->pollingStations()->syncWithoutDetaching([$station->id]);
                }
            }

            return [
                'personero_id'    => $personero->id,
                'user_id'         => $user->id,
                'document_number' => $personero->document_number,
            ];
        });
    }
}
