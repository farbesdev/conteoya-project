<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Jobs\ImportCandidatesJsonJob;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * @tags Candidatos - Importación de Padrón JEE
 */
class CandidateImportController extends Controller
{
    /**
     * Subir e Importar Archivo JSON de Candidatos JEE (>150MB)
     *
     * @bodyParam file file required Archivo JSON con el padrón completo oficial de candidatos del JEE (soporta archivos de más de 150MB).
     */
    public function importJson(Request $request): JsonResponse
    {
        $current = Cache::get(ImportCandidatesJsonJob::CACHE_KEY);
        if ($current && isset($current['status']) && $current['status'] === 'running') {
            return response()->json([
                'message' => 'Ya existe un proceso de importación en ejecución.',
                'data'    => $current,
            ], 200);
        }

        $request->validate([
            'file' => ['required', 'file', 'max:350000'], // hasta 350 MB
        ], [
            'file.required' => 'Debe seleccionar un archivo JSON para importar.',
            'file.file'     => 'El archivo enviado no es válido.',
            'file.max'      => 'El archivo no debe exceder los 350 MB.',
        ]);

        $uploadedFile = $request->file('file');
        $originalName = $uploadedFile->getClientOriginalName();
        $extension = strtolower($uploadedFile->getClientOriginalExtension());

        if ($extension !== 'json') {
            return response()->json([
                'message' => 'El archivo debe tener extensión .json',
            ], 422);
        }

        $importsDir = storage_path('app/imports');
        if (!file_exists($importsDir)) {
            @mkdir($importsDir, 0755, true);
        }

        $targetFileName = 'candidates_import_' . Str::uuid() . '.json';
        $targetPath = $importsDir . '/' . $targetFileName;

        $uploadedFile->move($importsDir, $targetFileName);

        $initialProgress = [
            'status'             => 'running',
            'file_name'          => $originalName,
            'total'              => 0,
            'processed'          => 0,
            'new_candidates'     => 0,
            'updated_candidates' => 0,
            'new_lists'          => 0,
            'percentage'         => 0.0,
            'last_candidate_name'=> 'Archivo recibido. Iniciando procesamiento en cola...',
            'started_at'         => now()->toIso8601String(),
            'updated_at'         => now()->toIso8601String(),
        ];

        Cache::put(ImportCandidatesJsonJob::CACHE_KEY, $initialProgress, 86400);

        // Despachar Job asíncrono
        ImportCandidatesJsonJob::dispatch($targetPath, $originalName);

        return response()->json([
            'message' => 'Archivo JSON recibido correctamente. Procesamiento iniciado en segundo plano.',
            'data'    => $initialProgress,
        ], 202);
    }

    /**
     * Consultar Progreso en Tiempo Real de la Importación JSON
     */
    public function getStatus(): JsonResponse
    {
        $progress = Cache::get(ImportCandidatesJsonJob::CACHE_KEY, [
            'status'             => 'idle',
            'file_name'          => null,
            'total'              => 0,
            'processed'          => 0,
            'new_candidates'     => 0,
            'updated_candidates' => 0,
            'new_lists'          => 0,
            'percentage'         => 0.0,
            'last_candidate_name'=> '',
            'started_at'         => null,
            'updated_at'         => null,
        ]);

        return response()->json([
            'message' => 'Estado de importación de candidatos JEE.',
            'data'    => $progress,
        ]);
    }

    /**
     * Cancelar Proceso de Importación Activo
     */
    public function cancelImport(): JsonResponse
    {
        $current = Cache::get(ImportCandidatesJsonJob::CACHE_KEY);

        if ($current && isset($current['status']) && $current['status'] === 'running') {
            $current['status'] = 'canceled';
            $current['updated_at'] = now()->toIso8601String();
            Cache::put(ImportCandidatesJsonJob::CACHE_KEY, $current, 86400);

            return response()->json([
                'message' => 'Proceso de importación cancelado exitosamente.',
                'data'    => $current,
            ]);
        }

        return response()->json([
            'message' => 'No hay ningún proceso de importación activo para cancelar.',
            'data'    => $current,
        ], 200);
    }
}
