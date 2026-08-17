<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\PollingStation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * @tags Mesas Electorales
 */
class PollingStationController extends Controller
{
    /**
     * Listar y Buscar Mesas Electorales (Paginación y Filtros para Admin / Director)
     *
     * Permite consultar y buscar mesas electorales con paginación de alto rendimiento.
     * Soporta filtrado por texto libre (`search`), código de mesa, departamento, provincia o distrito.
     *
     * @queryParam search string Término de búsqueda (Código de mesa, nombre del local de votación o distrito). Example: 030390
     * @queryParam department_name string Nombre del departamento para filtrar. Example: LIMA
     * @queryParam province_name string Nombre de la provincia para filtrar. Example: LIMA
     * @queryParam district_name string Nombre del distrito para filtrar. Example: MIRAFLORES
     * @queryParam per_page int Cantidad de elementos por página (default 10, max 50). Example: 10
     * @queryParam page int Número de página. Example: 1
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->input('per_page', 10), 50);
        if ($perPage < 1) {
            $perPage = 10;
        }

        $query = PollingStation::with(['electoralLocation.district.province.department']);

        // Filtro por búsqueda general (código de mesa o nombre de local)
        if ($search = $request->input('search')) {
            $search = trim($search);
            $query->where(function ($q) use ($search) {
                $q->where('code', 'LIKE', "%{$search}%")
                  ->orWhereHas('electoralLocation', function ($locQ) use ($search) {
                      $locQ->where('name', 'LIKE', "%{$search}%")
                           ->orWhereHas('district', function ($distQ) use ($search) {
                               $distQ->where('name', 'LIKE', "%{$search}%");
                           });
                  });
            });
        }

        // Filtros jerárquicos de ubicación si son especificados
        if ($dept = $request->input('department_name')) {
            $query->whereHas('electoralLocation.district.province.department', function ($q) use ($dept) {
                $q->where('name', 'LIKE', "%{$dept}%");
            });
        }

        if ($prov = $request->input('province_name')) {
            $query->whereHas('electoralLocation.district.province', function ($q) use ($prov) {
                $q->where('name', 'LIKE', "%{$prov}%");
            });
        }

        if ($dist = $request->input('district_name')) {
            $query->whereHas('electoralLocation.district', function ($q) use ($dist) {
                $q->where('name', 'LIKE', "%{$dist}%");
            });
        }

        $paginated = $query->orderBy('code')->paginate($perPage);

        $items = collect($paginated->items())->map(function ($station) {
            $loc = $station->electoralLocation;
            $dist = $loc?->district;
            $prov = $dist?->province;
            $dept = $prov?->department;

            return [
                'id'                => $station->id,
                'code'              => $station->code,
                'location_name'     => $loc?->name ?? 'LOCAL DE VOTACIÓN',
                'address'           => $loc?->address,
                'district_code'     => $dist?->code ?? '000000',
                'district_name'     => $dist?->name ?? 'DISTRITO',
                'province_name'     => $prov?->name ?? 'PROVINCIA',
                'department_name'   => $dept?->name ?? 'DEPARTAMENTO',
                'registered_voters' => $station->registered_voters,
                'status'            => $station->status,
            ];
        });

        return response()->json([
            'message' => 'Lista paginada de mesas electorales obtendida exitosamente.',
            'data'    => $items,
            'meta'    => [
                'current_page' => $paginated->currentPage(),
                'last_page'    => $paginated->lastPage(),
                'per_page'     => $paginated->perPage(),
                'total'        => $paginated->total(),
                'has_more'     => $paginated->hasMorePages(),
            ],
        ]);
    }
}
