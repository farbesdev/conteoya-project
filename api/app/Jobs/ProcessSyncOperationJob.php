<?php

namespace App\Jobs;

use App\Domain\Acts\SyncService;
use App\Models\SyncOperation;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class ProcessSyncOperationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries   = 5;
    public int $timeout = 60;

    public function __construct(
        public readonly string $clientOperationId
    ) {}

    public function handle(SyncService $syncService): void
    {
        $operation = SyncOperation::where('client_operation_id', $this->clientOperationId)->firstOrFail();

        // Idempotencia: si ya está sincronizada, no re-procesar
        if ($operation->status === 'SYNCED') {
            return;
        }

        $syncService->processOperation(
            clientOperationId: $operation->client_operation_id,
            personero: $operation->personero,
            device: $operation->device,
            entityType: $operation->entity_type,
            entityId: $operation->entity_id,
            operation: $operation->operation,
            payload: $operation->payload
        );
    }

    public function backoff(): array
    {
        return [10, 30, 60, 120, 300]; // Exponential backoff en segundos
    }

    public function failed(\Throwable $exception): void
    {
        Log::error("Fallo definitivo en Job ProcessSyncOperationJob ({$this->clientOperationId}): " . $exception->getMessage());
        SyncOperation::where('client_operation_id', $this->clientOperationId)->update([
            'status'     => 'FAILED',
            'last_error' => $exception->getMessage(),
        ]);
    }
}
