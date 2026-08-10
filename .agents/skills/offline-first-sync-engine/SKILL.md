---
name: offline-first-sync-engine
description: >
  Experto y buenas prácticas en el diseño e implementación de motores de sincronización
  offline-first para aplicaciones móviles electorales. Cubre máquinas de estado, idempotencia,
  exponential backoff, resolución de conflictos, checksum de integridad, y las estrategias de
  sincronización específicas para ConteoYA (Flutter ↔ Laravel/PostgreSQL).
  Activar en "offline", "sync", "sincronización", "idempotencia", "conflict", "retry",
  "backoff", "connectivity", "client_operation_id", "sync engine".
---

# Experto y Buenas Prácticas en Offline-First Sync Engine

## 1. Principios Fundamentales

1. **Offline es el modo normal.** La conectividad es el caso especial, no al revés.
2. **El dispositivo es la fuente de verdad local.** El servidor es la fuente de verdad global eventual.
3. **Idempotencia end-to-end.** Cualquier operación puede enviarse N veces; el resultado es siempre el mismo.
4. **Nunca duplicar una acta.** La clave de idempotencia (`client_operation_id`) previene duplicados en el servidor.
5. **Auditoría completa.** Cada operación de sync tiene trazabilidad: quién, cuándo, qué dispositivo, cuántos intentos.

---

## 2. Máquina de Estados de una Acta

```
                    ┌─────────────┐
      [crear]       │    DRAFT    │
    ─────────────►  │  (local)    │
                    └──────┬──────┘
                           │ [personero confirma]
                           ▼
                    ┌─────────────────┐
                    │  READY_TO_SYNC  │
                    │   (local)       │
                    └──────┬──────────┘
                           │ [sync engine inicia]
                           ▼
                    ┌─────────────┐
                    │   SYNCING   │◄──────────────────────┐
                    │  (local)    │                       │
                    └──────┬──────┘                       │ [retry]
                           │                              │
               ┌───────────┼───────────┐                  │
               ▼           ▼           ▼                  │
         ┌──────────┐ ┌──────────┐ ┌──────────┐          │
         │  SYNCED  │ │  FAILED  │ │ CONFLICT │──────────►┘
         │  (final) │ │ (retry)  │ │ (manual) │
         └──────────┘ └──────────┘ └──────────┘
```

### Transiciones válidas
| Estado actual | Evento | Nuevo estado |
|---------------|--------|--------------|
| `DRAFT` | Personero confirma | `READY_TO_SYNC` |
| `READY_TO_SYNC` | Engine detecta red | `SYNCING` |
| `READY_TO_SYNC` | Personero edita | `DRAFT` |
| `SYNCING` | Servidor acepta (2xx) | `SYNCED` |
| `SYNCING` | Error de red | `FAILED` |
| `SYNCING` | Conflicto (409) | `CONFLICT` |
| `FAILED` | Timer/retry | `READY_TO_SYNC` |
| `CONFLICT` | Resolución manual | `READY_TO_SYNC` |

---

## 3. SyncOperation — Estructura Completa

```dart
// Flutter / Drift
class LocalSyncOperationsTable extends Table {
  TextColumn get clientOperationId => text()();     // UUID — idempotency key
  TextColumn get deviceUuid        => text()();     // UUID del dispositivo
  TextColumn get personeroId       => text()();     // ID del personero
  TextColumn get entityType        => text()();     // 'acts' | 'act_results' | 'act_evidence'
  TextColumn get entityId          => text()();     // clientId de la entidad
  TextColumn get operation         => text()();     // 'CREATE' | 'UPDATE' | 'DELETE'
  TextColumn get payloadJson       => text()();     // JSON serializado
  TextColumn get checksum          => text()();     // SHA-256 del payload (integridad)
  IntColumn  get attempts          => integer().withDefault(const Constant(0))();
  TextColumn get status            => text().withDefault(const Constant('PENDING'))();
  TextColumn get lastError         => text().nullable()();
  TextColumn get scheduledAt       => text()();     // Cuándo procesar (backoff)
  TextColumn get processedAt       => text().nullable()();
  TextColumn get createdAt         => text()();

  @override
  Set<Column> get primaryKey => {clientOperationId};
}
```

---

## 4. Exponential Backoff — Implementación

```dart
// lib/core/sync/backoff_calculator.dart
class ExponentialBackoff {
  // Delays en segundos: 5s, 10s, 20s, 40s, 80s, max 120s
  static const _base = 5;
  static const _maxDelay = 120;
  static const _jitterPercent = 0.2; // ±20% aleatoriedad para evitar thundering herd

  static Duration calculate(int attempt) {
    if (attempt <= 0) return const Duration(seconds: _base);

    final exponential = _base * pow(2, attempt - 1).toInt();
    final capped      = exponential.clamp(0, _maxDelay);

    // Añadir jitter
    final jitter = (capped * _jitterPercent * Random().nextDouble()).round();
    final finalDelay = capped + jitter;

    return Duration(seconds: finalDelay);
  }
}

// Uso en el SyncEngine
Future<void> _scheduleRetry(LocalSyncOperation op) async {
  final delay = ExponentialBackoff.calculate(op.attempts);
  final scheduledAt = DateTime.now().add(delay);

  await _db.syncOperationDao.updateScheduledAt(
    op.clientOperationId,
    scheduledAt.toIso8601String(),
    newStatus: 'PENDING',
  );
}
```

---

## 5. SyncEngine — Motor Principal

```dart
// lib/features/sync/sync_engine.dart
class SyncEngine {
  final AppDatabase         _db;
  final SyncApiClient       _api;
  final ConnectivityService _connectivity;
  final AuditLogger         _logger;

  Timer? _periodicTimer;

  /// Inicia el motor de sincronización periódico
  void start() {
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _trySync(),
    );

    // También escuchar cambios de conectividad
    _connectivity.onConnected.listen((_) => _trySync());
  }

  Future<void> _trySync() async {
    if (!await _connectivity.isConnected) return;

    final pending = await _db.syncOperationDao.getDueOperations(DateTime.now());
    if (pending.isEmpty) return;

    for (final op in pending) {
      if (!await _connectivity.isConnected) break; // Detener si perdemos red

      await _processOperation(op);
    }
  }

  Future<void> _processOperation(LocalSyncOperation op) async {
    // 1. Marcar como IN_FLIGHT
    await _db.syncOperationDao.updateStatus(op.clientOperationId, 'IN_FLIGHT');

    try {
      // 2. Verificar integridad del payload
      final actualChecksum = _computeSha256(op.payloadJson);
      if (actualChecksum != op.checksum) {
        throw SyncIntegrityException('Checksum mismatch para ${op.clientOperationId}');
      }

      // 3. Enviar al servidor con Idempotency-Key
      await _api.submitOperation(
        clientOperationId: op.clientOperationId,
        entityType:        op.entityType,
        entityId:          op.entityId,
        operation:         op.operation,
        payload:           jsonDecode(op.payloadJson),
      );

      // 4. Marcar como SYNCED
      await _db.syncOperationDao.markSynced(
        op.clientOperationId,
        processedAt: DateTime.now().toIso8601String(),
      );

      _logger.log('SYNC_SUCCESS', op.clientOperationId);

    } on ConflictException catch (e) {
      await _db.syncOperationDao.markConflict(op.clientOperationId, e.message);
      _logger.log('SYNC_CONFLICT', op.clientOperationId, error: e.message);

    } on NetworkException {
      final newAttempts = op.attempts + 1;
      await _scheduleRetry(op.copyWith(attempts: newAttempts));
      _logger.log('SYNC_RETRY', op.clientOperationId, attempt: newAttempts);

    } catch (e) {
      await _db.syncOperationDao.markFailed(op.clientOperationId, e.toString());
      _logger.log('SYNC_FAILED', op.clientOperationId, error: e.toString());
    }
  }
}
```

---

## 6. Backend Laravel — Endpoint de Sync

```php
// POST /api/v1/sync
// Header: Idempotency-Key: {client_operation_id}
class SyncController extends Controller
{
    public function receive(SyncOperationRequest $request): JsonResponse
    {
        $clientOperationId = $request->header('Idempotency-Key')
                           ?? $request->input('client_operation_id');

        // Idempotencia: ¿ya fue procesado?
        $existing = SyncOperation::where('client_operation_id', $clientOperationId)->first();
        if ($existing?->status === 'SYNCED') {
            return response()->json([
                'message'              => 'Operación ya procesada.',
                'client_operation_id'  => $clientOperationId,
                'replayed'             => true,
            ])->header('X-Idempotent-Replayed', 'true');
        }

        // Procesar en queue para no bloquear la respuesta
        ProcessSyncOperationJob::dispatch($clientOperationId);

        return response()->json([
            'message'             => 'Operación encolada para procesamiento.',
            'client_operation_id' => $clientOperationId,
        ], 202);
    }
}
```

---

## 7. Resolución de Conflictos

### Estrategia para ConteoYA (Fase 1)
- **Conflicto:** El acta ya fue registrada en el servidor por otro dispositivo con el mismo `polling_station_id + election_id + electoral_level_id`.
- **Resolución:** El backend devuelve `409 Conflict` con el acta existente; el cliente muestra una pantalla de resolución manual.
- **NO usar Last-Write-Wins** para actas electorales — requiere supervisión humana.

```php
// Detección de conflicto en el servidor
$existingAct = Act::where('polling_station_id', $dto->pollingStationId)
                  ->where('election_id', $dto->electionId)
                  ->where('electoral_level_id', $dto->electoralLevelId)
                  ->first();

if ($existingAct && $existingAct->status !== 'DRAFT') {
    return response()->json([
        'message'       => 'Ya existe un acta confirmada para esta mesa y elección.',
        'conflict_act'  => new ActResource($existingAct),
    ], 409);
}
```

---

## 8. Reglas Críticas del Sync Engine

| Regla | Descripción |
|-------|-------------|
| **`client_operation_id` es UUID** | Generado en el cliente, jamás en el servidor |
| **Checksum en payload** | SHA-256 del JSON antes de encolar; verificar antes de enviar |
| **Jitter en backoff** | Evitar thundering herd cuando miles de dispositivos reconectan simultáneamente |
| **Nunca eliminar SyncOperations** | Mantener historial completo para auditoría post-electoral |
| **Límite de intentos** | Máximo 10 intentos; después notificar al supervisor |
| **Respetar ownership** | El servidor rechaza operaciones de mesas no asignadas al personero |
| **Transacción DB en el servidor** | Todo el procesamiento de una SyncOperation es atómico |
