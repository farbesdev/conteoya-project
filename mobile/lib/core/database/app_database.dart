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
  LocalPersonerosTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          final migrator = createMigrator();
          if (from < 5) {
            try {
              await migrator.drop(localPersonerosTable);
              await migrator.createTable(localPersonerosTable);
            } catch (_) {}
            try {
              await migrator.drop(localPollingStationsTable);
              await migrator.createTable(localPollingStationsTable);
            } catch (_) {}
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');

          final m = createMigrator();

          // 1. Validar y autorreparar local_polling_stations_table
          try {
            final stationColumns = await customSelect("PRAGMA table_info('local_polling_stations_table')").get();
            final hasDistrictName = stationColumns.any((row) => row.read<String>('name') == 'district_name');
            if (!hasDistrictName) {
              await m.drop(localPollingStationsTable);
              await m.createTable(localPollingStationsTable);
            }
          } catch (_) {
            try {
              await m.createTable(localPollingStationsTable);
            } catch (_) {}
          }

          // 2. Validar y autorreparar local_personeros_table (eliminar UNIQUE en polling_station_code)
          try {
            final indexList = await customSelect("PRAGMA index_list('local_personeros_table')").get();
            final hasPollingUnique = indexList.any((row) {
              final name = row.read<String>('name');
              return name.contains('polling_station_code');
            });
            if (hasPollingUnique) {
              await m.drop(localPersonerosTable);
              await m.createTable(localPersonerosTable);
            }
          } catch (_) {
            try {
              await m.drop(localPersonerosTable);
              await m.createTable(localPersonerosTable);
            } catch (_) {}
          }

          try {
            await m.createTable(localPoliticalOrganizationsTable);
          } catch (_) {}

          await seedInitialDataIfEmpty();
        },
      );

  // ─── DAOs & Consultas Transaccionales para Actas ────────────────────────────
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
        confirmedAt: status == 'CONFIRMED' || status == 'SYNCED' || status == 'REGISTRADA'
            ? Value(DateTime.now())
            : const Value.absent(),
      ),
    );
  }

  Stream<List<LocalAct>> watchAllActs() {
    return (select(localActsTable)..orderBy([(t) => OrderingTerm.desc(t.capturedAt)])).watch();
  }

  Future<List<LocalAct>> getActsByPollingStation(String pollingStationCode) {
    return (select(localActsTable)
          ..where((t) => t.pollingStationCode.equals(pollingStationCode)))
        .get();
  }

  Stream<List<LocalAct>> watchActsByPollingStation(String pollingStationCode) {
    return (select(localActsTable)
          ..where((t) => t.pollingStationCode.equals(pollingStationCode)))
        .watch();
  }

  Future<LocalAct?> getActByStationAndLevel(String pollingStationCode, int electoralLevelId) {
    return (select(localActsTable)
          ..where((t) =>
              t.pollingStationCode.equals(pollingStationCode) &
              t.electoralLevelId.equals(electoralLevelId)))
        .getSingleOrNull();
  }

  Future<LocalActTotal?> getTotalsForAct(String clientActUuid) {
    return (select(localActTotalsTable)
          ..where((t) => t.clientActUuid.equals(clientActUuid)))
        .getSingleOrNull();
  }

  Future<List<LocalActResult>> getResultsForAct(String clientActUuid) {
    return (select(localActResultsTable)
          ..where((t) => t.clientActUuid.equals(clientActUuid)))
        .get();
  }

  Future<LocalActEvidence?> getEvidenceForAct(String clientActUuid) {
    return (select(localActEvidenceTable)
          ..where((t) => t.clientActUuid.equals(clientActUuid)))
        .getSingleOrNull();
  }

  // ─── DAOs para Personeros ──────────────────────────────────────────────────
  Stream<List<LocalPersonero>> watchAllPersoneros() {
    return (select(localPersonerosTable)
          ..orderBy([(t) => OrderingTerm.asc(t.lastName), (t) => OrderingTerm.asc(t.firstName)]))
        .watch()
        .handleError((error) async {
      try {
        final m = createMigrator();
        await m.drop(localPersonerosTable);
        await m.createTable(localPersonerosTable);
        await seedInitialDataIfEmpty();
      } catch (_) {}
      return <LocalPersonero>[];
    });
  }

  Future<List<LocalPersonero>> getAllPersoneros() async {
    try {
      return await (select(localPersonerosTable)
            ..orderBy([(t) => OrderingTerm.asc(t.lastName), (t) => OrderingTerm.asc(t.firstName)]))
          .get();
    } catch (_) {
      try {
        final m = createMigrator();
        await m.drop(localPersonerosTable);
        await m.createTable(localPersonerosTable);
        await seedInitialDataIfEmpty();
        return await (select(localPersonerosTable)
              ..orderBy([(t) => OrderingTerm.asc(t.lastName), (t) => OrderingTerm.asc(t.firstName)]))
            .get();
      } catch (_) {
        return [];
      }
    }
  }

  Future<LocalPersonero?> getPersoneroByDni(String dni) {
    return (select(localPersonerosTable)..where((t) => t.dni.equals(dni))).getSingleOrNull();
  }

  Future<LocalPersonero?> getPersoneroByEmailOrDni(String queryStr) async {
    final clean = queryStr.trim();
    if (clean.isEmpty) return null;
    final byDni = await (select(localPersonerosTable)..where((t) => t.dni.equals(clean))).getSingleOrNull();
    if (byDni != null) return byDni;
    final byEmail = await (select(localPersonerosTable)..where((t) => t.email.equals(clean))).getSingleOrNull();
    if (byEmail != null) return byEmail;
    final digits = RegExp(r'\d{8}').firstMatch(clean)?.group(0);
    if (digits != null) {
      return (select(localPersonerosTable)..where((t) => t.dni.equals(digits))).getSingleOrNull();
    }
    return null;
  }

  Future<LocalPersonero?> getPersoneroByStation(String pollingStationCode) {
    return (select(localPersonerosTable)
          ..where((t) => t.pollingStationCode.equals(pollingStationCode)))
        .getSingleOrNull();
  }

  Future<int> insertPersonero(LocalPersonerosTableCompanion personero) {
    return into(localPersonerosTable).insert(personero);
  }

  Future<bool> updatePersonero(LocalPersonerosTableCompanion personero) {
    return update(localPersonerosTable).replace(personero);
  }

  Future<int> deletePersonero(int id) {
    return (delete(localPersonerosTable)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deletePersoneroByDni(String dni) {
    return (delete(localPersonerosTable)..where((t) => t.dni.equals(dni))).go();
  }

  Future<int> deletePollingStationByCode(String code) {
    return (delete(localPollingStationsTable)..where((t) => t.code.equals(code))).go();
  }

  Future<bool> updatePollingStation(LocalPollingStationsTableCompanion station) {
    final code = station.code.value;
    return (update(localPollingStationsTable)..where((t) => t.code.equals(code))).write(station).then((val) => val > 0);
  }

  Future<int> deleteActByClientUuid(String clientActUuid) {
    return transaction(() async {
      await (delete(localActEvidenceTable)..where((t) => t.clientActUuid.equals(clientActUuid))).go();
      await (delete(localActResultsTable)..where((t) => t.clientActUuid.equals(clientActUuid))).go();
      await (delete(localActTotalsTable)..where((t) => t.clientActUuid.equals(clientActUuid))).go();
      return (delete(localActsTable)..where((t) => t.clientActUuid.equals(clientActUuid))).go();
    });
  }

  // ─── DAOs para Mesas (Polling Stations) ────────────────────────────────────
  Stream<List<LocalPollingStation>> watchAllPollingStations() {
    return (select(localPollingStationsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.code)]))
        .watch();
  }

  Future<List<LocalPollingStation>> getAllPollingStations() {
    return (select(localPollingStationsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.code)]))
        .get();
  }

  Future<LocalPollingStation?> getPollingStationByCode(String code) {
    return (select(localPollingStationsTable)..where((t) => t.code.equals(code)))
        .getSingleOrNull();
  }

  Future<int> insertPollingStation(LocalPollingStationsTableCompanion station) async {
    final code = station.code.value;
    final existing = await (select(localPollingStationsTable)..where((t) => t.code.equals(code))).getSingleOrNull();
    if (existing != null) {
      await (update(localPollingStationsTable)..where((t) => t.code.equals(code))).write(
        LocalPollingStationsTableCompanion(
          locationName: station.locationName,
          districtCode: station.districtCode,
          districtName: station.districtName,
          provinceName: station.provinceName,
          departmentName: station.departmentName,
          registeredVoters: station.registeredVoters,
          status: station.status,
        ),
      );
      return existing.id;
    } else {
      return into(localPollingStationsTable).insert(station);
    }
  }

  Future<void> savePollingStations(List<LocalPollingStationsTableCompanion> stations) async {
    for (final station in stations) {
      await insertPollingStation(station);
    }
  }

  Future<void> savePersoneros(List<LocalPersonerosTableCompanion> personeros) {
    return batch((b) {
      b.insertAllOnConflictUpdate(localPersonerosTable, personeros);
    });
  }

  // ─── DAOs para Organizaciones Políticas ────────────────────────────────────
  Future<List<LocalPoliticalOrganization>> getAllPoliticalOrganizations() {
    return (select(localPoliticalOrganizationsTable)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<void> savePoliticalOrganizations(List<LocalPoliticalOrganizationsTableCompanion> orgs) {
    return batch((b) {
      b.insertAllOnConflictUpdate(localPoliticalOrganizationsTable, orgs);
    });
  }

  // ─── DAOs para Operaciones de Sincronización ───────────────────────────────
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

  // ─── Seeder Inicial Local (Mesas, Personeros y Organizaciones) ──────────────
  Future<void> seedInitialDataIfEmpty() async {
    try {
      // Sembrar/Actualizar Mesas Iniciales (Lima y Puerto Inca, Huánuco)
      await batch((b) {
        b.insertAllOnConflictUpdate(localPollingStationsTable, [
          LocalPollingStationsTableCompanion.insert(
            code: '030390',
            locationName: 'I.E. NUESTRA SEÑORA DE GUADALUPE',
            districtCode: const Value('150101'),
            districtName: const Value('LIMA - CERCADO'),
            provinceName: const Value('LIMA'),
            departmentName: const Value('LIMA'),
            registeredVoters: const Value(300),
          ),
          LocalPollingStationsTableCompanion.insert(
            code: '030391',
            locationName: 'I.E. NUESTRA SEÑORA DE GUADALUPE',
            districtCode: const Value('150101'),
            districtName: const Value('LIMA - CERCADO'),
            provinceName: const Value('LIMA'),
            departmentName: const Value('LIMA'),
            registeredVoters: const Value(300),
          ),
          LocalPollingStationsTableCompanion.insert(
            code: '030392',
            locationName: 'I.E. PEDRO A. LABARTHE',
            districtCode: const Value('150115'),
            districtName: const Value('LA VICTORIA'),
            provinceName: const Value('LIMA'),
            departmentName: const Value('LIMA'),
            registeredVoters: const Value(295),
          ),
          LocalPollingStationsTableCompanion.insert(
            code: '030393',
            locationName: 'I.E. ALFONSO UGARTE',
            districtCode: const Value('150131'),
            districtName: const Value('SAN ISIDRO'),
            provinceName: const Value('LIMA'),
            departmentName: const Value('LIMA'),
            registeredVoters: const Value(310),
          ),
          // Mesas de Puerto Inca - Huánuco
          LocalPollingStationsTableCompanion.insert(
            code: '040101',
            locationName: 'I.E. AGROPECUARIO PUERTO INCA',
            districtCode: const Value('001272'),
            districtName: const Value('PUERTO INCA'),
            provinceName: const Value('PUERTO INCA'),
            departmentName: const Value('HUÁNUCO'),
            registeredVoters: const Value(280),
          ),
          LocalPollingStationsTableCompanion.insert(
            code: '040102',
            locationName: 'I.E. 32223 CODO DEL POZUZO',
            districtCode: const Value('001274'),
            districtName: const Value('CODO DEL POZUZO'),
            provinceName: const Value('PUERTO INCA'),
            departmentName: const Value('HUÁNUCO'),
            registeredVoters: const Value(290),
          ),
          LocalPollingStationsTableCompanion.insert(
            code: '040103',
            locationName: 'I.E. TOURNAVISTA',
            districtCode: const Value('001272'),
            districtName: const Value('TOURNAVISTA'),
            provinceName: const Value('PUERTO INCA'),
            departmentName: const Value('HUÁNUCO'),
            registeredVoters: const Value(275),
          ),
          LocalPollingStationsTableCompanion.insert(
            code: '040104',
            locationName: 'I.E. YUYAPICHIS',
            districtCode: const Value('001275'),
            districtName: const Value('YUYAPICHIS'),
            provinceName: const Value('PUERTO INCA'),
            departmentName: const Value('HUÁNUCO'),
            registeredVoters: const Value(305),
          ),
        ]);
      });
    } catch (_) {
      try {
        final m = createMigrator();
        await m.drop(localPollingStationsTable);
        await m.createTable(localPollingStationsTable);
      } catch (_) {}
    }

    try {
      final personeroCount = await (select(localPersonerosTable)..limit(1)).get();
      if (personeroCount.isEmpty) {
        await into(localPersonerosTable).insert(
          LocalPersonerosTableCompanion.insert(
            dni: '44001122',
            firstName: 'Personero',
            lastName: 'Puerto Inca (Yuyapichis)',
            pollingStationCode: '040104',
            phoneNumber: const Value('+51 962 111 222'),
            email: const Value('personero.puertoinca@conteoya.pe'),
          ),
        );

        await into(localPersonerosTable).insert(
          LocalPersonerosTableCompanion.insert(
            dni: '12345678',
            firstName: 'Juan',
            lastName: 'Pérez Demo',
            pollingStationCode: '030390',
            phoneNumber: const Value('+51 987 654 321'),
            email: const Value('personero@conteoya.pe'),
          ),
        );
      }
    } catch (_) {
      try {
        final m = createMigrator();
        await m.drop(localPersonerosTable);
        await m.createTable(localPersonerosTable);
      } catch (_) {}
    }

    // Actualizar o sembrar Organizaciones Políticas con sus logos oficiales reales de Azure Blob
    await batch((b) {
      b.insertAllOnConflictUpdate(localPoliticalOrganizationsTable, [
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(4),
          name: 'ACCIÓN POPULAR',
          shortName: const Value('AP'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/4.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(14),
          name: 'PARTIDO DEMOCRÁTICO SOMOS PERÚ',
          shortName: const Value('SOMOS PERU'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/14.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(1257),
          name: 'ALIANZA PARA EL PROGRESO',
          shortName: const Value('APP'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/1257.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(1264),
          name: 'JUNTOS POR EL PERÚ',
          shortName: const Value('JP'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/1264.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(1366),
          name: 'FUERZA POPULAR',
          shortName: const Value('FP'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/1366.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(2173),
          name: 'AVANZA PAIS - PARTIDO DE INTEGRACION SOCIAL',
          shortName: const Value('AVANZA PAIS'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/2173.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(2731),
          name: 'PODEMOS PERU',
          shortName: const Value('PODEMOS'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/2731.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(2840),
          name: 'PARTIDO MORADO',
          shortName: const Value('PM'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/2840.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(2857),
          name: 'PARTIDO FRENTE DE LA ESPERANZA 2021',
          shortName: const Value('FE 2021'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/2857.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(3040),
          name: 'RENOVACIÓN POPULAR',
          shortName: const Value('RP'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/3040.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(2980),
          name: 'AHORA NACION - AN',
          shortName: const Value('AN'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/2980.png'),
        ),
      ]);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'conteoya_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
