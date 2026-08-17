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
     * Retorna la plantilla estructurada de la cédula electoral (mesa, organizaciones, listas y candidatos)
     * para el registro de actas electorales mediante consulta a la vista/procedimiento de base de datos.
     */
    public function ballotTemplate(Request $request)
    {
        $request->validate([
            'polling_station_code' => 'required|string',
            'electoral_level_id' => 'required|integer',
        ]);

        $stationCode = $request->query('polling_station_code');
        $levelId = (int) $request->query('electoral_level_id');

        // Consultar directamente usando DB::select / DB::table para compatibilidad tanto con PostgreSQL como SQLite
        $driver = config('database.default');

        if ($driver === 'pgsql') {
            $result = \Illuminate\Support\Facades\DB::select(
                "SELECT fn_get_polling_station_ballot(?, ?) AS ballot",
                [$stationCode, $levelId]
            );
            $ballotData = isset($result[0]->ballot) ? json_decode($result[0]->ballot, true) : null;
            return response()->json(['data' => $ballotData]);
        }

        // Fallback de compatibilidad relacional estándar
        $station = \App\Models\PollingStation::where('code', $stationCode)->firstOrFail();
        $level = \App\Models\ElectoralLevel::findOrFail($levelId);

        $lists = ElectoralList::where('electoral_level_id', $levelId)
            ->with(['politicalOrganization', 'candidacies.candidate'])
            ->where('status', 'INSCRITO')
            ->get()
            ->map(function ($list) {
                return [
                    'electoral_list_id' => $list->id,
                    'political_organization_id' => $list->political_organization_id,
                    'political_organization_name' => $list->political_organization?->name,
                    'political_organization_short_name' => $list->political_organization?->short_name,
                    'logo_url' => $list->political_organization?->logo_url,
                    'local_logo_url' => $list->political_organization?->local_logo_url,
                    'candidates' => $list->candidacies->map(function ($c) {
                        return [
                            'candidate_id' => $c->candidate_id,
                            'candidate_name' => $c->candidate?->full_name,
                            'candidate_document' => $c->candidate?->document_number,
                            'photo_url' => $c->candidate?->photo_url,
                            'local_photo_url' => $c->candidate?->local_photo_url,
                            'position' => $c->position,
                            'list_number' => $c->list_number,
                        ];
                    }),
                ];
            });

        return response()->json([
            'data' => [
                'station' => [
                    'id' => $station->id,
                    'code' => $station->code,
                    'registered_voters' => $station->registered_voters,
                    'status' => $station->status,
                    'department_name' => $station->department_name,
                    'province_name' => $station->province_name,
                    'district_name' => $station->district_name,
                ],
                'electoral_level' => [
                    'id' => $level->id,
                    'code' => $level->code,
                    'name' => $level->name,
                    'has_preferential_vote' => $level->has_preferential_vote,
                ],
                'lists' => $lists,
            ]
        ]);
    }
}

