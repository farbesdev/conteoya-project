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
        ]);

        $stationCode = $request->query('polling_station_code');
        $levelParam = $request->query('electoral_level_id') ?? $request->query('electoral_level_code');
        
        // Buscar el nivel electoral por ID o por Código
        $level = is_numeric($levelParam)
            ? \App\Models\ElectoralLevel::find((int) $levelParam)
            : \App\Models\ElectoralLevel::where('code', (string) $levelParam)->first();

        if (!$level) {
            $level = \App\Models\ElectoralLevel::where('code', 'REGIONAL_GOBERNADOR')->first();
        }

        $levelId = $level ? $level->id : 1;
        $levelCode = $level ? $level->code : 'REGIONAL_GOBERNADOR';
        $driver = config('database.default');

        // Caché L1 en Redis (24 horas) para responder en < 1ms a miles de personeros en concurrencia
        $cacheKey = "catalog:ballot_template:{$stationCode}:{$levelCode}";

        $ballotData = Cache::remember($cacheKey, 86400, function () use ($stationCode, $level, $levelCode) {
            $station = \App\Models\PollingStation::where('code', $stationCode)->first();
            if (!$station)
                return null;

            // Resolver Ubigeo (departamento, provincia, distrito) de la mesa
            $deptName = trim($station->department_name ?? '');
            $provName = trim($station->province_name ?? '');
            $distName = trim($station->district_name ?? '');

            // 1. Resolver Distrito y Provincia exactos
            $district = \App\Models\District::whereRaw('LOWER(TRIM(name)) = LOWER(TRIM(?))', [$distName])->first();
            $distCode = $district?->code;
            $provCode = $district?->province_code ?? \App\Models\Province::whereRaw('LOWER(TRIM(name)) = LOWER(TRIM(?))', [$provName])->value('code');

            // 2. Resolver Departamento exacto
            $deptCodes = \App\Models\Department::whereRaw('LOWER(TRIM(name)) = LOWER(TRIM(?))', [$deptName])->pluck('code')->toArray();
            if (empty($deptCodes) && $district?->department_code) {
                $deptCodes = [$district->department_code];
            }

            // Solo estados válidos de listas participantes en la cédula oficial
            $allowedStatuses = ['INSCRITO', 'ADMITIDO'];

            // Resolver los niveles electorales por código
            $provLevel = \App\Models\ElectoralLevel::where('code', 'MUNICIPAL_PROVINCIAL')->first();
            $distLevel = \App\Models\ElectoralLevel::where('code', 'MUNICIPAL_DISTRITAL')->first();
            $regLevel = \App\Models\ElectoralLevel::where('code', 'REGIONAL_GOBERNADOR')->first();

            $isMunicipal = in_array($levelCode, ['MUNICIPAL_PROVINCIAL', 'MUNICIPAL_DISTRITAL', 'MUNICIPAL_PROVINCIAL_DISTRITAL']) || $level->id == 2 || $level->id == 3;

            if ($isMunicipal) {
                // Nivel Municipal Provincial - Distrital Combinado
                $provLevelId = $provLevel ? $provLevel->id : 2;
                $distLevelId = $distLevel ? $distLevel->id : 3;

                $provLists = ElectoralList::where('electoral_level_id', $provLevelId)
                    ->whereIn('status', $allowedStatuses)
                    ->where(function ($q) use ($provCode) {
                        if ($provCode) {
                            $q->where('province_code', $provCode);
                        }
                    })
                    ->with(['politicalOrganization', 'candidacies.candidate'])
                    ->get();

                $distLists = ElectoralList::where('electoral_level_id', $distLevelId)
                    ->whereIn('status', $allowedStatuses)
                    ->where(function ($q) use ($distCode) {
                        if ($distCode) {
                            $q->where('district_code', $distCode);
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

                    $provCandidates = $list->candidacies->map(function ($c) use ($base) {
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
                    })->all();

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
                            'candidates' => $provCandidates,
                        ];
                    } else {
                        $orgsMap[$orgId]['is_provincial_admitted'] = true;
                        if (empty($orgsMap[$orgId]['candidates'])) {
                            $orgsMap[$orgId]['candidates'] = $provCandidates;
                        }
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

                    $distCandidates = $list->candidacies->map(function ($c) use ($base) {
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
                    })->all();

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
                            'candidates' => $distCandidates,
                        ];
                    } else {
                        $orgsMap[$orgId]['is_distrital_admitted'] = true;
                    }
                }

                $lists = array_values($orgsMap);
            } else {
                // Nivel Regional
                $base = request()->getSchemeAndHttpHost();
                $regLevelId = $regLevel ? $regLevel->id : 1;

                $listsQuery = ElectoralList::where('electoral_level_id', $regLevelId)
                    ->whereIn('status', $allowedStatuses)
                    ->with(['politicalOrganization', 'candidacies.candidate']);

                if (!empty($deptCodes)) {
                    $listsQuery->whereIn('department_code', $deptCodes);
                }

                $lists = $listsQuery->get()->map(function ($list) use ($base) {
                    $org = $list->politicalOrganization;
                    $orgLogo = null;
                    if ($org?->local_logo_url) {
                        $orgLogo = $base . '/storage/political-organizationals/' . ltrim($org->local_logo_url, '/');
                    } elseif ($org?->logo_url) {
                        $orgLogo = str_starts_with($org->logo_url, '/storage/') ? ($base . $org->logo_url) : str_replace('http://localhost/storage/', $base . '/storage/', $org->logo_url);
                    }

                    // Encontrar primero al candidato a Gobernador Regional
                    $candidacies = $list->candidacies->sortBy(function ($c) {
                        return ($c->position === 'GOBERNADOR REGIONAL') ? 0 : 1;
                    });

                    return [
                        'electoral_list_id' => $list->id,
                        'political_organization_id' => $list->political_organization_id,
                        'political_organization_name' => $org?->name,
                        'political_organization_short_name' => $org?->short_name,
                        'logo_url' => $orgLogo,
                        'local_logo_url' => $org?->local_logo_url ? ($base . '/storage/political-organizationals/' . ltrim($org->local_logo_url, '/')) : null,
                        'is_provincial_admitted' => true,
                        'is_distrital_admitted' => true,
                        'candidates' => $candidacies->map(function ($c) use ($base) {
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
                        })->values()->all(),
                    ];
                })->all();
            }

            return [
                'station' => [
                    'id' => $station->id,
                    'code' => $station->code,
                    'registered_voters' => $station->registered_voters,
                    'status' => $station->status,
                    'department_code' => $deptCodes[0] ?? null,
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

