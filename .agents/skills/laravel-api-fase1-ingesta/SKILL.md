---
name: laravel-api-fase1-ingesta
description: >
  Experto y buenas prácticas en Laravel 12+ para la implementación de endpoints de
  ingesta de actas electorales: Form Requests, API Resources, Policies, Services/UseCases,
  Jobs de procesamiento, idempotencia via Idempotency-Key, y protección de ownership de mesa.
  Activar en "laravel", "api", "endpoint", "controller", "form request", "policy", "service",
  "ingesta", "acta", "sync", "idempotencia".
---

# Experto y Buenas Prácticas en Laravel 12+ — API de Ingesta (Fase 1)

## 1. Estructura de Capas Recomendada

```
app/
├── Http/
│   ├── Controllers/Api/V1/
│   │   ├── ActController.php          # POST /acts, POST /acts/{act}/confirm
│   │   ├── EvidenceController.php     # POST /acts/{act}/evidence/*
│   │   └── SyncController.php         # POST /sync, GET /sync/status
│   ├── Requests/
│   │   ├── CreateActRequest.php
│   │   ├── ConfirmActRequest.php
│   │   ├── RequestUploadUrlRequest.php
│   │   └── SyncOperationRequest.php
│   ├── Resources/
│   │   ├── ActResource.php
│   │   ├── ActResultResource.php
│   │   └── SyncStatusResource.php
│   └── Middleware/
│       └── IdempotencyMiddleware.php  # Detecta reintentos por Idempotency-Key
├── Domain/
│   ├── Acts/
│   │   ├── ActService.php             # Orquesta creación y confirmación
│   │   ├── SyncService.php            # Procesa SyncOperations entrantes
│   │   └── ActValidationService.php   # Reglas de negocio: totales, ownership
│   └── Evidence/
│       └── EvidenceService.php
├── Policies/
│   ├── ActPolicy.php                  # ¿Puede el personero operar esta acta?
│   └── EvidencePolicy.php
├── Jobs/
│   └── ProcessSyncOperationJob.php    # Procesar operaciones en queue
└── Events/
    └── ActConfirmedEvent.php
```

---

## 2. Form Requests — Validación de Entradas

```php
// app/Http/Requests/CreateActRequest.php
class CreateActRequest extends FormRequest
{
    public function authorize(): bool
    {
        // Verificar que el personero tiene asignada esta mesa
        return $this->user()
                    ->personero
                    ?->pollingStations()
                    ->where('code', $this->polling_station_code)
                    ->exists() ?? false;
    }

    public function rules(): array
    {
        return [
            'client_operation_id'  => ['required', 'uuid', 'unique:sync_operations,client_operation_id'],
            'polling_station_code' => ['required', 'string', 'exists:polling_stations,code'],
            'election_id'          => ['required', 'integer', 'exists:elections,id'],
            'electoral_level_id'   => ['required', 'integer', 'exists:electoral_levels,id'],
            'results'              => ['required', 'array', 'min:1'],
            'results.*.political_organization_id' => ['required', 'integer', 'exists:political_organizations,id'],
            'results.*.votes'      => ['required', 'integer', 'min:0'],
            'results.*.source'     => ['required', 'string', 'in:MANUAL,OCR,AI'],
            'results.*.confidence' => ['nullable', 'numeric', 'min:0', 'max:1'],
            'totals'               => ['required', 'array'],
            'totals.registered_voters'  => ['required', 'integer', 'min:1'],
            'totals.voters_who_voted'   => ['required', 'integer', 'min:0'],
            'totals.total_votes'        => ['required', 'integer', 'min:0'],
            'totals.blank_votes'        => ['required', 'integer', 'min:0'],
            'totals.null_votes'         => ['required', 'integer', 'min:0'],
            'totals.challenged_votes'   => ['required', 'integer', 'min:0'],
        ];
    }
}
```

---

## 3. Idempotencia — Middleware y Manejo de Reintentos

```php
// app/Http/Middleware/IdempotencyMiddleware.php
class IdempotencyMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $idempotencyKey = $request->header('Idempotency-Key')
                        ?? $request->input('client_operation_id');

        if (!$idempotencyKey) {
            return $next($request);
        }

        // ¿Ya fue procesado? Devolver respuesta cacheada
        $cached = Cache::get("idempotency:{$idempotencyKey}");
        if ($cached) {
            return response()->json($cached['body'], $cached['status'])
                             ->header('X-Idempotent-Replayed', 'true');
        }

        $response = $next($request);

        // Cachear respuesta exitosa por 24 horas
        if ($response->getStatusCode() < 400) {
            Cache::put(
                "idempotency:{$idempotencyKey}",
                ['body' => $response->getData(true), 'status' => $response->getStatusCode()],
                now()->addDay()
            );
        }

        return $response;
    }
}
```

---

## 4. Policies — Ownership y Autorización

```php
// app/Policies/ActPolicy.php
class ActPolicy
{
    // ¿Puede el personero autenticado ver esta acta?
    public function view(User $user, Act $act): bool
    {
        return $user->role === Role::ADMIN
            || $user->role === Role::DIRECTOR
            || ($user->role === Role::PERSONERO
                && $act->capturedByPersoneroId === $user->personero?->id);
    }

    // ¿Puede crear un acta para esta mesa?
    public function create(User $user, PollingStation $station): bool
    {
        if ($user->role !== Role::PERSONERO) return false;

        return $user->personero
                    ?->pollingStations()
                    ->where('id', $station->id)
                    ->exists() ?? false;
    }

    // Solo el personero propietario puede confirmar
    public function confirm(User $user, Act $act): bool
    {
        return $user->role === Role::PERSONERO
            && $act->capturedByPersoneroId === $user->personero?->id
            && $act->status === 'DRAFT';
    }
}
```

---

## 5. Service / Use Case — Validación de Totales

```php
// app/Domain/Acts/ActValidationService.php
class ActValidationService
{
    /**
     * Reglas de negocio críticas para validar la integridad de un acta.
     * No lanzar excepciones — devolver lista de warnings para Human-in-the-Loop.
     */
    public function validate(ActTotalsDTO $totals, array $results): ActValidationResult
    {
        $warnings = [];

        // Regla 1: sum(votos_por_lista) + blancos + nulos + impugnados == total_votes
        $sumResults = array_sum(array_column($results, 'votes'));
        $expectedTotal = $sumResults + $totals->blankVotes + $totals->nullVotes + $totals->challengedVotes;

        if ($expectedTotal !== $totals->totalVotes) {
            $warnings[] = ActWarning::totalMismatch($expectedTotal, $totals->totalVotes);
        }

        // Regla 2: ciudadanos_que_votaron <= electores_habiles
        if ($totals->votersWhoVoted > $totals->registeredVoters) {
            $warnings[] = ActWarning::votersExceedRegistered();
        }

        // Regla 3: total_votes <= electores_habiles
        if ($totals->totalVotes > $totals->registeredVoters) {
            $warnings[] = ActWarning::votesExceedRegistered();
        }

        return new ActValidationResult(
            isValid:  empty($warnings),
            warnings: $warnings,
        );
    }
}
```

---

## 6. API Resources — Respuestas Consistentes

```php
// app/Http/Resources/ActResource.php
class ActResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                    => $this->id,
            'status'                => $this->status,
            'polling_station'       => new PollingStationResource($this->whenLoaded('pollingStation')),
            'election_id'           => $this->election_id,
            'electoral_level_id'    => $this->electoral_level_id,
            'captured_at'           => $this->captured_at?->toIso8601String(),
            'confirmed_at'          => $this->confirmed_at?->toIso8601String(),
            'totals'                => new ActTotalsResource($this->whenLoaded('totals')),
            'results'               => ActResultResource::collection($this->whenLoaded('results')),
            'evidence_count'        => $this->when(
                $this->relationLoaded('evidence'),
                fn () => $this->evidence->count()
            ),
            'has_ai_source'         => $this->when(
                $this->relationLoaded('results'),
                fn () => $this->results->contains('source', 'AI')
                      || $this->results->contains('source', 'OCR')
            ),
        ];
    }
}
```

---

## 7. Jobs — Procesamiento Asíncrono

```php
// app/Jobs/ProcessSyncOperationJob.php
class ProcessSyncOperationJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries   = 5;
    public int $timeout = 60;

    public function __construct(
        private readonly string $clientOperationId
    ) {}

    public function handle(SyncService $syncService): void
    {
        $operation = SyncOperation::where('client_operation_id', $this->clientOperationId)
                                  ->firstOrFail();

        // Double-check idempotencia en el job
        if ($operation->status === 'SYNCED') {
            return; // Ya procesado, no hacer nada
        }

        $syncService->process($operation);
    }

    public function backoff(): array
    {
        return [10, 30, 60, 120, 300]; // Exponential backoff en segundos
    }
}
```

---

## 8. Reglas Críticas para la API de Ingesta

| Regla | Descripción |
|-------|-------------|
| **Idempotencia obligatoria** | Todos los endpoints de escritura deben soportar `Idempotency-Key` |
| **Ownership siempre verificado** | `authorize()` en FormRequest + Policy antes de procesar |
| **La IA nunca confirma** | El campo `source: AI/OCR` es solo informativo; la confirmación la hace el personero |
| **Warnings no bloquean** | Las inconsistencias de totales son warnings, no errores 422 |
| **Transacciones atómicas** | `act` + `act_results` + `act_totals` se guardan en una sola transacción DB |
| **Rate limiting estricto** | `throttle:acts` más restrictivo que `throttle:api` general |
| **Audit log en cada acción** | Registrar `captured_by`, `confirmed_by`, `device_id`, IP, timestamp |
