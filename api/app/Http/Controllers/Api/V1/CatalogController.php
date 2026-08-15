<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use App\Models\Department;
use App\Models\Province;
use App\Models\District;
use App\Models\Election;
use App\Models\PoliticalOrganization;
use App\Models\ElectoralList;

class CatalogController extends Controller
{
    /**
     * Retorna departamentos con caché en Redis de 24 horas.
     */
    public function departments()
    {
        $departments = Cache::remember('catalog:departments', 86400, function () {
            return Department::orderBy('name')->get();
        });

        return response()->json($departments);
    }

    /**
     * Retorna provincias por departamento con caché en Redis de 24 horas.
     */
    public function provinces(Request $request)
    {
        $depCode = $request->query('department_code', 'all');
        $cacheKey = "catalog:provinces:{$depCode}";

        $provinces = Cache::remember($cacheKey, 86400, function () use ($request) {
            $query = Province::query()->orderBy('name');
            if ($request->has('department_code')) {
                $query->where('department_code', $request->department_code);
            }
            return $query->get();
        });

        return response()->json($provinces);
    }

    /**
     * Retorna distritos por provincia con caché en Redis de 24 horas.
     */
    public function districts(Request $request)
    {
        $provCode = $request->query('province_code', 'all');
        $cacheKey = "catalog:districts:{$provCode}";

        $districts = Cache::remember($cacheKey, 86400, function () use ($request) {
            $query = District::query()->orderBy('name');
            if ($request->has('province_code')) {
                $query->where('province_code', $request->province_code);
            }
            return $query->get();
        });

        return response()->json($districts);
    }

    /**
     * Retorna elecciones activas con niveles electorales en caché de Redis.
     */
    public function elections()
    {
        $elections = Cache::remember('catalog:elections', 86400, function () {
            return Election::with('levels')->get();
        });

        return response()->json($elections);
    }

    /**
     * Retorna organizaciones políticas con caché en Redis de 12 horas.
     */
    public function politicalOrganizations()
    {
        $orgs = Cache::remember('catalog:political_organizations', 43200, function () {
            return PoliticalOrganization::orderBy('name')->get();
        });

        return response()->json($orgs);
    }

    /**
     * Listas electorales filtradas por nivel/ubigeo con soporte de paginación y caché dinámico.
     */
    public function electoralLists(Request $request)
    {
        $levelId = $request->query('electoral_level_id', '0');
        $districtCode = $request->query('district_code', '0');
        $page = $request->query('page', '1');

        $cacheKey = "catalog:electoral_lists:L{$levelId}_D{$districtCode}_P{$page}";

        $lists = Cache::remember($cacheKey, 3600, function () use ($request) {
            $query = ElectoralList::with(['politicalOrganization', 'candidacies.candidate']);

            if ($request->has('electoral_level_id')) {
                $query->where('electoral_level_id', $request->electoral_level_id);
            }

            if ($request->has('district_code')) {
                $query->where('district_code', $request->district_code);
            }

            return $query->paginate(50);
        });

        return response()->json($lists);
    }

    /**
     * Catálogo de mesas de votación con búsqueda en tiempo real, filtros y paginación.
     */
    public function pollingStations(Request $request)
    {
        $query = \Illuminate\Support\Facades\DB::table('polling_stations')
            ->join('electoral_locations', 'polling_stations.electoral_location_id', '=', 'electoral_locations.id')
            ->join('districts', 'electoral_locations.district_code', '=', 'districts.code')
            ->join('provinces', 'districts.province_code', '=', 'provinces.code')
            ->join('departments', 'districts.department_code', '=', 'departments.code')
            ->select([
                'polling_stations.id',
                'polling_stations.code',
                'electoral_locations.name as location_name',
                'electoral_locations.address',
                'districts.code as district_code',
                'districts.name as district_name',
                'provinces.name as province_name',
                'departments.name as department_name',
                'polling_stations.registered_voters',
                'polling_stations.status',
            ]);

        if ($request->filled('department_code')) {
            $query->where('departments.code', $request->query('department_code'));
        }
        if ($request->filled('province_code')) {
            $query->where('provinces.code', $request->query('province_code'));
        }
        if ($request->filled('district_code')) {
            $query->where('districts.code', $request->query('district_code'));
        }
        if ($request->filled('search')) {
            $search = $request->query('search');
            $query->where(function ($q) use ($search) {
                $q->where('polling_stations.code', 'like', "%{$search}%")
                  ->orWhere('electoral_locations.name', 'like', "%{$search}%")
                  ->orWhere('districts.name', 'like', "%{$search}%");
            });
        }

        $perPage = (int) $request->query('per_page', 20);
        $perPage = min(max($perPage, 1), 100);

        $results = $query->orderBy('polling_stations.code')->paginate($perPage);

        return response()->json($results);
    }
}
