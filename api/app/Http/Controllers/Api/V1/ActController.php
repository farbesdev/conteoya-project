<?php

namespace App\Http\Controllers\Api\V1;

use App\Domain\Acts\ActService;
use App\Domain\Acts\DTOs\ActTotalsDTO;
use App\Http\Controllers\Controller;
use App\Http\Requests\ConfirmActRequest;
use App\Http\Requests\CreateActRequest;
use App\Http\Resources\ActResource;
use App\Models\Act;
use App\Models\Device;
use App\Models\PollingStation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

/**
 * @tags Actas Electorales
 */
class ActController extends Controller
{
    public function __construct(
        protected ActService $actService
    ) {}

    /**
     * Listar y Filtrar Actas Electorales (Admin, Director o Personero)
     *
     * @queryParam search string Término de búsqueda (código de acta o código de mesa).
     * @queryParam status string Filtrar por estado (DRAFT, CONFIRMED, SYNCED, OBSERVED).
     * @queryParam election_id int Filtrar por ID de elección.
     * @queryParam per_page int Cantidad de elementos por página (default 15).
     * @queryParam page int Número de página.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $perPage = min((int) $request->input('per_page', 15), 100);
        if ($perPage < 1) {
            $perPage = 15;
        }

        $query = Act::with([
            'totals',
            'results.politicalOrganization',
            'evidences',
            'pollingStation',
            'capturedByPersonero.user',
        ]);

        if ($user->isPersonero() && $user->personero) {
            $stationIds = $user->personero->pollingStations()->pluck('polling_stations.id');
            $query->where(function ($q) use ($user, $stationIds) {
                $q->where('captured_by_personero_id', $user->personero->id)
                  ->orWhereIn('polling_station_id', $stationIds);
            });
        }

        if ($search = $request->input('search')) {
            $search = trim($search);
            $like = config('database.default') === 'pgsql' ? 'ILIKE' : 'LIKE';
            $query->where(function ($q) use ($search, $like) {
                $q->where('act_code', $like, "%{$search}%")
                  ->orWhereHas('pollingStation', function ($stQ) use ($search, $like) {
                      $stQ->where('code', $like, "%{$search}%")
                          ->orWhere('department_name', $like, "%{$search}%")
                          ->orWhere('province_name', $like, "%{$search}%")
                          ->orWhere('district_name', $like, "%{$search}%");
                  });
            });
        }

        if ($status = $request->input('status')) {
            $query->where('status', $status);
        }

        if ($electionId = $request->input('election_id')) {
            $query->where('election_id', $electionId);
        }

        $paginated = $query->orderByDesc('id')->paginate($perPage);

        return response()->json([
            'message' => 'Lista de actas obtenida exitosamente.',
            'data'    => ActResource::collection($paginated->items()),
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
     * Registrar o actualizar Acta Electoral (Ingesta Manual / Offline)
     *
     * Registra los resultados y totales de una mesa de votación de forma atómica.
     * Si la suma de votos difiere del total emitido, la operación no se bloquea;
     * se devuelve el acta registrada junto con la lista de advertencias (`warnings`).
     */
    public function store(CreateActRequest $request): JsonResponse
    {
        $user = $request->user();
        $personero = $user->personero;

        if (!$personero && !$user->isAdmin()) {
            return response()->json(['message' => 'El usuario no tiene perfil de personero.'], 403);
        }

        $station = PollingStation::where(function ($q) use ($request) {
            if ($request->filled('polling_station_id')) {
                $q->where('id', $request->input('polling_station_id'));
            }
            if ($request->filled('polling_station_code')) {
                $q->orWhere('code', $request->input('polling_station_code'));
            }
        })->firstOrFail();

        $totalsDTO = ActTotalsDTO::fromArray($request->input('totals'));
        $results   = $request->input('results', []);

        $deviceId = null;
        if ($request->has('device_uuid')) {
            $device = Device::where('device_uuid', $request->input('device_uuid'))->first();
            $deviceId = $device?->id;
        }

        $created = $this->actService->createOrUpdateAct(
            electionId: (int)$request->input('election_id'),
            electoralLevelId: (int)$request->input('electoral_level_id'),
            station: $station,
            personero: $personero,
            totalsDTO: $totalsDTO,
            results: $results,
            actCode: $request->input('act_code'),
            status: $request->input('status', 'DRAFT'),
            clientOperationId: $request->input('client_operation_id'),
            deviceId: $deviceId
        );

        return response()->json([
            'message'           => 'Acta electoral registrada con éxito.',
            'data'              => new ActResource($created['act']),
            'validation_result' => $created['validation_result']->toArray(),
        ], 201);
    }

    /**
     * Ver detalle de un Acta Electoral
     */
    public function show(Request $request, Act $act): JsonResponse
    {
        Gate::authorize('view', $act);

        $act->load(['totals', 'results.politicalOrganization', 'results.candidate', 'evidences', 'pollingStation', 'capturedByPersonero.user']);

        return response()->json([
            'data' => new ActResource($act),
        ]);
    }

    /**
     * Confirmar Acta Electoral
     *
     * Transiciona el estado del acta a `CONFIRMED` e inserta la marca temporal de confirmación.
     */
    public function confirm(ConfirmActRequest $request, Act $act): JsonResponse
    {
        Gate::authorize('confirm', $act);

        $personero = $request->user()->personero;
        $confirmed = $this->actService->confirmAct($act, $personero);

        return response()->json([
            'message' => 'Acta electoral confirmada exitosamente.',
            'data'    => new ActResource($confirmed),
        ]);
    }

    /**
     * Actualizar Acta Electoral (Admin / Director)
     */
    public function update(Request $request, Act $act): JsonResponse
    {
        Gate::authorize('update', $act);

        if ($request->has('status')) {
            $act->status = $request->input('status');
            if ($act->status === 'CONFIRMED' && !$act->confirmed_at) {
                $act->confirmed_at = now();
            }
        }
        if ($request->filled('act_code')) {
            $act->act_code = $request->input('act_code');
        }
        $act->save();

        if ($request->filled('totals') && is_array($request->input('totals'))) {
            $totals = $request->input('totals');
            $act->totals()->updateOrCreate(
                ['act_id' => $act->id],
                array_filter([
                    'total_votes'      => $totals['total_votes'] ?? null,
                    'voters_who_voted' => $totals['voters_who_voted'] ?? null,
                    'blank_votes'      => $totals['blank_votes'] ?? null,
                    'null_votes'       => $totals['null_votes'] ?? null,
                    'challenged_votes' => $totals['challenged_votes'] ?? null,
                ], fn ($v) => !is_null($v))
            );
        }

        return response()->json([
            'message' => 'Acta electoral actualizada exitosamente.',
            'data'    => new ActResource($act->fresh(['totals', 'results.politicalOrganization', 'evidences', 'pollingStation'])),
        ]);
    }

    /**
     * Eliminar o Limpiar Acta Electoral (Admin, Director o Personero Asignado)
     */
    public function destroy(Request $request, Act $act): JsonResponse
    {
        Gate::authorize('delete', $act);

        \Illuminate\Support\Facades\DB::transaction(function () use ($act) {
            $act->evidence()->delete();
            $act->results()->delete();
            $act->totals()->delete();
            $act->delete();
        });

        return response()->json([
            'message' => 'Acta electoral eliminada exitosamente del sistema.',
        ]);
    }
}
