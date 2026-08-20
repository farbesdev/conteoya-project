<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Jobs\SyncCandidateCvsJob;
use App\Models\Candidate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

/**
 * @tags Candidatos - Sincronización de Hojas de Vida
 */
class CandidateCvSyncController extends Controller
{
    /**
     * Iniciar Sincronización Asíncrona de Hojas de Vida (Redis Queue)
     */
    public function startSync(Request $request): JsonResponse
    {
        $current = Cache::get(SyncCandidateCvsJob::CACHE_KEY);

        // Si ya está corriendo, devolver el estado actual
        if ($current && isset($current['status']) && $current['status'] === 'running') {
            return response()->json([
                'message' => 'La sincronización de hojas de vida ya se encuentra en ejecución.',
                'data'    => $current,
            ], 200);
        }

        $chunk = (int) $request->input('chunk', 50);
        $delayMs = (int) $request->input('delay_ms', 250);
        $limit = $request->has('limit') ? (int) $request->input('limit') : null;

        $totalCandidates = Candidate::whereNotNull('id_hoja_vida')
            ->where('id_hoja_vida', '!=', '')
            ->count();

        $initialProgress = [
            'status'             => 'running',
            'total'              => $limit ? min($totalCandidates, $limit) : $totalCandidates,
            'processed'          => 0,
            'success_count'      => 0,
            'error_count'        => 0,
            'percentage'         => 0.0,
            'last_candidate_name'=> 'Iniciando conexión con JNE Declara...',
            'started_at'         => now()->toIso8601String(),
            'updated_at'         => now()->toIso8601String(),
        ];

        Cache::put(SyncCandidateCvsJob::CACHE_KEY, $initialProgress, 86400);

        // Despachar Job asíncrono a la cola
        SyncCandidateCvsJob::dispatch($chunk, $delayMs, $limit);

        return response()->json([
            'message' => 'Sincronización de hojas de vida iniciada en segundo plano.',
            'data'    => $initialProgress,
        ], 202);
    }

    /**
     * Consultar Progreso y Estado de Sincronización en Tiempo Real
     */
    public function getStatus(): JsonResponse
    {
        $progress = Cache::get(SyncCandidateCvsJob::CACHE_KEY, [
            'status'             => 'idle',
            'total'              => Candidate::whereNotNull('id_hoja_vida')->where('id_hoja_vida', '!=', '')->count(),
            'processed'          => 0,
            'success_count'      => 0,
            'error_count'        => 0,
            'percentage'         => 0.0,
            'last_candidate_name'=> '',
            'started_at'         => null,
            'updated_at'         => null,
        ]);

        return response()->json([
            'message' => 'Estado de sincronización de hojas de vida.',
            'data'    => $progress,
        ]);
    }

    /**
     * Cancelar o Detener Sincronización Activa
     */
    public function cancelSync(): JsonResponse
    {
        $current = Cache::get(SyncCandidateCvsJob::CACHE_KEY);

        if ($current && isset($current['status']) && $current['status'] === 'running') {
            $current['status'] = 'canceled';
            $current['updated_at'] = now()->toIso8601String();
            Cache::put(SyncCandidateCvsJob::CACHE_KEY, $current, 86400);

            return response()->json([
                'message' => 'Sincronización cancelada exitosamente.',
                'data'    => $current,
            ]);
        }

        return response()->json([
            'message' => 'No hay ninguna sincronización en ejecución.',
            'data'    => $current,
        ]);
    }
}
