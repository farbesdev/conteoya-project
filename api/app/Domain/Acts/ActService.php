<?php

namespace App\Domain\Acts;

use App\Domain\Acts\DTOs\ActTotalsDTO;
use App\Models\Act;
use App\Models\ActResult;
use App\Models\ActTotal;
use App\Models\AuditLog;
use App\Models\Personero;
use App\Models\PollingStation;
use App\Models\SyncOperation;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Request;

class ActService
{
    public function __construct(
        protected ActValidationService $validationService
    ) {}

    /**
     * Crea o actualiza un acta con sus totales y resultados atómicamente.
     */
    public function createOrUpdateAct(
        int $electionId,
        int $electoralLevelId,
        PollingStation $station,
        Personero $personero,
        ActTotalsDTO $totalsDTO,
        array $results,
        ?string $actCode = null,
        string $status = 'DRAFT',
        ?string $clientOperationId = null,
        ?int $deviceId = null
    ): array {
        $validationResult = $this->validationService->validate($totalsDTO, $results);

        $act = DB::transaction(function () use (
            $electionId,
            $electoralLevelId,
            $station,
            $personero,
            $totalsDTO,
            $results,
            $actCode,
            $status,
            $validationResult
        ) {
            // Crear o buscar acta existente para esta mesa y elección
            $act = Act::updateOrCreate(
                [
                    'polling_station_id' => $station->id,
                    'election_id'        => $electionId,
                    'electoral_level_id' => $electoralLevelId,
                ],
                [
                    'act_code'                 => $actCode,
                    'status'                   => $status,
                    'captured_by_personero_id' => $personero->id,
                    'captured_at'              => now(),
                    'confirmed_at'             => $status === 'CONFIRMED' || $status === 'SYNCED' ? now() : null,
                ]
            );

            // Guardar / Actualizar Totales
            ActTotal::updateOrCreate(
                ['act_id' => $act->id],
                [
                    'registered_voters' => $totalsDTO->registeredVoters,
                    'voters_who_voted'  => $totalsDTO->votersWhoVoted,
                    'total_votes'       => $totalsDTO->totalVotes,
                    'blank_votes'       => $totalsDTO->blankVotes,
                    'null_votes'        => $totalsDTO->nullVotes,
                    'challenged_votes'  => $totalsDTO->challengedVotes,
                    'is_valid_total'    => $validationResult->isValidTotal,
                ]
            );

            // Reemplazar / Crear Resultados de Votos
            $act->results()->delete();
            foreach ($results as $res) {
                ActResult::create([
                    'act_id'                    => $act->id,
                    'political_organization_id' => $res['political_organization_id'] ?? null,
                    'electoral_list_id'         => $res['electoral_list_id'] ?? null,
                    'candidate_id'              => $res['candidate_id'] ?? null,
                    'votes'                     => (int)($res['votes'] ?? 0),
                    'source'                    => $res['source'] ?? 'MANUAL',
                    'confidence'                => isset($res['confidence']) ? (float)$res['confidence'] : null,
                ]);
            }

            return $act;
        });

        // Registrar en audit log
        AuditLog::create([
            'user_id'     => $personero->user_id,
            'action'      => 'INGEST_ACT',
            'entity_type' => 'acts',
            'entity_id'   => (string)$act->id,
            'ip_address'  => Request::ip(),
            'user_agent'  => Request::userAgent(),
            'payload'     => [
                'polling_station_code' => $station->code,
                'status'               => $status,
                'warnings_count'       => count($validationResult->warnings),
                'client_operation_id'  => $clientOperationId,
            ],
        ]);

        return [
            'act'               => $act->load(['totals', 'results', 'pollingStation', 'capturedByPersonero.user']),
            'validation_result' => $validationResult,
        ];
    }

    /**
     * Confirma un acta previamente en DRAFT.
     */
    public function confirmAct(Act $act, Personero $personero): Act
    {
        $act->update([
            'status'       => 'CONFIRMED',
            'confirmed_at' => now(),
        ]);

        AuditLog::create([
            'user_id'     => $personero->user_id,
            'action'      => 'CONFIRM_ACT',
            'entity_type' => 'acts',
            'entity_id'   => (string)$act->id,
            'ip_address'  => Request::ip(),
            'user_agent'  => Request::userAgent(),
            'payload'     => [
                'confirmed_at' => now()->toIso8601String(),
            ],
        ]);

        return $act->load(['totals', 'results', 'pollingStation']);
    }
}
