<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Personero;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * @tags Personeros
 */
class PersoneroController extends Controller
{
    /**
     * Listar y Buscar Personeros (Paginación y Filtros para Admin / Director)
     *
     * Permite consultar y buscar personeros con paginación de alto rendimiento.
     * Soporta filtrado por DNI, nombres, apellidos, mesa o partido político.
     *
     * @queryParam search string Término de búsqueda (DNI, nombres, apellidos, mesa o partido). Example: 12345678
     * @queryParam per_page int Cantidad de elementos por página (default 15, max 50). Example: 15
     * @queryParam page int Número de página. Example: 1
     */
    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->input('per_page', 15), 50);
        if ($perPage < 1) {
            $perPage = 15;
        }

        $query = Personero::with(['user', 'pollingStations', 'politicalOrganization']);

        if ($search = $request->input('search')) {
            $search = trim($search);
            $like = config('database.default') === 'pgsql' ? 'ILIKE' : 'LIKE';
            $words = array_filter(explode(' ', $search));

            $query->where(function ($q) use ($search, $words, $like) {
                // Coincidencia de frase completa
                $q->where('document_number', $like, "%{$search}%")
                  ->orWhere('full_name', $like, "%{$search}%")
                  ->orWhere('first_name', $like, "%{$search}%")
                  ->orWhere('political_organization_name', $like, "%{$search}%")
                  ->orWhere('email', $like, "%{$search}%")
                  ->orWhere('abogado_responsable', $like, "%{$search}%")
                  ->orWhere('personero_type', $like, "%{$search}%")
                  ->orWhere('jee_name', $like, "%{$search}%")
                  ->orWhere('department_name', $like, "%{$search}%")
                  ->orWhere('province_name', $like, "%{$search}%")
                  ->orWhere('district_name', $like, "%{$search}%")
                  ->orWhereHas('pollingStations', function ($pQ) use ($search, $like) {
                      $pQ->where('code', $like, "%{$search}%");
                  })
                  ->orWhereHas('user', function ($uQ) use ($search, $like) {
                      $uQ->where('name', $like, "%{$search}%")
                         ->orWhere('email', $like, "%{$search}%");
                  });

                // Si hay múltiples palabras, también verificar que cada palabra coincida en al menos un campo relevante
                if (count($words) > 1) {
                    $q->orWhere(function ($subQ) use ($words, $like) {
                        foreach ($words as $word) {
                            $subQ->where(function ($wQ) use ($word, $like) {
                                $wQ->where('full_name', $like, "%{$word}%")
                                   ->orWhere('first_name', $like, "%{$word}%")
                                   ->orWhere('email', $like, "%{$word}%")
                                   ->orWhere('document_number', $like, "%{$word}%")
                                   ->orWhereHas('user', function ($uQ) use ($word, $like) {
                                       $uQ->where('name', $like, "%{$word}%");
                                   });
                            });
                        }
                    });
                }
            });
        }

        $paginated = $query->orderBy('id')->paginate($perPage);

        $items = collect($paginated->items())->map(function ($p) {
            $stationCodes = $p->pollingStations->pluck('code')->filter()->values()->all();
            $stationCode = $stationCodes[0] ?? '030390';
            $fullName = $p->full_name ?: ($p->user?->name ?? 'Personero Registrado');
            $parts = explode(' ', trim($fullName));
            $firstName = $p->first_name ?: ($parts[0] ?? 'Personero');
            $lastName = count($parts) > 1 ? implode(' ', array_slice($parts, 1)) : ' ';

            return [
                'id'                          => $p->id,
                'user_id'                     => $p->user_id,
                'dni'                         => $p->document_number,
                'first_name'                  => $firstName,
                'last_name'                   => $lastName,
                'name'                        => $fullName,
                'full_name'                   => $fullName,
                'polling_station_code'        => $stationCode,
                'polling_station_codes'       => $stationCodes,
                'phone_number'                => $p->phone_number,
                'email'                       => $p->email ?: $p->user?->email,
                'is_active'                   => $p->user?->is_active ?? false,
                'status'                      => $p->status ?? 'RECONOCIDO',
                'personero_type'              => $p->personero_type,
                'political_organization_name' => $p->political_organization_name,
                'jee_name'                    => $p->jee_name,
                'department_name'             => $p->department_name,
                'province_name'               => $p->province_name,
                'district_name'               => $p->district_name,
            ];
        });

        return response()->json([
            'message' => 'Lista paginada de personeros obtenida exitosamente.',
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
     * Obtener mesas asignadas al personero autenticado.
     */
    public function pollingStations(Request $request): JsonResponse
    {
        $user = $request->user();
        $personero = $user->personero;

        if (!$personero) {
            return response()->json(['message' => 'El usuario no tiene un perfil de personero asignado.'], 403);
        }

        $stations = $personero->pollingStations()->with('electoralLocation.district')->get();

        return response()->json([
            'personero_id'     => $personero->id,
            'document_number'  => $personero->document_number,
            'polling_stations' => $stations,
        ]);
    }

    /**
     * Asignar / sincronizar múltiples mesas de votación a un personero.
     */
    public function assignPollingStations(Request $request, int $id): JsonResponse
    {
        $personero = Personero::findOrFail($id);
        $stationCodes = $request->input('polling_station_codes', []);
        if (empty($stationCodes) && $request->filled('polling_station_code')) {
            $stationCodes = [$request->input('polling_station_code')];
        }

        $stationIds = \App\Models\PollingStation::whereIn('code', $stationCodes)->pluck('id')->all();
        $personero->pollingStations()->sync($stationIds);

        return response()->json([
            'message'               => 'Mesas asignadas exitosamente al personero.',
            'personero_id'          => $personero->id,
            'polling_station_codes' => $stationCodes,
            'assigned_count'        => count($stationIds),
        ]);
    }

    /**
     * Ver Ficha Detallada de Personero
     */
    public function show(int|string $id): JsonResponse
    {
        $personero = is_numeric($id)
            ? Personero::with(['user', 'pollingStations.electoralLocation.district.province.department', 'politicalOrganization'])->find($id)
            : Personero::with(['user', 'pollingStations.electoralLocation.district.province.department', 'politicalOrganization'])->where('document_number', $id)->first();

        if (!$personero) {
            return response()->json(['message' => 'Personero no encontrado.'], 404);
        }

        $stationCodes = $personero->pollingStations->pluck('code')->filter()->values()->all();
        $fullName = $personero->full_name ?: ($personero->user?->name ?? 'Personero Registrado');
        $parts = explode(' ', trim($fullName));
        $firstName = $personero->first_name ?: ($parts[0] ?? 'Personero');
        $lastName = count($parts) > 1 ? implode(' ', array_slice($parts, 1)) : ' ';

        return response()->json([
            'message' => 'Ficha de personero obtenida exitosamente.',
            'data'    => [
                'id'                          => $personero->id,
                'user_id'                     => $personero->user_id,
                'document_number'             => $personero->document_number,
                'dni'                         => $personero->document_number,
                'first_name'                  => $firstName,
                'last_name'                   => $lastName,
                'full_name'                   => $fullName,
                'name'                        => $fullName,
                'phone_number'                => $personero->phone_number,
                'email'                       => $personero->email ?: $personero->user?->email,
                'political_organization_name' => $personero->political_organization_name,
                'political_org_name'          => $personero->political_organization_name,
                'personero_type'              => $personero->personero_type,
                'abogado_responsable'         => $personero->abogado_responsable,
                'jee_name'                    => $personero->jee_name,
                'department_name'             => $personero->department_name,
                'province_name'               => $personero->province_name,
                'district_name'               => $personero->district_name,
                'is_active'                   => $personero->user?->is_active ?? true,
                'status'                      => $personero->status ?? 'RECONOCIDO',
                'assigned_polling_stations'   => $personero->pollingStations,
                'polling_station_codes'       => $stationCodes,
            ],
        ]);
    }

    /**
     * Crear nuevo personero
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'document_number' => 'required|string|min:8|max:12',
            'first_name'      => 'nullable|string|max:100',
            'last_name'       => 'nullable|string|max:100',
            'name'            => 'nullable|string|max:200',
            'email'           => 'nullable|email|max:150',
            'phone_number'    => 'nullable|string|max:30',
            'political_org_name' => 'nullable|string|max:200',
            'polling_station_codes' => 'nullable|array',
            'polling_station_ids'   => 'nullable|array',
        ]);

        $doc = trim($request->input('document_number'));
        $name = trim($request->input('name') ?: trim($request->input('first_name', '') . ' ' . $request->input('last_name', '')));
        if (empty($name)) {
            $name = "Personero {$doc}";
        }
        $email = trim($request->input('email') ?: "personero_{$doc}@conteoya.pe");

        $personero = \Illuminate\Support\Facades\DB::transaction(function () use ($request, $doc, $name, $email) {
            $role = \App\Models\Role::where('name', 'PERSONERO')->first();

            $user = \App\Models\User::firstOrCreate(
                ['email' => $email],
                [
                    'name'      => $name,
                    'password'  => \Illuminate\Support\Facades\Hash::make('Personero123!'),
                    'role'      => 'PERSONERO',
                    'role_id'   => $role ? $role->id : 3,
                    'is_active' => true,
                ]
            );

            $personero = Personero::updateOrCreate(
                ['document_number' => $doc],
                [
                    'user_id'                     => $user->id,
                    'first_name'                  => $request->input('first_name', $name),
                    'last_name_paternal'          => $request->input('last_name', ''),
                    'full_name'                   => $name,
                    'phone_number'                => $request->input('phone_number'),
                    'email'                       => $email,
                    'political_organization_name' => $request->input('political_org_name') ?: $request->input('political_organization_name'),
                    'status'                      => 'RECONOCIDO',
                ]
            );

            // Asignar mesas
            $stationIds = [];
            if ($request->filled('polling_station_ids')) {
                $stationIds = $request->input('polling_station_ids');
            } elseif ($request->filled('polling_station_codes')) {
                $stationIds = \App\Models\PollingStation::whereIn('code', $request->input('polling_station_codes'))->pluck('id')->all();
            }
            if (!empty($stationIds)) {
                $personero->pollingStations()->sync($stationIds);
            }

            return $personero;
        });

        return response()->json([
            'message' => 'Personero registrado exitosamente.',
            'data'    => $personero->load(['user', 'pollingStations']),
        ], 201);
    }

    /**
     * Actualizar datos del personero
     */
    public function update(Request $request, int|string $id): JsonResponse
    {
        $personero = is_numeric($id)
            ? Personero::find($id)
            : Personero::where('document_number', $id)->first();

        if (!$personero) {
            return response()->json(['message' => 'Personero no encontrado.'], 404);
        }

        $request->validate([
            'first_name'         => 'nullable|string|max:100',
            'last_name'          => 'nullable|string|max:100',
            'name'               => 'nullable|string|max:200',
            'phone_number'       => 'nullable|string|max:30',
            'email'              => 'nullable|email|max:150',
            'political_org_name' => 'nullable|string|max:200',
            'polling_station_ids' => 'nullable|array',
            'polling_station_codes' => 'nullable|array',
            'is_active'          => 'nullable|boolean',
        ]);

        \Illuminate\Support\Facades\DB::transaction(function () use ($request, $personero) {
            $name = trim($request->input('name') ?: trim($request->input('first_name', '') . ' ' . $request->input('last_name', '')));

            $personero->update(array_filter([
                'first_name'                  => $request->input('first_name'),
                'last_name_paternal'          => $request->input('last_name'),
                'full_name'                   => $name ?: $personero->full_name,
                'phone_number'                => $request->input('phone_number', $personero->phone_number),
                'email'                       => $request->input('email', $personero->email),
                'political_organization_name' => $request->input('political_org_name') ?: $request->input('political_organization_name', $personero->political_organization_name),
            ], fn ($v) => !is_null($v)));

            if ($request->filled('polling_station_ids')) {
                $personero->pollingStations()->sync($request->input('polling_station_ids'));
            } elseif ($request->filled('polling_station_codes')) {
                $stationIds = \App\Models\PollingStation::whereIn('code', $request->input('polling_station_codes'))->pluck('id')->all();
                $personero->pollingStations()->sync($stationIds);
            }

            if ($personero->user) {
                $personero->user->update(array_filter([
                    'name'      => $name ?: $personero->user->name,
                    'email'     => $request->input('email', $personero->user->email),
                    'is_active' => $request->has('is_active') ? $request->boolean('is_active') : $personero->user->is_active,
                ], fn ($v) => !is_null($v)));
            }
        });

        return response()->json([
            'message' => 'Personero actualizado exitosamente.',
            'data'    => $personero->fresh()->load(['user', 'pollingStations']),
        ]);
    }

    /**
     * Eliminar personero
     *
     * Elimina el perfil de personero, sus asignaciones de mesas y su cuenta de usuario asociada.
     *
     * @response 200 { "message": "Personero eliminado exitosamente del sistema." }
     * @response 404 { "message": "Personero no encontrado." }
     */
    public function destroy(int|string $id): JsonResponse
    {
        $personero = is_numeric($id)
            ? Personero::find($id)
            : Personero::where('document_number', $id)->first();

        if (!$personero) {
            return response()->json(['message' => 'Personero no encontrado.'], 404);
        }

        \Illuminate\Support\Facades\DB::transaction(function () use ($personero) {
            $personero->pollingStations()->detach();
            \App\Models\SyncOperation::where('personero_id', $personero->id)->update(['personero_id' => null]);
            \App\Models\Device::where('personero_id', $personero->id)->delete();

            $user = $personero->user;
            $personero->delete();

            if ($user) {
                $user->tokens()->delete();
                $user->delete();
            }
        });

        return response()->json([
            'message' => 'Personero eliminado exitosamente del sistema.',
        ]);
    }
}

