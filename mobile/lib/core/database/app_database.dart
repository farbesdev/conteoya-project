import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  LocalActsTable,
  LocalActTotalsTable,
  LocalActResultsTable,
  LocalActEvidenceTable,
  LocalSyncOperationsTable,
  LocalPollingStationsTable,
  LocalPoliticalOrganizationsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  // DAOs & Consultas Transaccionales para Actas
  Future<void> saveCompleteAct({
    required LocalActsTableCompanion act,
    required LocalActTotalsTableCompanion totals,
    required List<LocalActResultsTableCompanion> results,
  }) {
    return transaction(() async {
      await into(localActsTable).insertOnConflictUpdate(act);
      await into(localActTotalsTable).insertOnConflictUpdate(totals);
      
      // Eliminar resultados previos para esta acta y reinsertar
      await (delete(localActResultsTable)
            ..where((tbl) => tbl.clientActUuid.equals(act.clientActUuid.value)))
          .go();

      for (final res in results) {
        await into(localActResultsTable).insert(res);
      }
    });
  }

  Future<void> updateActStatus(String clientActUuid, String status, {int? serverActId}) {
    return (update(localActsTable)..where((t) => t.clientActUuid.equals(clientActUuid))).write(
      LocalActsTableCompanion(
        status: Value(status),
        serverActId: serverActId != null ? Value(serverActId) : const Value.absent(),
        confirmedAt: status == 'CONFIRMED' || status == 'SYNCED' ? Value(DateTime.now()) : const Value.absent(),
      ),
    );
  }

  // Sync Operations DAOs
  Future<void> enqueueSyncOperation(LocalSyncOperationsTableCompanion op) {
    return into(localSyncOperationsTable).insertOnConflictUpdate(op);
  }

  Future<List<LocalSyncOperation>> getPendingSyncOperations() {
    return (select(localSyncOperationsTable)
          ..where((t) => t.status.isIn(['PENDING', 'FAILED']))
          ..where((t) => t.scheduledAt.isSmallerOrEqualValue(DateTime.now()))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> updateSyncOpStatus(
    String clientOperationId,
    String status, {
    String? error,
    DateTime? nextSchedule,
  }) {
    return (update(localSyncOperationsTable)
          ..where((t) => t.clientOperationId.equals(clientOperationId)))
        .write(
      LocalSyncOperationsTableCompanion(
        status: Value(status),
        lastError: Value(error),
        processedAt: status == 'SYNCED' ? Value(DateTime.now()) : const Value.absent(),
        scheduledAt: nextSchedule != null ? Value(nextSchedule) : const Value.absent(),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'conteoya_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
