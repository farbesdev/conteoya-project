<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Acts\SyncService;
use App\Http\Controllers\Controller;
use App\Http\Requests\SyncOperationRequest;
use App\Http\Resources\SyncOperationResource;
use App\Models\Device;
use App\Models\SyncOperation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

/**
 * @tags Motor de Sincronización (Offline-First)
 */
class SyncController extends Controller
{
    public function __construct(
        protected SyncService $syncService
    ) {}

    /**
     * Sincronizar Operaciones en Lote (Sync Engine Endpoint)
     *
     * Recibe un lote de operaciones generadas offline por el cliente móvil (`SyncOperation`).
     * Cada operación posee un `client_operation_id` (UUID) para garantizar idempotencia.
     * Si la operación ya fue procesada anteriormente, se devuelve el estado previo sin duplicar.
     */
    public function sync(SyncOperationRequest $request): JsonResponse
    {
        $user = $request->user();
        if (!$user->isPersonero() && !$user->isAdmin() && !$user->isDirector()) {
            return response()->json(['message' => 'No autorizado para sincronizar operaciones.'], 403);
        }

        $operations = $request->input('operations', []);
        $filteredOperations = [];
        $unauthorizedResults = [];

        // El PERSONERO solo puede sincronizar datos de actas y evidencias ('acts', 'act_evidence')
        // EL ADMIN y DIRECTOR pueden sincronizar cualquier entidad
        if ($user->isPersonero()) {
            foreach ($operations as $op) {
                $type = $op['entity_type'] ?? '';
                if (in_array($type, ['acts', 'act_evidence'])) {
                    $filteredOperations[] = $op;
                } else {
                    $unauthorizedResults[] = [
                        'client_operation_id' => $op['client_operation_id'] ?? null,
                        'status'              => 'FAILED',
                        'error'               => "El rol PERSONERO solo está autorizado para sincronizar actas y evidencias.",
                    ];
                }
            }
        } else {
            $filteredOperations = $operations;
        }

        $personero = $user->personero;

        $device = null;
        if ($request->has('device_uuid')) {
            $device = Device::where('device_uuid', $request->input('device_uuid'))->first();
        }

        $results = $this->syncService->processBatch(
            personero: $personero,
            device: $device,
            operations: $filteredOperations
        );

        $finalResults = array_merge($unauthorizedResults, $results);

        return response()->json([
            'message' => 'Lote de operaciones de sincronización procesado.',
            'data'    => $finalResults,
        ]);
    }

    /**
     * Sincronización Descendente (Pull / Downstream Sync)
     *
     * Devuelve las mesas, personeros y catálogos autorizados para la base de datos local SQLite (app_database.dart).
     */
    public function pull(Request $request): JsonResponse
    {
        $user = $request->user();

        // Construir clave de caché por usuario + filtros activos para granularidad correcta
        $filterKey = implode('_', array_filter([
            $request->query('department_code', ''),
            $request->query('province_code', ''),
            $request->query('district_code', ''),
            $request->query('search', ''),
        ]));
        $cacheKey = "sync:pull:u{$user->id}:{$filterKey}";

        // Si el cliente envía X-Force-Refresh: 1 (pull manual), se invalida la caché.
        if ($request->header('X-Force-Refresh') === '1') {
            try {
                Cache::forget($cacheKey);
            } catch (\Throwable) {
                // Redis no disponible — continuar sin error
            }
        }

        // Construir el payload (con caché Redis si está disponible, sin ella si no lo está)
        $buildPayload = function () use ($user, $request) {
            // 1. Mesas — LEFT JOINs para que mesas con electoral_location_id=NULL
            //    también sean devueltas (caso real: JEE seeds sin relación configurada)
            $pollingStationsQuery = DB::table('polling_stations')
                ->leftJoin('electoral_locations', 'polling_stations.electoral_location_id', '=', 'electoral_locations.id')
                ->leftJoin('districts', 'electoral_locations.district_code', '=', 'districts.code')
                ->leftJoin('provinces', 'districts.province_code', '=', 'provinces.code')
                ->leftJoin('departments', 'districts.department_code', '=', 'departments.code')
                ->select([
                    'polling_stations.id',
                    'polling_stations.code',
                    DB::raw("COALESCE(electoral_locations.name, '') as location_name"),
                    DB::raw("COALESCE(electoral_locations.address, '') as address"),
                    DB::raw("COALESCE(districts.code, '') as district_code"),
                    DB::raw("COALESCE(districts.name, '') as district_name"),
                    DB::raw("COALESCE(provinces.name, '') as province_name"),
                    DB::raw("COALESCE(departments.name, '') as department_name"),
                    'polling_stations.registered_voters',
                    'polling_stations.status',
                ]);

            if ($user->role === 'PERSONERO' && $user->personero) {
                // Personero: solo sus mesas asignadas (generalmente 1-5 mesas — payload < 5 KB)
                $stationIds = $user->personero->pollingStations()->pluck('polling_stations.id');
                $pollingStationsQuery->whereIn('polling_stations.id', $stationIds);
            } else {
                // Admin / Director: filtros geográficos opcionales
                if ($request->filled('department_code')) {
                    $pollingStationsQuery->where('departments.code', $request->query('department_code'));
                }
                if ($request->filled('province_code')) {
                    $pollingStationsQuery->where('provinces.code', $request->query('province_code'));
                }
                if ($request->filled('district_code')) {
                    $pollingStationsQuery->where('districts.code', $request->query('district_code'));
                }
                if ($request->filled('search')) {
                    $search = $request->query('search');
                    $pollingStationsQuery->where(function ($q) use ($search) {
                        $q->where('polling_stations.code', 'like', "%{$search}%")
                          ->orWhere('electoral_locations.name', 'like', "%{$search}%");
                    });
                }

                // Límite reducido a 200 por defecto (máximo 2000) para no saturar el VPS.
                // El cliente puede enviar ?limit=500&department_code=10 para ampliar.
                $limit = (int) $request->query('limit', 200);
                $limit = min(max($limit, 1), 2000);
                $pollingStationsQuery->limit($limit);
            }

            $pollingStations = $pollingStationsQuery->orderBy('polling_stations.code')->get();

            // 2. Personeros
            $personerosQuery = \App\Models\Personero::with(['user', 'pollingStations']);
            if ($user->role === 'PERSONERO' && $user->personero) {
                $personerosQuery->where('id', $user->personero->id);
            }

            $personeros = $personerosQuery->get()->map(function ($p) {
                $stationCode = $p->pollingStations->first()?->code ?? '';
                $fullName = $p->user?->name ?? 'Personero Registrado';
                $parts = explode(' ', trim($fullName));
                $firstName = $parts[0] ?? 'Personero';
                $lastName = count($parts) > 1 ? implode(' ', array_slice($parts, 1)) : ' ';

                return [
                    'id'                   => $p->id,
                    'dni'                  => $p->document_number,
                    'first_name'           => $firstName,
                    'last_name'            => $lastName,
                    'name'                 => $fullName,
                    'polling_station_code' => $stationCode,
                    'phone_number'         => $p->phone_number,
                    'email'                => $p->user?->email,
                ];
            });

            // 3. Organizaciones políticas
            $organizations = \App\Models\PoliticalOrganization::orderBy('name')->get()->map(function ($org) {
                return [
                    'id'          => $org->id,
                    'code'        => $org->code,
                    'name'        => $org->name,
                    'short_name'  => $org->short_name,
                    'logo_url'    => $org->logo_url,
                    'order_index' => $org->order_index ?? 0,
                ];
            });

            return [
                'polling_stations'        => $pollingStations,
                'personeros'              => $personeros,
                'political_organizations' => $organizations,
                'server_time'             => now()->toIso8601String(),
            ];
        };

        // Intentar usar Redis como caché (TTL 120s). Si Redis no está disponible,
        // ejecutar la query directamente sin caché para no lanzar HTTP 500.
        try {
            $payload = Cache::remember($cacheKey, 120, $buildPayload);
        } catch (\Throwable) {
            // Redis no disponible en el VPS — fallback a consulta directa
            $payload = $buildPayload();
        }

        return response()->json([
            'message' => 'Sincronización descendente completada.',
            'data'    => $payload,
        ]);
    }

    /**
     * Consultar Estado de Sincronización
     *
     * Devuelve la lista de operaciones registradas para el usuario o dispositivo actual.
     */
    public function status(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = SyncOperation::query();

        if ($user->role === 'PERSONERO' && $user->personero) {
            $query->where('personero_id', $user->personero->id);
        }

        if ($request->has('client_operation_id')) {
            $query->where('client_operation_id', $request->input('client_operation_id'));
        }

        $operations = $query->latest()->limit(50)->get();

        return response()->json([
            'data' => SyncOperationResource::collection($operations),
        ]);
    }
}
