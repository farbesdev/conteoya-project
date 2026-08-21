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
     * Retorna organizaciones políticas con caché en Redis de 12 horas o filtrado dinámico por búsqueda.
     */
    public function politicalOrganizations(Request $request)
    {
        if ($search = $request->query('search')) {
            $search = trim($search);
            $like = config('database.default') === 'pgsql' ? 'ILIKE' : 'LIKE';
            $results = PoliticalOrganization::where('name', $like, "%{$search}%")
                ->orWhere('short_name', $like, "%{$search}%")
                ->orderBy('name')
                ->limit(25)
                ->get();

            return response()->json($results);
        }

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
        $driver = config('database.default');

        // Caché L1 en Redis (24 horas) para responder en < 1ms a miles de personeros en concurrencia
        $cacheKey = "catalog:ballot_template:{$stationCode}:{$levelId}";

        $ballotData = Cache::remember($cacheKey, 86400, function () use ($stationCode, $levelId, $driver) {
            $station = \App\Models\PollingStation::where('code', $stationCode)->first();
            if (!$station)
                return null;

            $level = \App\Models\ElectoralLevel::find($levelId);
            if (!$level)
                return null;

            if ($driver === 'pgsql') {
                $result = \Illuminate\Support\Facades\DB::select(
                    "SELECT fn_get_polling_station_ballot(?, ?) AS ballot",
                    [$stationCode, $levelId]
                );
                if (isset($result[0]->ballot)) {
                    return json_decode($result[0]->ballot, true);
                }
            }

            // Resolver Ubigeo (departamento, provincia, distrito) de la mesa
            $deptName = $station->department_name;
            $provName = $station->province_name;
            $distName = $station->district_name;

            $district = \App\Models\District::where(function ($q) use ($distName) {
                $q->where('name', $distName)->orWhereRaw('LOWER(TRIM(name)) = LOWER(TRIM(?))', [$distName ?? '']);
            })->first();

            $distCode = $district?->code;
            $provCode = $district?->province_code ?? \App\Models\Province::where('name', $provName)->value('code');
            $deptCode = $district?->department_code ?? \App\Models\Department::where('name', $deptName)->value('code');

            if ($levelId == 2) {
                // Nivel Municipal Provincial - Distrital Combinado
                $provLists = ElectoralList::where('electoral_level_id', 2)
                    ->where('status', 'INSCRITO')
                    ->where(function ($q) use ($provCode) {
                        if ($provCode) {
                            $q->whereNull('province_code')->orWhere('province_code', $provCode);
                        }
                    })
                    ->with(['politicalOrganization', 'candidacies.candidate'])
                    ->get();

                $distLists = ElectoralList::where('electoral_level_id', 3)
                    ->where('status', 'INSCRITO')
                    ->where(function ($q) use ($distCode) {
                        if ($distCode) {
                            $q->whereNull('district_code')->orWhere('district_code', $distCode);
                        }
                    })
                    ->with(['politicalOrganization', 'candidacies.candidate'])
                    ->get();

                $orgsMap = [];

                $base = request()->getSchemeAndHttpHost();
                foreach ($provLists as $list) {
                    $org = $list->politicalOrganization;
                    if (!$org)
                        continue;
                    $orgId = $org->id;
                    $orgLogo = null;
                    if ($org->local_logo_url) {
                        $orgLogo = $base . '/storage/political-organizationals/' . ltrim($org->local_logo_url, '/');
                    } elseif ($org->logo_url) {
                        $orgLogo = str_starts_with($org->logo_url, '/storage/') ? ($base . $org->logo_url) : str_replace('http://localhost/storage/', $base . '/storage/', $org->logo_url);
                    }

                    if (!isset($orgsMap[$orgId])) {
                        $orgsMap[$orgId] = [
                            'electoral_list_id' => $list->id,
                            'political_organization_id' => $org->id,
                            'political_organization_name' => $org->name,
                            'political_organization_short_name' => $org->short_name,
                            'logo_url' => $orgLogo,
                            'local_logo_url' => $org->local_logo_url ? ($base . '/storage/political-organizationals/' . ltrim($org->local_logo_url, '/')) : null,
                            'is_provincial_admitted' => true,
                            'is_distrital_admitted' => false,
                            'candidates' => [],
                        ];
                    } else {
                        $orgsMap[$orgId]['is_provincial_admitted'] = true;
                    }
                }

                foreach ($distLists as $list) {
                    $org = $list->politicalOrganization;
                    if (!$org)
                        continue;
                    $orgId = $org->id;
                    $orgLogo = null;
                    if ($org->local_logo_url) {
                        $orgLogo = $base . '/storage/political-organizationals/' . ltrim($org->local_logo_url, '/');
                    } elseif ($org->logo_url) {
                        $orgLogo = str_starts_with($org->logo_url, '/storage/') ? ($base . $org->logo_url) : str_replace('http://localhost/storage/', $base . '/storage/', $org->logo_url);
                    }

                    if (!isset($orgsMap[$orgId])) {
                        $orgsMap[$orgId] = [
                            'electoral_list_id' => $list->id,
                            'political_organization_id' => $org->id,
                            'political_organization_name' => $org->name,
                            'political_organization_short_name' => $org->short_name,
                            'logo_url' => $orgLogo,
                            'local_logo_url' => $org->local_logo_url ? ($base . '/storage/political-organizationals/' . ltrim($org->local_logo_url, '/')) : null,
                            'is_provincial_admitted' => false,
                            'is_distrital_admitted' => true,
                            'candidates' => [],
                        ];
                    } else {
                        $orgsMap[$orgId]['is_distrital_admitted'] = true;
                    }
                }

                $lists = array_values($orgsMap);
            } else {
                // Nivel Simple (Regional u otro)
                $base = request()->getSchemeAndHttpHost();
                $listsQuery = ElectoralList::where('electoral_level_id', $levelId)
                    ->where('status', 'INSCRITO')
                    ->with(['politicalOrganization', 'candidacies.candidate']);

                if ($levelId == 1 && $deptCode) {
                    $listsQuery->where(function ($q) use ($deptCode) {
                        $q->whereNull('department_code')->orWhere('department_code', $deptCode);
                    });
                }

                $lists = $listsQuery->get()->map(function ($list) use ($base) {
                    $org = $list->political_organization;
                    $orgLogo = null;
                    if ($org?->local_logo_url) {
                        $orgLogo = $base . '/storage/political-organizationals/' . ltrim($org->local_logo_url, '/');
                    } elseif ($org?->logo_url) {
                        $orgLogo = str_starts_with($org->logo_url, '/storage/') ? ($base . $org->logo_url) : str_replace('http://localhost/storage/', $base . '/storage/', $org->logo_url);
                    }

                    return [
                        'electoral_list_id' => $list->id,
                        'political_organization_id' => $list->political_organization_id,
                        'political_organization_name' => $org?->name,
                        'political_organization_short_name' => $org?->short_name,
                        'logo_url' => $orgLogo,
                        'local_logo_url' => $org?->local_logo_url ? ($base . '/storage/political-organizationals/' . ltrim($org->local_logo_url, '/')) : null,
                        'is_provincial_admitted' => true,
                        'is_distrital_admitted' => true,
                        'candidates' => $list->candidacies->map(function ($c) use ($base) {
                            $photo = null;
                            if ($c->candidate?->local_photo_url) {
                                $photo = $base . '/storage/candidates/' . ltrim($c->candidate->local_photo_url, '/');
                            } elseif ($c->candidate?->photo_url) {
                                $photo = str_starts_with($c->candidate->photo_url, '/storage/') ? ($base . $c->candidate->photo_url) : str_replace('http://localhost/storage/', $base . '/storage/', $c->candidate->photo_url);
                            }

                            return [
                                'candidate_id' => $c->candidate_id,
                                'candidate_name' => $c->candidate?->full_name,
                                'candidate_document' => $c->candidate?->document_number,
                                'photo_url' => $photo,
                                'local_photo_url' => $c->candidate?->local_photo_url ? ($base . '/storage/candidates/' . ltrim($c->candidate->local_photo_url, '/')) : null,
                                'position' => $c->position,
                                'list_number' => $c->list_number,
                            ];
                        }),
                    ];
                })->all();
            }

            return [
                'station' => [
                    'id' => $station->id,
                    'code' => $station->code,
                    'registered_voters' => $station->registered_voters,
                    'status' => $station->status,
                    'department_code' => $deptCode,
                    'department_name' => $station->department_name,
                    'province_code' => $provCode,
                    'province_name' => $station->province_name,
                    'district_code' => $distCode,
                    'district_name' => $station->district_name,
                ],
                'electoral_level' => [
                    'id' => $level->id,
                    'code' => $level->code,
                    'name' => $level->name,
                    'has_preferential_vote' => $level->has_preferential_vote,
                ],
                'lists' => $lists,
            ];
        });

        if (!$ballotData) {
            return response()->json(['message' => 'Mesa o nivel electoral no encontrado'], 404);
        }

        return response()->json(['data' => $ballotData]);
    }
}

