<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Acts\ActRecognitionService;
use App\Http\Controllers\Controller;
use App\Http\Requests\RecognizeActRequest;
use App\Models\Act;
use App\Models\ActEvidence;
use App\Models\PollingStation;
use Illuminate\Http\JsonResponse;

/**
 * @tags Reconocimiento OCR / IA
 */
class RecognitionController extends Controller
{
    public function __construct(
        protected ActRecognitionService $recognitionService
    ) {}

    /**
     * Procesar Imagen de Acta con OCR / IA (Human-in-the-Loop)
     *
     * Extrae automáticamente los totales y votos por lista a partir de una fotografía de acta.
     * IMPORTANTE: La IA/OCR nunca confirma el acta; únicamente sugiere valores acompañados
     * por un mapa de confianza (`confidence`). Los campos con confianza < 0.85 requieren revisión humana.
     */
    public function recognize(RecognizeActRequest $request, ?Act $act = null): JsonResponse
    {
        $imagePath = null;
        $mimeType = 'image/jpeg';

        if ($request->hasFile('image')) {
            $file = $request->file('image');
            $imagePath = $file->getRealPath();
            $mimeType = $file->getMimeType();
        } elseif ($request->has('image_url')) {
            $imagePath = $request->input('image_url');
        } else {
            // Imagen mock o simulación
            $imagePath = 'storage/mock/acta_demo.jpg';
        }

        $evidence = null;
        if ($request->has('act_evidence_id')) {
            $evidence = ActEvidence::find($request->input('act_evidence_id'));
        }

        $context = [];
        if ($request->has('polling_station_code')) {
            $context['polling_station_code'] = $request->input('polling_station_code');
            $station = PollingStation::where('code', $request->input('polling_station_code'))->first();
            if ($station) {
                $context['registered_voters'] = $station->registered_voters;
            }
        }

        $extraction = $this->recognitionService->recognize(
            imagePath: $imagePath,
            mimeType: $mimeType,
            act: $act,
            evidence: $evidence,
            context: $context
        );

        return response()->json([
            'message' => 'Extracción OCR/IA procesada con éxito.',
            'data'    => $extraction->toArray(),
        ]);
    }
}
