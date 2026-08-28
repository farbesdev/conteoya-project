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
                $levelId = (int)$request->input('electoral_level_id', 1);
                $context['electoral_level_id'] = $levelId;

                $dept = \App\Models\Department::whereRaw('upper(trim(name)) = ?', [strtoupper(trim($station->department_name))])->first();
                if ($dept) {
                    $query = \App\Models\ElectoralList::where('department_code', $dept->code)
                        ->where('electoral_level_id', $levelId)
                        ->whereIn('status', ['INSCRITO', 'ADMITIDO', 'INSCRITA', 'ADMITIDA'])
                        ->with('politicalOrganization');

                    if ($levelId == 3 && $station->province_name) {
                        $prov = \App\Models\Province::where('department_code', $dept->code)
                            ->whereRaw('upper(trim(name)) = ?', [strtoupper(trim($station->province_name))])
                            ->first();
                        if ($prov) {
                            $query->where('province_code', $prov->code);
                        }
                    } elseif ($levelId == 4 && $station->district_name) {
                        $dist = \App\Models\District::whereRaw('upper(trim(name)) = ?', [strtoupper(trim($station->district_name))])
                            ->first();
                        if ($dist) {
                            $query->where('district_code', $dist->code);
                        }
                    }

                    $lists = $query->get();
                    if ($lists->isNotEmpty()) {
                        $context['organizations'] = $lists->map(function ($list) {
                            return [
                                'id'                => $list->political_organization_id,
                                'name'              => $list->politicalOrganization?->name,
                                'short_name'        => $list->politicalOrganization?->short_name,
                                'electoral_list_id' => $list->id,
                            ];
                        })->toArray();
                    }
                }
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
