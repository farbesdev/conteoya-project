<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Evidence\EvidenceService;
use App\Http\Controllers\Controller;
use App\Http\Requests\ConfirmEvidenceRequest;
use App\Http\Requests\RequestUploadUrlRequest;
use App\Http\Resources\ActEvidenceResource;
use App\Models\Act;
use App\Models\ActEvidence;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

/**
 * @tags Evidencias Fotográficas
 */
class EvidenceController extends Controller
{
    public function __construct(
        protected EvidenceService $evidenceService
    ) {}

    /**
     * Solicitar URL Presignada de Subida a Cloudflare R2
     *
     * Genera una URL temporal con método PUT para que el cliente móvil suba directamente
     * la fotografía del acta de manera segura sin exponer credenciales del bucket.
     */
    public function requestUploadUrl(RequestUploadUrlRequest $request, Act $act): JsonResponse
    {
        Gate::authorize('upload', $act);

        $uploadInfo = $this->evidenceService->generateUploadUrl(
            act: $act,
            sha256Hash: $request->input('sha256_hash'),
            fileMime: $request->input('file_mime', 'image/jpeg'),
            fileSizeBytes: (int)$request->input('file_size_bytes'),
            ttlSeconds: 900
        );

        return response()->json([
            'message' => 'URL de subida generada con éxito.',
            'data'    => $uploadInfo,
        ]);
    }

    /**
     * Confirmar Subida de Evidencia Fotográfica
     *
     * Registra la evidencia en la base de datos una vez que el cliente móvil
     * completó la subida al bucket Cloudflare R2.
     */
    public function confirm(ConfirmEvidenceRequest $request, Act $act): JsonResponse
    {
        Gate::authorize('upload', $act);

        $evidence = $this->evidenceService->confirmEvidence(
            act: $act,
            objectKey: $request->input('object_key'),
            sha256Hash: $request->input('sha256_hash'),
            fileMime: $request->input('file_mime'),
            fileSizeBytes: (int)$request->input('file_size_bytes'),
            deviceId: $request->input('device_id'),
            widthPx: $request->input('width_px'),
            heightPx: $request->input('height_px'),
            capturedAt: $request->input('captured_at')
        );

        return response()->json([
            'message' => 'Evidencia fotográfica registrada y asociada al acta.',
            'data'    => new ActEvidenceResource($evidence),
        ], 201);
    }

    /**
     * Obtener URL Presignada de Descarga/Visualización
     *
     * Genera una URL firmada de lectura privada con TTL de 1 hora.
     */
    public function download(Request $request, Act $act, ActEvidence $evidence): JsonResponse
    {
        Gate::authorize('view', $evidence);

        $downloadUrl = $this->evidenceService->getDownloadUrl($evidence, 3600);

        return response()->json([
            'download_url'   => $downloadUrl,
            'expires_in_sec' => 3600,
        ]);
    }
}
