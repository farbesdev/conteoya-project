<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Candidate;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

/**
 * @tags Candidatos
 */
class CandidateController extends Controller
{
    /**
     * Listar y Buscar Candidatos Electorales
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->input('per_page', 15), 100);
        if ($perPage < 1) {
            $perPage = 15;
        }

        $query = Candidate::with([
            'candidacies.electoralList.politicalOrganization',
            'candidacies.electoralList.electoralLevel',
            'candidacies.electoralList.department',
            'candidacies.electoralList.province',
            'candidacies.electoralList.district',
        ]);

        if ($search = $request->input('search')) {
            $search = trim($search);
            $like = config('database.default') === 'pgsql' ? 'ILIKE' : 'LIKE';
            $query->where(function ($q) use ($search, $like) {
                $q->where('full_name', $like, "%{$search}%")
                  ->orWhere('document_number', $like, "%{$search}%")
                  ->orWhereHas('candidacies', function ($cQ) use ($search, $like) {
                      $cQ->where('position', $like, "%{$search}%")
                         ->orWhereHas('electoralList.politicalOrganization', function ($poQ) use ($search, $like) {
                             $poQ->where('name', $like, "%{$search}%")
                                 ->orWhere('short_name', $like, "%{$search}%");
                         });
                  });
            });
        }

        $paginated = $query->orderBy('id')->paginate($perPage);

        $base = request()->getSchemeAndHttpHost();

        // Mapa de organizaciones políticas en caché para resolución garantizada O(1)
        $orgMap = Cache::remember('candidate_political_org_logos_map', 3600, function () use ($base) {
            return \App\Models\PoliticalOrganization::all()->mapWithKeys(function ($org) use ($base) {
                $logo = null;
                if ($org->local_logo_url) {
                    $logo = $base . '/storage/political-organizationals/' . $org->local_logo_url;
                } elseif ($org->logo_url) {
                    if (str_starts_with($org->logo_url, 'http://localhost/storage/')) {
                        $logo = str_replace('http://localhost/storage/', $base . '/storage/', $org->logo_url);
                    } else {
                        $logo = $org->logo_url;
                    }
                }

                $key = mb_strtoupper(trim($org->name), 'UTF-8');
                return [
                    $org->id => [
                        'id'         => $org->id,
                        'name'       => $org->name,
                        'short_name' => $org->short_name,
                        'logo_url'   => $logo,
                    ],
                    $key => [
                        'id'         => $org->id,
                        'name'       => $org->name,
                        'short_name' => $org->short_name,
                        'logo_url'   => $logo,
                    ],
                ];
            })->all();
        });

        $items = collect($paginated->items())->map(function ($c) use ($base, $orgMap) {
            $candidacy = $c->candidacies->first();
            $list = $candidacy?->electoralList;
            $org = $list?->politicalOrganization;
            $level = $list?->electoralLevel;

            // Resolver URL de foto de candidato
            $photoUrl = $c->photo_url ?: $c->local_photo_url;
            if ($photoUrl && str_starts_with($photoUrl, '/storage/')) {
                $photoUrl = $base . $photoUrl;
            }

            // Resolver Organización Política y Logo
            $orgName = $org?->name;
            $orgShortName = $org?->short_name;
            $orgLogo = null;

            if ($org) {
                if ($org->local_logo_url) {
                    $orgLogo = $base . '/storage/political-organizationals/' . $org->local_logo_url;
                } elseif ($org->logo_url) {
                    $orgLogo = str_starts_with($org->logo_url, 'http://localhost/storage/')
                        ? str_replace('http://localhost/storage/', $base . '/storage/', $org->logo_url)
                        : $org->logo_url;
                }
            } elseif ($list && $list->political_organization_id && isset($orgMap[$list->political_organization_id])) {
                $cached = $orgMap[$list->political_organization_id];
                $orgName = $cached['name'];
                $orgShortName = $cached['short_name'];
                $orgLogo = $cached['logo_url'];
            }

            $position = $candidacy?->position ?: 'CANDIDATO';
            $status = $list?->status ?: 'INSCRITO';
            $cvUrl = $c->id_hoja_vida ? "https://declara.jne.gob.pe/HojaVida/HojaVida?idHojaVida={$c->id_hoja_vida}" : null;
            $votoInformadoUrl = $c->id_hoja_vida ? "https://votoinformado.jne.gob.pe/voto/hoja-de-vida/{$c->id_hoja_vida}" : null;

            return [
                'id'                      => $c->id,
                'document_number'         => $c->document_number,
                'dni'                     => $c->document_number,
                'full_name'               => $c->full_name,
                'name'                    => $c->full_name,
                'photo_url'               => $photoUrl,
                'local_photo_url'         => $c->local_photo_url,
                'id_hoja_vida'            => $c->id_hoja_vida,
                'cv_url'                  => $cvUrl,
                'voto_informado_url'      => $votoInformadoUrl,
                'position'                => $position,
                'status'                  => strtoupper($status),
                'list_number'             => $candidacy?->list_number,
                'political_org_name'      => $orgName ?? 'Organización Política',
                'political_org_short_name'=> $orgShortName,
                'political_org_logo'      => $orgLogo,
                'electoral_level_name'    => $level?->name ?? 'Regional / Municipal',
                'department_name'         => $list?->department?->name,
                'province_name'           => $list?->province?->name,
                'district_name'           => $list?->district?->name,
            ];
        });

        return response()->json([
            'message' => 'Lista de candidatos obtenida exitosamente.',
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
     * Ver Detalle de Candidato
     */
    public function show(int $id): JsonResponse
    {
        $c = Candidate::with([
            'candidacies.electoralList.politicalOrganization',
            'candidacies.electoralList.electoralLevel',
            'candidacies.electoralList.department',
            'candidacies.electoralList.province',
            'candidacies.electoralList.district',
            'cv',
        ])->findOrFail($id);

        $base = request()->getSchemeAndHttpHost();
        $candidacy = $c->candidacies->first();
        $list = $candidacy?->electoralList;
        $org = $list?->politicalOrganization;
        $level = $list?->electoralLevel;

        $photoUrl = $c->photo_url ?: $c->local_photo_url;
        if ($photoUrl && str_starts_with($photoUrl, '/storage/')) {
            $photoUrl = $base . $photoUrl;
        }

        $orgLogo = null;
        if ($org) {
            if ($org->local_logo_url) {
                $orgLogo = $base . '/storage/political-organizationals/' . $org->local_logo_url;
            } elseif ($org->logo_url) {
                $orgLogo = str_starts_with($org->logo_url, 'http://localhost/storage/')
                    ? str_replace('http://localhost/storage/', $base . '/storage/', $org->logo_url)
                    : $org->logo_url;
            }
        }

        $position = $candidacy?->position ?: 'CANDIDATO';
        $status = $list?->status ?: 'INSCRITO';
        $cvUrl = $c->id_hoja_vida ? "https://declara.jne.gob.pe/HojaVida/HojaVida?idHojaVida={$c->id_hoja_vida}" : null;
        $votoInformadoUrl = $c->id_hoja_vida ? "https://votoinformado.jne.gob.pe/voto/hoja-de-vida/{$c->id_hoja_vida}" : null;

        return response()->json([
            'message' => 'Ficha de candidato obtenida exitosamente.',
            'data'    => [
                'id'                      => $c->id,
                'document_number'         => $c->document_number,
                'dni'                     => $c->document_number,
                'full_name'               => $c->full_name,
                'name'                    => $c->full_name,
                'photo_url'               => $photoUrl,
                'local_photo_url'         => $c->local_photo_url,
                'id_hoja_vida'            => $c->id_hoja_vida,
                'cv_url'                  => $cvUrl,
                'voto_informado_url'      => $votoInformadoUrl,
                'cv_data'                 => $c->cv,
                'position'                => $position,
                'status'                  => strtoupper($status),
                'list_number'             => $candidacy?->list_number,
                'political_org_name'      => $org?->name ?? 'Organización Política',
                'political_org_short_name'=> $org?->short_name,
                'political_org_logo'      => $orgLogo,
                'electoral_level_name'    => $level?->name ?? 'Regional / Municipal',
                'department_name'         => $list?->department?->name,
                'province_name'           => $list?->province?->name,
                'district_name'           => $list?->district?->name,
            ],
        ]);
    }

    /**
     * Crear Candidato
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'document_number' => 'required|string|max:12',
            'full_name'       => 'required|string|max:200',
            'photo_url'       => 'nullable|string|max:500',
            'position'        => 'nullable|string|max:150',
            'id_hoja_vida'    => 'nullable|string|max:50',
        ]);

        $candidate = Candidate::create([
            'document_number' => trim($request->input('document_number')),
            'full_name'       => trim($request->input('full_name')),
            'photo_url'       => $request->input('photo_url'),
            'id_hoja_vida'    => $request->input('id_hoja_vida'),
        ]);

        return response()->json([
            'message' => 'Candidato registrado exitosamente.',
            'data'    => $candidate,
        ], 201);
    }

    /**
     * Actualizar Candidato
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $candidate = Candidate::findOrFail($id);

        $request->validate([
            'full_name'       => 'nullable|string|max:200',
            'photo_url'       => 'nullable|string|max:500',
            'id_hoja_vida'    => 'nullable|string|max:50',
        ]);

        $candidate->update(array_filter([
            'full_name'    => $request->input('full_name', $candidate->full_name),
            'photo_url'    => $request->input('photo_url', $candidate->photo_url),
            'id_hoja_vida' => $request->input('id_hoja_vida', $candidate->id_hoja_vida),
        ], fn ($v) => !is_null($v)));

        return response()->json([
            'message' => 'Candidato actualizado exitosamente.',
            'data'    => $candidate,
        ]);
    }

    /**
     * Eliminar Candidato
     */
    public function destroy(int $id): JsonResponse
    {
        $candidate = Candidate::findOrFail($id);
        $candidate->candidacies()->delete();
        $candidate->delete();

        return response()->json([
            'message' => 'Candidato eliminado exitosamente del sistema.',
        ]);
    }
}
