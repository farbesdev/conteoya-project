<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ElectoralLocation;
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

        if ($search = $request->input('search')) {
            $search = trim($search);
            // Usamos ILIKE (PostgreSQL) para búsqueda insensible a mayúsculas/minúsculas.
            // En SQLite (tests), LIKE ya es case-insensitive para ASCII.
            // Se busca tanto en columnas directas de polling_stations (mesas JEE desnormalizadas)
            // como en la relación electoralLocation para mesas con location_id configurado.
            $like = config('database.default') === 'pgsql' ? 'ILIKE' : 'LIKE';
            $query->where(function ($q) use ($search, $like) {
                $q->where('code', $like, "%{$search}%")
                  ->orWhere('odpe', $like, "%{$search}%")
                  ->orWhere('department_name', $like, "%{$search}%")
                  ->orWhere('province_name', $like, "%{$search}%")
                  ->orWhere('district_name', $like, "%{$search}%")
                  ->orWhereHas('electoralLocation', function ($locQ) use ($search, $like) {
                      $locQ->where('name', $like, "%{$search}%")
                           ->orWhere('address', $like, "%{$search}%")
                           ->orWhereHas('district', function ($distQ) use ($search, $like) {
                               $distQ->where('name', $like, "%{$search}%")
                                     ->orWhere('code', $like, "%{$search}%")
                                     ->orWhereHas('province', function ($provQ) use ($search, $like) {
                                         $provQ->where('name', $like, "%{$search}%")
                                               ->orWhereHas('department', function ($deptQ) use ($search, $like) {
                                                   $deptQ->where('name', $like, "%{$search}%");
                                               });
                                     });
                           });
                  });
            });
        }

        if ($dept = $request->input('department_name')) {
            $like = config('database.default') === 'pgsql' ? 'ILIKE' : 'LIKE';
            $query->where(function ($q) use ($dept, $like) {
                $q->where('department_name', $like, "%{$dept}%")
                  ->orWhereHas('electoralLocation.district.province.department', function ($subQ) use ($dept, $like) {
                      $subQ->where('name', $like, "%{$dept}%");
                  });
            });
        }

        if ($prov = $request->input('province_name')) {
            $like = config('database.default') === 'pgsql' ? 'ILIKE' : 'LIKE';
            $query->where(function ($q) use ($prov, $like) {
                $q->where('province_name', $like, "%{$prov}%")
                  ->orWhereHas('electoralLocation.district.province', function ($subQ) use ($prov, $like) {
                      $subQ->where('name', $like, "%{$prov}%");
                  });
            });
        }

        if ($dist = $request->input('district_name')) {
            $like = config('database.default') === 'pgsql' ? 'ILIKE' : 'LIKE';
            $query->where(function ($q) use ($dist, $like) {
                $q->where('district_name', $like, "%{$dist}%")
                  ->orWhereHas('electoralLocation.district', function ($subQ) use ($dist, $like) {
                      $subQ->where('name', $like, "%{$dist}%");
                  });
            });
        }

        $paginated = $query->orderBy('code')->paginate($perPage);

        $items = collect($paginated->items())->map(function ($station) {
            return $this->formatStation($station);
        });

        return response()->json([
            'message' => 'Lista paginada de mesas electorales obtenida exitosamente.',
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

    /**
     * Obtener Detalles de una Mesa Electoral por ID
     */
    public function show(int $id): JsonResponse
    {
        $station = PollingStation::with(['electoralLocation.district.province.department'])->find($id);

        if (!$station) {
            return response()->json(['message' => 'Mesa electoral no encontrada.'], 404);
        }

        return response()->json([
            'message' => 'Mesa electoral obtenida exitosamente.',
            'data'    => $this->formatStation($station),
        ]);
    }

    /**
     * Crear Nueva Mesa Electoral (Solo Admin o Director)
     */
    public function store(Request $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->isAdmin() && !$user->isDirector()) {
            return response()->json(['message' => 'No autorizado para crear mesas electorales.'], 403);
        }

        $validated = $request->validate([
            'code'              => 'required|string|max:10|unique:polling_stations,code',
            'registered_voters' => 'required|integer|min:1',
            'status'            => 'nullable|string|in:ACTIVE,INACTIVE',
            'location_name'     => 'nullable|string',
        ]);

        $location = ElectoralLocation::first();
        if (!$location) {
            $department = \App\Models\Department::firstOrCreate(['code' => '15'], ['name' => 'LIMA']);
            $province = \App\Models\Province::firstOrCreate(['code' => '1501'], ['name' => 'LIMA', 'department_code' => '15']);
            $district = \App\Models\District::firstOrCreate(['code' => '150101'], ['name' => 'LIMA', 'province_code' => '1501', 'department_code' => '15']);
            $location = ElectoralLocation::create([
                'code'          => '150101-01',
                'name'          => $request->input('location_name', 'LOCAL DE VOTACIÓN PRINCIPAL'),
                'address'       => 'AV. PRINCIPAL 123',
                'district_code' => $district->code,
            ]);
        }

        $station = PollingStation::create([
            'code'                  => $validated['code'],
            'electoral_location_id' => $location->id,
            'registered_voters'     => $validated['registered_voters'],
            'status'                => $validated['status'] ?? 'ACTIVE',
        ]);

        $station->load(['electoralLocation.district.province.department']);

        return response()->json([
            'message' => 'Mesa electoral creada exitosamente.',
            'data'    => $this->formatStation($station),
        ], 201);
    }

    /**
     * Actualizar Mesa Electoral (Solo Admin o Director)
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if (!$user->isAdmin() && !$user->isDirector()) {
            return response()->json(['message' => 'No autorizado para actualizar mesas electorales.'], 403);
        }

        $station = PollingStation::find($id);
        if (!$station) {
            return response()->json(['message' => 'Mesa electoral no encontrada.'], 404);
        }

        $validated = $request->validate([
            'code'              => 'nullable|string|max:10|unique:polling_stations,code,' . $station->id,
            'registered_voters' => 'nullable|integer|min:1',
            'status'            => 'nullable|string|in:ACTIVE,INACTIVE',
        ]);

        $station->update(array_filter([
            'code'              => $validated['code'] ?? null,
            'registered_voters' => $validated['registered_voters'] ?? null,
            'status'            => $validated['status'] ?? null,
        ]));

        $station->load(['electoralLocation.district.province.department']);

        return response()->json([
            'message' => 'Mesa electoral actualizada exitosamente.',
            'data'    => $this->formatStation($station),
        ]);
    }

    /**
     * Eliminar Mesa Electoral (Solo Admin o Director)
     */
    public function destroy(Request $request, int $id): JsonResponse
    {
        $user = $request->user();
        if (!$user->isAdmin() && !$user->isDirector()) {
            return response()->json(['message' => 'No autorizado para eliminar mesas electorales.'], 403);
        }

        $station = PollingStation::find($id);
        if (!$station) {
            return response()->json(['message' => 'Mesa electoral no encontrada.'], 404);
        }

        $station->personeros()->detach();
        $station->delete();

        return response()->json([
            'message' => 'Mesa electoral eliminada exitosamente.',
        ]);
    }

    protected function formatStation(PollingStation $station): array
    {
        $loc  = $station->electoralLocation;
        $dist = $loc?->district;
        $prov = $dist?->province;
        $dept = $prov?->department;

        // Las mesas importadas del JEE tienen los nombres reales en columnas directas
        // (department_name, province_name, district_name). La relación electoralLocation
        // solo existe para mesas creadas manualmente o con location propia (ej. I.E. YUYAPICHIS).
        // Se usan las columnas directas como fuente primaria para los nombres geográficos.
        $locationName   = $loc?->name ?? 'LOCAL DE VOTACIÓN';
        $districtName   = $dist?->name ?? $station->district_name ?? 'DISTRITO';
        $provinceName   = $prov?->name ?? $station->province_name ?? 'PROVINCIA';
        $departmentName = $dept?->name ?? $station->department_name ?? 'DEPARTAMENTO';
        $districtCode   = $dist?->code ?? $station->district_code ?? '000000';

        return [
            'id'                => $station->id,
            'code'              => $station->code,
            'location_name'     => $locationName,
            'address'           => $loc?->address,
            'district_code'     => $districtCode,
            'district_name'     => $districtName,
            'province_name'     => $provinceName,
            'department_name'   => $departmentName,
            'odpe'              => $station->odpe,
            'registered_voters' => $station->registered_voters,
            'status'            => $station->status,
        ];
    }

}
