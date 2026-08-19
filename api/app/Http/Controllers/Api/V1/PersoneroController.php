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
            $query->where(function ($q) use ($search) {
                // 1. Coincidencia directa por DNI o código de mesa asignada
                $q->where('document_number', 'LIKE', "%{$search}%")
                  ->orWhereHas('pollingStations', function ($pQ) use ($search) {
                      $pQ->where('code', 'LIKE', "%{$search}%");
                  })
                  // 2. Búsqueda insensible agnóstica en campos de personero
                  ->orWhereAnyInsensitive([
                      'full_name',
                      'first_name',
                      'political_organization_name',
                      'email',
                      'abogado_responsable',
                      'personero_type',
                      'jee_name',
                      'department_name',
                      'province_name',
                      'district_name',
                  ], $search)
                  // 3. Búsqueda en relación de usuario
                  ->orWhereHas('user', function ($uQ) use ($search) {
                      $uQ->whereAnyInsensitive(['name', 'email'], $search);
                  });
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
}

