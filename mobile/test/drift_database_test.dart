import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conteoya_mobile/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Guarda y recupera un acta completa transaccionalmente en Drift', () async {
    const actUuid = 'act-uuid-test-1234';

    await db.saveCompleteAct(
      act: LocalActsTableCompanion.insert(
        clientActUuid: actUuid,
        electionId: 1,
        electoralLevelId: 1,
        pollingStationCode: '030390',
        status: const Value('DRAFT'),
      ),
      totals: LocalActTotalsTableCompanion.insert(
        clientActUuid: actUuid,
        registeredVoters: 300,
        votersWhoVoted: 250,
        totalVotes: 250,
        blankVotes: const Value(10),
        nullVotes: const Value(5),
        challengedVotes: const Value(0),
        isValidTotal: const Value(true),
      ),
      results: [
        LocalActResultsTableCompanion.insert(
          clientActUuid: actUuid,
          politicalOrganizationId: const Value(1),
          politicalOrganizationName: const Value('PARTIDO A'),
          votes: const Value(235),
          source: const Value('MANUAL'),
        ),
      ],
    );

    final acts = await db.select(db.localActsTable).get();
    expect(acts.length, 1);
    expect(acts.first.clientActUuid, actUuid);
    expect(acts.first.status, 'DRAFT');

    final totals = await db.select(db.localActTotalsTable).get();
    expect(totals.length, 1);
    expect(totals.first.totalVotes, 250);

    final results = await db.select(db.localActResultsTable).get();
    expect(results.length, 1);
    expect(results.first.votes, 235);
  });

  test('Encola y actualiza operaciones de sincronización', () async {
    const opId = 'sync-op-uuid-999';

    await db.enqueueSyncOperation(
      LocalSyncOperationsTableCompanion.insert(
        clientOperationId: opId,
        entityType: 'acts',
        entityId: 'act-uuid-1',
        payloadJson: '{"test": 123}',
        status: const Value('PENDING'),
      ),
    );

    var pending = await db.getPendingSyncOperations();
    expect(pending.length, 1);
    expect(pending.first.clientOperationId, opId);

    await db.updateSyncOpStatus(opId, 'SYNCED');

    pending = await db.getPendingSyncOperations();
    expect(pending, isEmpty);
  });
}
