<?php

namespace App\Domain\Acts\Services;

use App\Models\Act;
use App\Models\ActResult;
use App\Models\ActTotal;
use App\Models\Election;
use App\Models\ElectoralLevel;
use App\Models\PoliticalOrganization;
use App\Models\PollingStation;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class ResultsAggregationService
{
    /**
     * Cache TTL en segundos (1 minuto)
     */
    protected const CACHE_TTL = 60;

    /**
     * Obtiene el resumen consolidado global o por ubigeo.
     */
    public function getSummary(
        ?int $electionId = null,
        ?string $departmentCode = null,
        ?string $provinceCode = null,
        ?string $districtCode = null
    ): array {
        $cacheKey = "results:summary:{$electionId}:{$departmentCode}:{$provinceCode}:{$districtCode}";

        return Cache::remember($cacheKey, self::CACHE_TTL, function () use (
            $electionId,
            $departmentCode,
            $provinceCode,
            $districtCode
        ) {
            // Consulta base de mesas esperadas
            $stationsQuery = PollingStation::query();
            $this->applyUbigeoFilterToStations($stationsQuery, $departmentCode, $provinceCode, $districtCode);

            $totalStations = (clone $stationsQuery)->count();
            $registeredVoters = (clone $stationsQuery)->sum('registered_voters');

            // Consulta de actas confirmadas
            $actsQuery = Act::query()
                ->whereIn('acts.status', ['CONFIRMED', 'SYNCED'])
                ->join('polling_stations', 'acts.polling_station_id', '=', 'polling_stations.id');

            if ($electionId) {
                $actsQuery->where('acts.election_id', $electionId);
            }

            $this->applyUbigeoFilterToStations($actsQuery, $departmentCode, $provinceCode, $districtCode, 'polling_stations.');

            $processedStationsCount = (clone $actsQuery)->distinct('acts.polling_station_id')->count('acts.polling_station_id');
            $confirmedActsCount     = (clone $actsQuery)->count('acts.id');
            $pendingStations        = max(0, $totalStations - $processedStationsCount);

            // Totales de votos
            $totalsQuery = ActTotal::query()
                ->join('acts', 'act_totals.act_id', '=', 'acts.id')
                ->join('polling_stations', 'acts.polling_station_id', '=', 'polling_stations.id')
                ->whereIn('acts.status', ['CONFIRMED', 'SYNCED']);

            if ($electionId) {
                $totalsQuery->where('acts.election_id', $electionId);
            }
            $this->applyUbigeoFilterToStations($totalsQuery, $departmentCode, $provinceCode, $districtCode, 'polling_stations.');

            $totals = $totalsQuery->selectRaw('
                COALESCE(SUM(act_totals.voters_who_voted), 0) as voters_who_voted,
                COALESCE(SUM(act_totals.total_votes), 0) as total_votes,
                COALESCE(SUM(act_totals.blank_votes), 0) as blank_votes,
                COALESCE(SUM(act_totals.null_votes), 0) as null_votes,
                COALESCE(SUM(act_totals.challenged_votes), 0) as challenged_votes
            ')->first();

            $votersWhoVoted  = (int) ($totals->voters_who_voted ?? 0);
            $totalVotes      = (int) ($totals->total_votes ?? 0);
            $blankVotes      = (int) ($totals->blank_votes ?? 0);
            $nullVotes       = (int) ($totals->null_votes ?? 0);
            $challengedVotes = (int) ($totals->challenged_votes ?? 0);

            // Votos válidos (sumatoria de act_results)
            $validVotesQuery = ActResult::query()
                ->join('acts', 'act_results.act_id', '=', 'acts.id')
                ->join('polling_stations', 'acts.polling_station_id', '=', 'polling_stations.id')
                ->whereIn('acts.status', ['CONFIRMED', 'SYNCED']);

            if ($electionId) {
                $validVotesQuery->where('acts.election_id', $electionId);
            }
            $this->applyUbigeoFilterToStations($validVotesQuery, $departmentCode, $provinceCode, $districtCode, 'polling_stations.');

            $validVotes = (int) $validVotesQuery->sum('act_results.votes');

            // Si no hay act_results explícitos pero hay totalVotes, calculamos válidos como total - no válidos
            if ($validVotes === 0 && $totalVotes > 0) {
                $validVotes = max(0, $totalVotes - ($blankVotes + $nullVotes + $challengedVotes));
            }

            $coveragePercentage = $totalStations > 0
                ? round(($processedStationsCount / $totalStations) * 100, 2)
                : 0.0;

            $participationPercentage = $registeredVoters > 0
                ? round(($votersWhoVoted / $registeredVoters) * 100, 2)
                : 0.0;

            return [
                'total_stations'             => $totalStations,
                'processed_stations'         => $processedStationsCount,
                'pending_stations'           => $pendingStations,
                'confirmed_acts_count'       => $confirmedActsCount,
                'coverage_percentage'        => $coveragePercentage,
                'registered_voters'          => (int) $registeredVoters,
                'voters_who_voted'           => $votersWhoVoted,
                'participation_percentage'   => $participationPercentage,
                'total_votes'                => $totalVotes,
                'valid_votes'                => $validVotes,
                'blank_votes'                => $blankVotes,
                'null_votes'                 => $nullVotes,
                'challenged_votes'           => $challengedVotes,
                'valid_votes_percentage'     => $totalVotes > 0 ? round(($validVotes / $totalVotes) * 100, 2) : 0.0,
                'blank_votes_percentage'     => $totalVotes > 0 ? round(($blankVotes / $totalVotes) * 100, 2) : 0.0,
                'null_votes_percentage'      => $totalVotes > 0 ? round(($nullVotes / $totalVotes) * 100, 2) : 0.0,
                'challenged_votes_percentage'=> $totalVotes > 0 ? round(($challengedVotes / $totalVotes) * 100, 2) : 0.0,
                'updated_at'                 => now()->toIso8601String(),
            ];
        });
    }

    /**
     * Obtiene los resultados desglosados por organización política para una elección y ubigeo.
     */
    public function getElectionResults(
        int $electionId,
        ?int $electoralLevelId = null,
        ?string $departmentCode = null,
        ?string $provinceCode = null,
        ?string $districtCode = null
    ): array {
        $cacheKey = "results:election:{$electionId}:{$electoralLevelId}:{$departmentCode}:{$provinceCode}:{$districtCode}";

        return Cache::remember($cacheKey, self::CACHE_TTL, function () use (
            $electionId,
            $electoralLevelId,
            $departmentCode,
            $provinceCode,
            $districtCode
        ) {
            $base = request()->getSchemeAndHttpHost();
            $summary = $this->getSummary($electionId, $departmentCode, $provinceCode, $districtCode);
            $validVotes = $summary['valid_votes'];
            $totalVotes = $summary['total_votes'];

            // Consulta agregada por organización política
            $resultsQuery = ActResult::query()
                ->select(
                    'act_results.political_organization_id',
                    'political_organizations.name as organization_name',
                    'political_organizations.short_name',
                    'political_organizations.logo_url',
                    DB::raw('COALESCE(SUM(act_results.votes), 0) as total_votes')
                )
                ->join('acts', 'act_results.act_id', '=', 'acts.id')
                ->join('polling_stations', 'acts.polling_station_id', '=', 'polling_stations.id')
                ->join('political_organizations', 'act_results.political_organization_id', '=', 'political_organizations.id')
                ->whereIn('acts.status', ['CONFIRMED', 'SYNCED'])
                ->where('acts.election_id', $electionId);

            if ($electoralLevelId) {
                $resultsQuery->where('acts.electoral_level_id', $electoralLevelId);
            }

            $this->applyUbigeoFilterToStations($resultsQuery, $departmentCode, $provinceCode, $districtCode, 'polling_stations.');

            $orgResults = $resultsQuery
                ->groupBy(
                    'act_results.political_organization_id',
                    'political_organizations.name',
                    'political_organizations.short_name',
                    'political_organizations.logo_url',
                    'political_organizations.local_logo_url'
                )
                ->orderByDesc('total_votes')
                ->get();

            // Si no hay votos todavía pero existen organizaciones para esta elección, devolvemos las organizaciones con 0 votos
            if ($orgResults->isEmpty()) {
                $allOrgs = PoliticalOrganization::all();
                $orgResults = $allOrgs->map(function ($org) use ($base) {
                    $logo = null;
                    if ($org->local_logo_url) {
                        $logo = $base . '/storage/political-organizationals/' . ltrim($org->local_logo_url, '/');
                    } elseif ($org->logo_url) {
                        $logo = str_starts_with($org->logo_url, '/storage/') ? ($base . $org->logo_url) : str_replace('http://localhost/storage/', $base . '/storage/', $org->logo_url);
                    }
                    return (object) [
                        'political_organization_id' => $org->id,
                        'organization_name'         => $org->name,
                        'short_name'                => $org->short_name,
                        'logo_url'                  => $logo,
                        'local_logo_url'            => $org->local_logo_url,
                        'total_votes'               => 0,
                    ];
                });
            }

            // Mapeo O(1) de logos locales de organizaciones
            $localLogos = PoliticalOrganization::pluck('local_logo_url', 'id')->all();

            $ranking = 1;
            $items = $orgResults->map(function ($row) use (&$ranking, $validVotes, $totalVotes, $base, $localLogos) {
                $votes = (int) $row->total_votes;
                $pctValid = $validVotes > 0 ? round(($votes / $validVotes) * 100, 2) : 0.0;
                $pctTotal = $totalVotes > 0 ? round(($votes / $totalVotes) * 100, 2) : 0.0;

                $logoUrl = null;
                $locLogo = $localLogos[$row->political_organization_id] ?? ($row->local_logo_url ?? null);
                if ($locLogo) {
                    $logoUrl = $base . '/storage/political-organizationals/' . ltrim($locLogo, '/');
                } elseif (!empty($row->logo_url)) {
                    $logoUrl = str_starts_with($row->logo_url, '/storage/') ? ($base . $row->logo_url) : str_replace('http://localhost/storage/', $base . '/storage/', $row->logo_url);
                }

                return [
                    'rank'                      => $ranking++,
                    'political_organization_id' => $row->political_organization_id,
                    'organization_name'         => $row->organization_name,
                    'short_name'                => $row->short_name ?? $row->organization_name,
                    'logo_url'                  => $logoUrl,
                    'votes'                     => $votes,
                    'percentage_valid_votes'    => $pctValid,
                    'percentage_total_votes'    => $pctTotal,
                ];
            });

            return [
                'summary'       => $summary,
                'organizations' => $items,
                'non_party_votes' => [
                    'blank_votes'      => $summary['blank_votes'],
                    'blank_percentage' => $summary['blank_votes_percentage'],
                    'null_votes'       => $summary['null_votes'],
                    'null_percentage'  => $summary['null_votes_percentage'],
                    'challenged_votes' => $summary['challenged_votes'],
                    'challenged_pct'   => $summary['challenged_votes_percentage'],
                ],
                'updated_at'    => now()->toIso8601String(),
            ];
        });
    }

    /**
     * Obtiene el desglose de resultados por cada mesa electoral con soporte de filtros.
     */
    public function getTableBreakdown(
        int $electionId,
        ?int $electoralLevelId = null,
        ?string $departmentCode = null,
        ?string $provinceCode = null,
        ?string $districtCode = null,
        int $perPage = 20
    ): array {
        $base = request()->getSchemeAndHttpHost();
        $query = Act::query()
            ->with(['pollingStation.electoralLocation.district.province.department', 'totals', 'results.politicalOrganization', 'evidences'])
            ->whereIn('status', ['CONFIRMED', 'SYNCED'])
            ->where('election_id', $electionId);

        if ($electoralLevelId) {
            $query->where('electoral_level_id', $electoralLevelId);
        }

        if ($departmentCode || $provinceCode || $districtCode) {
            $query->whereHas('pollingStation', function ($stQ) use ($departmentCode, $provinceCode, $districtCode) {
                $this->applyUbigeoFilterToStations($stQ, $departmentCode, $provinceCode, $districtCode);
            });
        }

        $paginated = $query->orderBy('polling_station_id')->paginate($perPage);

        return [
            'meta' => [
                'total_acts'   => $paginated->total(),
                'current_page' => $paginated->currentPage(),
                'last_page'    => $paginated->lastPage(),
                'per_page'     => $paginated->perPage(),
            ],
            'acts' => collect($paginated->items())->map(function ($act) use ($base) {
                return [
                    'act_id'             => $act->id,
                    'polling_station_id' => $act->polling_station_id,
                    'station_code'       => $act->pollingStation?->code,
                    'department'         => $act->pollingStation?->electoralLocation?->district?->province?->department?->name,
                    'province'           => $act->pollingStation?->electoralLocation?->district?->province?->name,
                    'district'           => $act->pollingStation?->electoralLocation?->district?->name,
                    'location_name'      => $act->pollingStation?->electoralLocation?->name,
                    'status'             => $act->status,
                    'totals'             => $act->totals ? [
                        'registered_voters' => $act->totals->registered_voters,
                        'voters_who_voted'  => $act->totals->voters_who_voted,
                        'total_votes'       => $act->totals->total_votes,
                        'blank_votes'       => $act->totals->blank_votes,
                        'null_votes'        => $act->totals->null_votes,
                        'challenged_votes'  => $act->totals->challenged_votes,
                        'is_valid_total'    => (bool) $act->totals->is_valid_total,
                    ] : null,
                    'results' => $act->results->map(function ($res) use ($base) {
                        $org = $res->politicalOrganization;
                        $logoUrl = null;
                        if ($org?->local_logo_url) {
                            $logoUrl = $base . '/storage/political-organizationals/' . ltrim($org->local_logo_url, '/');
                        } elseif ($org?->logo_url) {
                            $logoUrl = str_starts_with($org->logo_url, '/storage/') ? ($base . $org->logo_url) : str_replace('http://localhost/storage/', $base . '/storage/', $org->logo_url);
                        }
                        return [
                            'political_organization_id' => $res->political_organization_id,
                            'organization_name'         => $org?->name,
                            'short_name'                => $org?->short_name,
                            'logo_url'                  => $logoUrl,
                            'votes'                     => $res->votes,
                            'source'                    => $res->source,
                            'confidence'                => $res->confidence,
                        ];
                    }),
                    'evidences' => $act->evidences->map(function ($ev) {
                        return [
                            'id'           => $ev->id,
                            'evidence_type'=> $ev->evidence_type,
                            'file_path'    => $ev->file_path,
                            'file_hash'    => $ev->file_hash,
                            'status'       => $ev->status,
                            'created_at'   => $ev->created_at?->toIso8601String(),
                        ];
                    }),
                ];
            }),
        ];
    }

    /**
     * Obtiene el detalle de resultados de una mesa específica por código.
     */
    public function getStationResults(string $stationCode): ?array
    {
        $station = PollingStation::with([
            'electoralLocation.district.province.department',
        ])->where('code', $stationCode)->first();

        if (!$station) {
            return null;
        }

        $acts = Act::with(['totals', 'results.politicalOrganization', 'evidences', 'capturedByPersonero.user'])
            ->where('polling_station_id', $station->id)
            ->get();

        return [
            'polling_station' => [
                'id'                => $station->id,
                'code'              => $station->code,
                'registered_voters' => $station->registered_voters,
                'odpe'              => $station->odpe,
                'department_name'   => $station->department_name ?? $station->electoralLocation?->district?->province?->department?->name,
                'province_name'     => $station->province_name ?? $station->electoralLocation?->district?->province?->name,
                'district_name'     => $station->district_name ?? $station->electoralLocation?->district?->name,
                'location_name'     => $station->electoralLocation?->name ?? 'LOCAL DE VOTACIÓN',
                'status'            => $station->status,
            ],
            'acts' => $acts->map(function ($act) {
                return [
                    'id'                 => $act->id,
                    'act_code'           => $act->act_code,
                    'election_id'        => $act->election_id,
                    'electoral_level_id' => $act->electoral_level_id,
                    'status'             => $act->status,
                    'captured_at'        => $act->captured_at?->toIso8601String(),
                    'confirmed_at'       => $act->confirmed_at?->toIso8601String(),
                    'totals'             => $act->totals ? [
                        'registered_voters' => $act->totals->registered_voters,
                        'voters_who_voted'  => $act->totals->voters_who_voted,
                        'total_votes'       => $act->totals->total_votes,
                        'blank_votes'       => $act->totals->blank_votes,
                        'null_votes'        => $act->totals->null_votes,
                        'challenged_votes'  => $act->totals->challenged_votes,
                        'is_valid_total'    => (bool) $act->totals->is_valid_total,
                    ] : null,
                    'results' => $act->results->map(function ($res) {
                        return [
                            'political_organization_id' => $res->political_organization_id,
                            'organization_name'         => $res->politicalOrganization?->name,
                            'short_name'                => $res->politicalOrganization?->short_name,
                            'logo_url'                  => $res->politicalOrganization?->logo_url,
                            'votes'                     => $res->votes,
                            'source'                    => $res->source,
                            'confidence'                => $res->confidence,
                        ];
                    }),
                    'evidences' => $act->evidences->map(function ($ev) {
                        return [
                            'id'           => $ev->id,
                            'evidence_type'=> $ev->evidence_type,
                            'file_path'    => $ev->file_path,
                            'file_hash'    => $ev->file_hash,
                            'status'       => $ev->status,
                            'created_at'   => $ev->created_at?->toIso8601String(),
                        ];
                    }),
                ];
            }),
        ];
    }

    /**
     * Invalida la caché de agregaciones electorales.
     */
    public function invalidateCache(): void
    {
        try {
            Cache::flush();
        } catch (\Throwable $e) {
            // Ignorar fallas silenciosas en drivers sin flush
        }
    }

    /**
     * Aplica filtros de ubigeo a una consulta de mesas electorales.
     */
    protected function applyUbigeoFilterToStations(
        $query,
        ?string $departmentCode,
        ?string $provinceCode,
        ?string $districtCode,
        string $prefix = ''
    ): void {
        if ($districtCode) {
            $like = config('database.default') === 'pgsql' ? 'ILIKE' : 'LIKE';
            $query->where(function ($q) use ($districtCode, $prefix, $like) {
                $q->where("{$prefix}district_name", $like, "%{$districtCode}%")
                  ->orWhereHas('electoralLocation.district', function ($sub) use ($districtCode) {
                      $sub->where('code', $districtCode)->orWhere('name', 'LIKE', "%{$districtCode}%");
                  });
            });
        } elseif ($provinceCode) {
            $like = config('database.default') === 'pgsql' ? 'ILIKE' : 'LIKE';
            $query->where(function ($q) use ($provinceCode, $prefix, $like) {
                $q->where("{$prefix}province_name", $like, "%{$provinceCode}%")
                  ->orWhereHas('electoralLocation.district.province', function ($sub) use ($provinceCode) {
                      $sub->where('code', $provinceCode)->orWhere('name', 'LIKE', "%{$provinceCode}%");
                  });
            });
        } elseif ($departmentCode) {
            $like = config('database.default') === 'pgsql' ? 'ILIKE' : 'LIKE';
            $query->where(function ($q) use ($departmentCode, $prefix, $like) {
                $q->where("{$prefix}department_name", $like, "%{$departmentCode}%")
                  ->orWhereHas('electoralLocation.district.province.department', function ($sub) use ($departmentCode) {
                      $sub->where('code', $departmentCode)->orWhere('name', 'LIKE', "%{$departmentCode}%");
                  });
            });
        }
    }
}
