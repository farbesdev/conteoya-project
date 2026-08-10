---
name: sqlite-drift-offline-first
description: >
  Experto y buenas prácticas en SQLite con Drift (antes Moor) para Flutter,
  enfocado en arquitecturas offline-first, sincronización idempotente, migraciones
  seguras de esquema, y manejo de transacciones en sistemas electorales críticos.
  Activar en "drift", "sqlite", "offline", "local database", "sync", "local storage".
---

# Experto y Buenas Prácticas en SQLite + Drift (Offline-First)

## 1. Configuración de la Base de Datos Local

### AppDatabase — estructura recomendada
```dart
// database/app_database.dart
@DriftDatabase(tables: [
  LocalActs,
  LocalActResults,
  LocalActTotals,
  LocalActEvidence,
  LocalSyncOperations,
  LocalCatalogDepartments,
  LocalCatalogElections,
  LocalCatalogElectoralLists,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate:    (m) async => await m.createAll(),
    onUpgrade:   (m, from, to) async => _migrate(m, from, to),
    beforeOpen:  (details) async {
      // SIEMPRE habilitar FK en SQLite
      await customStatement('PRAGMA foreign_keys = ON');
      // WAL mode para mejor concurrencia de lectura
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File(path.join(dir.path, 'conteoya_local.db'));
    return NativeDatabase.createInBackground(file);
  });
}
```

---

## 2. Definición de Tablas Drift

### Tabla de Actas Locales
```dart
class LocalActs extends Table {
  // PK local (UUID generado en cliente)
  TextColumn get clientId => text().withLength(max: 36)();

  // FK al server (null hasta que se sincronice)
  IntColumn  get serverId => integer().nullable()();

  TextColumn get pollingStationCode => text().withLength(max: 10)();
  TextColumn get electionCode       => text().withLength(max: 50)();
  TextColumn get electoralLevelCode => text().withLength(max: 50)();

  // Estado de la máquina de estados offline
  TextColumn get status => text().withDefault(const Constant('DRAFT'))();
  // DRAFT | READY_TO_SYNC | SYNCING | SYNCED | FAILED | CONFLICT

  TextColumn get capturedAt => text()(); // ISO-8601 string
  TextColumn get confirmedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {clientId};
}
```

### Tabla de Sync Operations
```dart
class LocalSyncOperations extends Table {
  // Idempotency key — UUID generado en el cliente
  TextColumn get clientOperationId => text().withLength(max: 36)();

  TextColumn get deviceId     => text()();
  TextColumn get entityType   => text()(); // 'acts', 'act_results', 'act_evidence'
  TextColumn get entityId     => text()();  // clientId de la entidad
  TextColumn get operation    => text()(); // 'CREATE' | 'UPDATE' | 'DELETE'
  TextColumn get payloadJson  => text()(); // JSON serializado del payload

  IntColumn  get attempts     => integer().withDefault(const Constant(0))();
  TextColumn get status       => text().withDefault(const Constant('PENDING'))();
  // PENDING | IN_FLIGHT | SYNCED | FAILED | CONFLICT

  TextColumn get lastError    => text().nullable()();
  TextColumn get processedAt  => text().nullable()();
  TextColumn get createdAt    => text()();

  @override
  Set<Column> get primaryKey => {clientOperationId};
}
```

---

## 3. Patrones de Acceso a Datos (DAOs)

```dart
// daos/act_dao.dart
@DriftAccessor(tables: [LocalActs, LocalActResults, LocalActTotals])
class ActDao extends DatabaseAccessor<AppDatabase> with _$ActDaoMixin {
  ActDao(AppDatabase db) : super(db);

  // ✅ Usar transacciones para operaciones compuestas
  Future<void> saveActWithResults(LocalAct act, List<LocalActResult> results) {
    return transaction(() async {
      await into(localActs).insertOnConflictUpdate(act);
      await batch((b) {
        b.insertAllOnConflictUpdate(localActResults, results);
      });
    });
  }

  // ✅ Streams reactivos para sincronización con la UI
  Stream<List<LocalAct>> watchPendingActs() {
    return (select(localActs)
      ..where((a) => a.status.isIn(['READY_TO_SYNC', 'FAILED']))).watch();
  }

  // ✅ Máquina de estados — solo transiciones válidas
  Future<void> transitionStatus(String clientId, String newStatus) async {
    final validTransitions = {
      'DRAFT':          {'READY_TO_SYNC'},
      'READY_TO_SYNC':  {'SYNCING', 'DRAFT'},
      'SYNCING':        {'SYNCED', 'FAILED', 'CONFLICT'},
      'FAILED':         {'READY_TO_SYNC'},
      'CONFLICT':       {'READY_TO_SYNC'},
    };
    // Verificar transición válida antes de actualizar
    ...
  }
}
```

---

## 4. Migraciones de Esquema

```dart
// ⚠️ REGLA CRÍTICA: Nunca bajar schemaVersion. Solo incrementar.
// ⚠️ Siempre usar addColumnIfNotExists, never dropColumn sin respaldo.

Future<void> _migrate(Migrator m, int from, int to) async {
  if (from < 2) {
    // Agregar columna en versión 2
    await m.addColumn(localActs, localActs.confirmedAt);
  }
  if (from < 3) {
    // Crear nueva tabla en versión 3
    await m.createTable(localActEvidence);
  }
}
```

### Reglas de migración
- **SIEMPRE** incrementar `schemaVersion` al agregar/modificar tablas.
- **NUNCA** usar `recreateAllViews()` en producción sin migración explícita.
- Usar `Migrator.addColumn()` en lugar de recrear tablas.
- Testear migraciones con `SchemaVerifier` de Drift en tests unitarios.

---

## 5. Sync Engine — Motor de Sincronización

### Flujo de sincronización idempotente
```dart
class SyncEngine {
  final AppDatabase _db;
  final ApiClient   _api;
  final ConnectivityChecker _connectivity;

  // Exponential backoff: 1s, 2s, 4s, 8s, 16s, max 30s
  static const _delays = [1, 2, 4, 8, 16, 30];

  Future<void> syncPendingOperations() async {
    if (!await _connectivity.hasConnection) return;

    final pending = await _db.syncOperationDao.getPending();

    for (final op in pending) {
      await _processWithRetry(op);
    }
  }

  Future<void> _processWithRetry(LocalSyncOperation op) async {
    final attempt = op.attempts;

    // Marcar como IN_FLIGHT
    await _db.syncOperationDao.updateStatus(op.clientOperationId, 'IN_FLIGHT');

    try {
      await _api.submitSyncOperation(
        clientOperationId: op.clientOperationId, // Idempotency key en header
        entityType: op.entityType,
        payload:    jsonDecode(op.payloadJson),
      );
      await _db.syncOperationDao.markSynced(op.clientOperationId);
    } on ConflictException catch (e) {
      await _db.syncOperationDao.markConflict(op.clientOperationId, e.message);
    } on NetworkException {
      final delay = _delays[attempt.clamp(0, _delays.length - 1)];
      await _db.syncOperationDao.markFailed(
        op.clientOperationId,
        'Network error. Retry in ${delay}s',
        attempts: attempt + 1,
      );
    }
  }
}
```

### Idempotency header en el backend
```
POST /api/v1/sync
Idempotency-Key: {client_operation_id}
```

---

## 6. Optimizaciones SQLite para ConteoYA

```sql
-- PRAGMAs esenciales (configurar en beforeOpen)
PRAGMA foreign_keys = ON;      -- Integridad referencial
PRAGMA journal_mode = WAL;     -- Write-Ahead Logging: mejor concurrencia
PRAGMA synchronous = NORMAL;   -- Balance rendimiento/durabilidad
PRAGMA cache_size = -32000;    -- 32MB de caché en memoria
PRAGMA temp_store = MEMORY;    -- Tablas temporales en RAM
```

---

## 7. Testing de la Capa de Datos

```dart
// test/data/act_dao_test.dart
test('saveActWithResults persists act and results in a single transaction', () async {
  final db  = AppDatabase(NativeDatabase.memory());
  final dao = ActDao(db);

  await dao.saveActWithResults(tLocalAct, tLocalActResults);

  final stored = await dao.getActById(tLocalAct.clientId);
  expect(stored, isNotNull);
  expect(stored!.status, equals('DRAFT'));

  final results = await dao.getResultsForAct(tLocalAct.clientId);
  expect(results, hasLength(tLocalActResults.length));

  await db.close();
});
```

---

## 8. Reglas Críticas

| Regla | Motivo |
|-------|--------|
| `PRAGMA foreign_keys = ON` siempre | SQLite los desactiva por defecto |
| UUID en `clientOperationId` | Clave de idempotencia globalmente única |
| Transacciones para operaciones compuestas | Atomicidad: acta + resultados juntos o ninguno |
| Streams reactivos con `watch()` | UI siempre actualizada automáticamente |
| Solo incrementar `schemaVersion` | Evitar corrupción en migraciones |
| Nunca delete de SyncOperations | Mantener historial para auditoría y replay |
