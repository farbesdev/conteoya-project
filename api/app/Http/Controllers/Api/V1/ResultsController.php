<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Acts\Services\ResultsAggregationService;
use App\Http\Controllers\Controller;
use App\Models\Election;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * @tags Resultados y Consolidación Electoral
 */
class ResultsController extends Controller
{
    public function __construct(
        protected ResultsAggregationService $resultsService
    ) {}

    /**
     * Resumen Global de Resultados y Cobertura
     *
     * Retorna indicadores clave de desempeño electoral: % de actas procesadas, electores hábiles,
     * participación ciudadana, votos emitidos, válidos, en blanco, nulos e impugnados.
     * Soporta filtrado opcional por elección y niveles de Ubigeo.
     *
     * @unauthenticated
     * @queryParam election_id int ID de la elección (opcional). Example: 1
     * @queryParam department_code string Código o nombre del departamento. Example: 15
     * @queryParam province_code string Código o nombre de la provincia. Example: 1501
     * @queryParam district_code string Código o nombre del distrito. Example: 150101
     */
    public function summary(Request $request): JsonResponse
    {
        $electionId       = $request->filled('election_id') ? (int) $request->input('election_id') : null;
        $electoralLevelId = $request->filled('electoral_level_id') ? (int) $request->input('electoral_level_id') : null;
        $departmentCode   = $request->input('department_code');
        $provinceCode     = $request->input('province_code');
        $districtCode     = $request->input('district_code');

        $summary = $this->resultsService->getSummary(
            electionId: $electionId,
            electoralLevelId: $electoralLevelId,
            departmentCode: $departmentCode,
            provinceCode: $provinceCode,
            districtCode: $districtCode
        );

        return response()->json([
            'message' => 'Resumen de resultados consolidado obtenido exitosamente.',
            'data'    => $summary,
        ]);
    }

    /**
     * Resultados por Organización Política para una Elección
     *
     * Retorna el listado consolidado de votos por lista electoral / partido con ranking,
     * logos, porcentajes sobre votos válidos y porcentajes sobre votos emitidos totales.
     *
     * @unauthenticated
     * @queryParam electoral_level_id int ID del nivel electoral (Gobernador, Alcalde, etc.). Example: 1
     * @queryParam department_code string Código o nombre del departamento. Example: 15
     * @queryParam province_code string Código o nombre de la provincia. Example: 1501
     * @queryParam district_code string Código o nombre del distrito. Example: 150101
     */
    public function electionResults(Request $request, int $id): JsonResponse
    {
        $election = Election::find($id);
        if (!$election) {
            return response()->json(['message' => 'Elección no encontrada.'], 404);
        }

        $electoralLevelId = $request->filled('electoral_level_id') ? (int) $request->input('electoral_level_id') : null;
        $departmentCode   = $request->input('department_code');
        $provinceCode     = $request->input('province_code');
        $districtCode     = $request->input('district_code');

        $results = $this->resultsService->getElectionResults(
            electionId: $election->id,
            electoralLevelId: $electoralLevelId,
            departmentCode: $departmentCode,
            provinceCode: $provinceCode,
            districtCode: $districtCode
        );

        return response()->json([
            'message'  => 'Resultados por organización política obtenidos exitosamente.',
            'election' => [
                'id'   => $election->id,
                'code' => $election->code,
                'name' => $election->name,
                'date' => $election->date,
            ],
            'data'     => $results,
        ]);
    }

    /**
     * Resultados y Actas por Mesa Electoral
     *
     * Consulta el estado de las actas registradas para una mesa electoral específica.
     *
     * @unauthenticated
     * @param string $code Código único de mesa electoral (6 dígitos). Example: 030390
     */
    public function pollingStationResults(string $code): JsonResponse
    {
        $results = $this->resultsService->getStationResults($code);

        if (!$results) {
            return response()->json(['message' => 'Mesa electoral no encontrada.'], 404);
        }

        return response()->json([
            'message' => 'Resultados de mesa electoral obtenidos exitosamente.',
            'data'    => $results,
        ]);
    }
}
