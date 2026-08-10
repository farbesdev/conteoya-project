<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Acts\SyncService;
use App\Http\Controllers\Controller;
use App\Http\Requests\SyncOperationRequest;
use App\Http\Resources\SyncOperationResource;
use App\Models\Device;
use App\Models\SyncOperation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * @tags Motor de Sincronización (Offline-First)
 */
class SyncController extends Controller
{
    public function __construct(
        protected SyncService $syncService
    ) {}

    /**
     * Sincronizar Operaciones en Lote (Sync Engine Endpoint)
     *
     * Recibe un lote de operaciones generadas offline por el cliente móvil (`SyncOperation`).
     * Cada operación posee un `client_operation_id` (UUID) para garantizar idempotencia.
     * Si la operación ya fue procesada anteriormente, se devuelve el estado previo sin duplicar.
     */
    public function sync(SyncOperationRequest $request): JsonResponse
    {
        $user = $request->user();
        $personero = $user->personero;

        if (!$personero && !$user->isAdmin()) {
            return response()->json(['message' => 'Solo personeros pueden sincronizar operaciones.'], 403);
        }

        $device = null;
        if ($request->has('device_uuid')) {
            $device = Device::where('device_uuid', $request->input('device_uuid'))->first();
        }

        $operations = $request->input('operations', []);
        $results = $this->syncService->processBatch(
            personero: $personero,
            device: $device,
            operations: $operations
        );

        return response()->json([
            'message' => 'Lote de operaciones de sincronización procesado.',
            'data'    => $results,
        ]);
    }

    /**
     * Consultar Estado de Sincronización
     *
     * Devuelve la lista de operaciones registradas para el usuario o dispositivo actual.
     */
    public function status(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = SyncOperation::query();

        if ($user->role === 'PERSONERO' && $user->personero) {
            $query->where('personero_id', $user->personero->id);
        }

        if ($request->has('client_operation_id')) {
            $query->where('client_operation_id', $request->input('client_operation_id'));
        }

        $operations = $query->latest()->limit(50)->get();

        return response()->json([
            'data' => SyncOperationResource::collection($operations),
        ]);
    }
}
