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
        $personero = $user->personero;

        if (!$personero && !$user->isAdmin() && !$user->isDirector()) {
            return response()->json(['message' => 'No autorizado para sincronizar operaciones.'], 403);
        }

        $device = null;
        if ($request->has('device_uuid')) {
            $device = Device::where('device_uuid', $request->input('device_uuid'))->first();
        }

        $operations = $request->input('operations', []);
        $results = $this->syncService->processBatch(
            personero: $personero,
            device: $device,
            operations: $operations
        );

        return response()->json([
            'message' => 'Lote de operaciones de sincronización procesado.',
            'data'    => $results,
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

        // 1. Obtener mesas (Si es Personero solo las suyas, si es Admin/Director todas)
        $pollingStationsQuery = \App\Models\PollingStation::with(['electoralLocation.district.province.department']);
        if ($user->role === 'PERSONERO' && $user->personero) {
            $stationIds = $user->personero->pollingStations()->pluck('polling_stations.id');
            $pollingStationsQuery->whereIn('id', $stationIds);
        }

        $pollingStations = $pollingStationsQuery->get()->map(function ($station) {
            $loc = $station->electoralLocation;
            $dist = $loc?->district;
            $prov = $dist?->province;
            $dept = $prov?->department;

            return [
                'id'                => $station->id,
                'code'              => $station->code,
                'location_name'     => $loc?->name ?? 'LOCAL DE VOTACIÓN',
                'address'           => $loc?->address,
                'district_code'     => $dist?->code ?? '000000',
                'district_name'     => $dist?->name ?? 'DISTRITO',
                'province_name'     => $prov?->name ?? 'PROVINCIA',
                'department_name'   => $dept?->name ?? 'DEPARTAMENTO',
                'registered_voters' => $station->registered_voters,
                'status'            => $station->status,
            ];
        });

        // 2. Obtener personeros y usuarios (Si es Personero solo el suyo, si es Admin/Director todos)
        $personerosQuery = \App\Models\Personero::with(['user', 'pollingStations']);
        if ($user->role === 'PERSONERO' && $user->personero) {
            $personerosQuery->where('id', $user->personero->id);
        }

        $personeros = $personerosQuery->get()->map(function ($p) {
            $stationCode = $p->pollingStations->first()?->code ?? '030390';
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

        // 3. Obtener organizaciones políticas del catálogo maestro
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

        return response()->json([
            'message' => 'Sincronización descendente completada.',
            'data' => [
                'polling_stations'       => $pollingStations,
                'personeros'             => $personeros,
                'political_organizations' => $organizations,
                'server_time'            => now()->toIso8601String(),
            ],
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
