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
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _ensureBallotTemplatesTableCreated();
        },
        onUpgrade: (m, from, to) async {
          final migrator = createMigrator();
          if (from < 6) {
            try {
              await migrator.drop(localPollingStationsTable);
              await migrator.createTable(localPollingStationsTable);
            } catch (_) {}
          }
          if (from < 7) {
            try {
              await migrator.addColumn(localPersonerosTable, localPersonerosTable.isActive);
            } catch (_) {}
          }
          if (from < 8) {
            try {
              await migrator.addColumn(localPollingStationsTable, localPollingStationsTable.odpe);
            } catch (_) {}
          }
          if (from < 9) {
            // Agregar departmentCode: código de departamento RENIEC (2 dígitos),
            // derivado del districtCode. Corrige el bug de filtrado regional
            // donde el nombre con tildes (HUÁNUCO) no coincidía con departments.name (HUANUCO).
            try {
              await migrator.addColumn(
                localPollingStationsTable,
                localPollingStationsTable.departmentCode,
              );
              // Poblar departmentCode para mesas existentes: extraer 2 primeros dígitos del districtCode
              await customStatement(
                "UPDATE local_polling_stations_table "
                "SET department_code = SUBSTR(district_code, 1, 2) "
                "WHERE department_code IS NULL AND LENGTH(district_code) >= 6",
              );
            } catch (_) {}
          }
          await _ensureBallotTemplatesTableCreated();
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await customStatement('PRAGMA journal_mode = WAL');

          final m = createMigrator();

          // 1. Validar y autorreparar local_polling_stations_table
          try {
            final stationColumns = await customSelect("PRAGMA table_info('local_polling_stations_table')").get();
            final hasDistrictName = stationColumns.any((row) => row.read<String>('name') == 'district_name');
            final hasOdpe = stationColumns.any((row) => row.read<String>('name') == 'odpe');
            final hasDeptCode = stationColumns.any((row) => row.read<String>('name') == 'department_code');

            if (!hasDistrictName || !hasOdpe) {
              // Recrear la tabla completa si le faltan columnas críticas
              await m.drop(localPollingStationsTable);
              await m.createTable(localPollingStationsTable);
            } else if (!hasDeptCode) {
              // Agregar solo department_code si es la única columna faltante (migración incremental)
              await m.addColumn(localPollingStationsTable, localPollingStationsTable.departmentCode);
              // Poblar departmentCode desde districtCode (primeros 2 dígitos del ubigeo RENIEC)
              await customStatement(
                "UPDATE local_polling_stations_table "
                "SET department_code = SUBSTR(district_code, 1, 2) "
                "WHERE department_code IS NULL AND LENGTH(district_code) >= 6",
              );
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

          await _ensureBallotTemplatesTableCreated();

          await seedInitialDataIfEmpty();
        },
      );

  Future<void> _ensureBallotTemplatesTableCreated() async {
    try {
      await customStatement('''
        CREATE TABLE IF NOT EXISTS local_ballot_templates_table (
          polling_station_code TEXT NOT NULL,
          electoral_level_id INTEGER NOT NULL,
          template_json TEXT NOT NULL,
          updated_at INTEGER NOT NULL,
          PRIMARY KEY (polling_station_code, electoral_level_id)
        )
      ''');
    } catch (_) {}
  }

  // ─── DAOs & Consultas Transaccionales para Actas ────────────────────────────
  Future<void> saveCompleteAct({
    required LocalActsTableCompanion act,
    required LocalActTotalsTableCompanion totals,
    required List<LocalActResultsTableCompanion> results,
  }) {
    return transaction(() async {
      // Si existe un acta previa para la misma mesa y nivel con distinto UUID, limpiar duplicados
      final stationCode = act.pollingStationCode.value;
      final levelId = act.electoralLevelId.value;
      final currentUuid = act.clientActUuid.value;

      final previousActs = await (select(localActsTable)
            ..where((t) =>
                t.pollingStationCode.equals(stationCode) &
                t.electoralLevelId.equals(levelId) &
                t.clientActUuid.equals(currentUuid).not()))
          .get();

      for (final prev in previousActs) {
        await (delete(localActEvidenceTable)..where((t) => t.clientActUuid.equals(prev.clientActUuid))).go();
        await (delete(localActResultsTable)..where((t) => t.clientActUuid.equals(prev.clientActUuid))).go();
        await (delete(localActTotalsTable)..where((t) => t.clientActUuid.equals(prev.clientActUuid))).go();
        await (delete(localActsTable)..where((t) => t.clientActUuid.equals(prev.clientActUuid))).go();
      }

      await into(localActsTable).insertOnConflictUpdate(act);
      await into(localActTotalsTable).insertOnConflictUpdate(totals);

      // Eliminar resultados previos para esta acta y reinsertar
      await (delete(localActResultsTable)
            ..where((tbl) => tbl.clientActUuid.equals(currentUuid)))
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

  Future<LocalAct?> getActByStationAndLevel(String pollingStationCode, int electoralLevelId) async {
    final rows = await (select(localActsTable)
          ..where((t) =>
              t.pollingStationCode.equals(pollingStationCode) &
              t.electoralLevelId.equals(electoralLevelId))
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)])
          ..limit(1))
        .get();
    return rows.firstOrNull;
  }

  Future<LocalActTotal?> getTotalsForAct(String clientActUuid) async {
    final rows = await (select(localActTotalsTable)
          ..where((t) => t.clientActUuid.equals(clientActUuid))
          ..limit(1))
        .get();
    return rows.firstOrNull;
  }

  Future<List<LocalActResult>> getResultsForAct(String clientActUuid) {
    return (select(localActResultsTable)
          ..where((t) => t.clientActUuid.equals(clientActUuid)))
        .get();
  }

  Future<LocalActEvidence?> getEvidenceForAct(String clientActUuid) async {
    final rows = await (select(localActEvidenceTable)
          ..where((t) => t.clientActUuid.equals(clientActUuid))
          ..limit(1))
        .get();
    return rows.firstOrNull;
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

    // Derivar departmentCode automáticamente desde districtCode (primeros 2 dígitos del ubigeo RENIEC)
    // Esto garantiza que el campo esté siempre poblado sin depender de nombres con posibles tildes.
    final distCode = station.districtCode.present ? station.districtCode.value : '';
    final derivedDeptCode = distCode.length >= 6 ? distCode.substring(0, 2) : null;
    final deptCodeValue = station.departmentCode.present && station.departmentCode.value != null
        ? Value<String?>(station.departmentCode.value)
        : Value<String?>(derivedDeptCode);

    final existing = await (select(localPollingStationsTable)..where((t) => t.code.equals(code))).getSingleOrNull();
    if (existing != null) {
      await (update(localPollingStationsTable)..where((t) => t.code.equals(code))).write(
        LocalPollingStationsTableCompanion(
          locationName: station.locationName,
          districtCode: station.districtCode,
          districtName: station.districtName,
          provinceName: station.provinceName,
          departmentName: station.departmentName,
          departmentCode: deptCodeValue,
          registeredVoters: station.registeredVoters,
          status: station.status,
        ),
      );
      return existing.id;
    } else {
      return into(localPollingStationsTable).insert(
        station.copyWith(departmentCode: deptCodeValue),
      );
    }
  }

  Future<void> savePollingStations(List<LocalPollingStationsTableCompanion> stations) async {
    for (final station in stations) {
      await insertPollingStation(station);
    }
  }

  Future<void> savePersoneros(List<LocalPersonerosTableCompanion> personeros) async {
    for (final personero in personeros) {
      final dni = personero.dni.value;
      final existing = await (select(localPersonerosTable)..where((t) => t.dni.equals(dni))).getSingleOrNull();
      if (existing != null) {
        await (update(localPersonerosTable)..where((t) => t.dni.equals(dni))).write(
          LocalPersonerosTableCompanion(
            firstName: personero.firstName,
            lastName: personero.lastName,
            pollingStationCode: personero.pollingStationCode,
            phoneNumber: personero.phoneNumber,
            email: personero.email,
            isActive: personero.isActive,
          ),
        );
      } else {
        // Usar insert con modo insertOrIgnore para evitar duplicados por dni en dispositivos nuevos.
        // No usamos insertOrReplace porque tiene conflicto en id (PK autoincremental), no en dni.
        await customInsert(
          'INSERT OR IGNORE INTO local_personeros_table (dni, first_name, last_name, polling_station_code, phone_number, email, is_active) VALUES (?, ?, ?, ?, ?, ?, ?)',
          variables: [
            Variable.withString(dni),
            Variable.withString(personero.firstName.value),
            Variable.withString(personero.lastName.value),
            Variable.withString(personero.pollingStationCode.value),
            Variable(personero.phoneNumber.value),
            Variable(personero.email.value),
            Variable.withBool(personero.isActive.value),
          ],
        );
      }
    }
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

  // ─── DAOs para Plantillas de Cédula (Ballot Templates) ────────────────────
  Future<String?> getBallotTemplateString(String pollingStationCode, int electoralLevelId) async {
    try {
      final rows = await customSelect(
        'SELECT template_json FROM local_ballot_templates_table WHERE polling_station_code = ? AND electoral_level_id = ? LIMIT 1',
        variables: [
          Variable.withString(pollingStationCode),
          Variable.withInt(electoralLevelId),
        ],
      ).get();

      if (rows.isNotEmpty) {
        return rows.first.read<String>('template_json');
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveBallotTemplateString(String pollingStationCode, int electoralLevelId, String templateJson) async {
    try {
      await customStatement('''
        CREATE TABLE IF NOT EXISTS local_ballot_templates_table (
          polling_station_code TEXT NOT NULL,
          electoral_level_id INTEGER NOT NULL,
          template_json TEXT NOT NULL,
          updated_at INTEGER NOT NULL,
          PRIMARY KEY (polling_station_code, electoral_level_id)
        )
      ''');

      await customInsert(
        'INSERT OR REPLACE INTO local_ballot_templates_table (polling_station_code, electoral_level_id, template_json, updated_at) VALUES (?, ?, ?, ?)',
        variables: [
          Variable.withString(pollingStationCode),
          Variable.withInt(electoralLevelId),
          Variable.withString(templateJson),
          Variable.withInt(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ],
      );
    } catch (_) {}
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
      await savePollingStations([
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
        // Mesas oficiales reales de Puerto Inca - Huánuco (Rango ONPE 021038 - 021056)
        LocalPollingStationsTableCompanion.insert(
          code: '021038',
          locationName: 'I.E. 32617 YUYAPICHIS',
          districtCode: const Value('001275'),
          districtName: const Value('YUYAPICHIS'),
          provinceName: const Value('PUERTO INCA'),
          departmentName: const Value('HUÁNUCO'),
          registeredVoters: const Value(300),
        ),
        LocalPollingStationsTableCompanion.insert(
          code: '021039',
          locationName: 'I.E. AGROPECUARIO PUERTO INCA',
          districtCode: const Value('001272'),
          districtName: const Value('PUERTO INCA'),
          provinceName: const Value('PUERTO INCA'),
          departmentName: const Value('HUÁNUCO'),
          registeredVoters: const Value(280),
        ),
        LocalPollingStationsTableCompanion.insert(
          code: '021040',
          locationName: 'I.E. 32223 CODO DEL POZUZO',
          districtCode: const Value('001274'),
          districtName: const Value('CODO DEL POZUZO'),
          provinceName: const Value('PUERTO INCA'),
          departmentName: const Value('HUÁNUCO'),
          registeredVoters: const Value(290),
        ),
        LocalPollingStationsTableCompanion.insert(
          code: '021041',
          locationName: 'I.E. TOURNAVISTA',
          districtCode: const Value('001272'),
          districtName: const Value('TOURNAVISTA'),
          provinceName: const Value('PUERTO INCA'),
          departmentName: const Value('HUÁNUCO'),
          registeredVoters: const Value(275),
        ),
      ]);
    } catch (_) {}

    try {
      final personeroCount = await (select(localPersonerosTable)..limit(1)).get();
      if (personeroCount.isEmpty) {
        await into(localPersonerosTable).insertOnConflictUpdate(
          LocalPersonerosTableCompanion.insert(
            dni: '44001122',
            firstName: 'Personero',
            lastName: 'Puerto Inca (Yuyapichis)',
            pollingStationCode: '021038',
            phoneNumber: const Value('+51 962 111 222'),
            email: const Value('personero.puertoinca@conteoya.pe'),
          ),
        );

        await into(localPersonerosTable).insertOnConflictUpdate(
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

    // Actualizar o sembrar Organizaciones Políticas con IDs canónicos de JEE/PostgreSQL
    await batch((b) {
      b.insertAllOnConflictUpdate(localPoliticalOrganizationsTable, [
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(1),
          name: 'ACCIÓN POPULAR',
          shortName: const Value('AP'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/4.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(2),
          name: 'PARTIDO DEMOCRÁTICO SOMOS PERÚ',
          shortName: const Value('SOMOS PERU'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/14.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(6),
          name: 'ALIANZA PARA EL PROGRESO',
          shortName: const Value('APP'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/1257.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(7),
          name: 'JUNTOS POR EL PERÚ',
          shortName: const Value('JP'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/1264.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(8),
          name: 'FUERZA POPULAR',
          shortName: const Value('FP'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/1366.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(17),
          name: 'AVANZA PAIS - PARTIDO DE INTEGRACION SOCIAL',
          shortName: const Value('AVANZA PAIS'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/2173.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(21),
          name: 'PODEMOS PERU',
          shortName: const Value('PODEMOS'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/2731.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(25),
          name: 'PARTIDO MORADO',
          shortName: const Value('PM'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/2840.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(26),
          name: 'PARTIDO FRENTE DE LA ESPERANZA 2021',
          shortName: const Value('FE 2021'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/2857.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(37),
          name: 'PARTIDO POLITICO PERU PRIMERO',
          shortName: const Value('PERU PRIMERO'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/2925.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(55),
          name: 'AHORA NACION - AN',
          shortName: const Value('AN'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/2980.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(65),
          name: 'ALIANZA ELECTORAL VENCEREMOS',
          shortName: const Value('VENCEREMOS'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/3028.png'),
        ),
        LocalPoliticalOrganizationsTableCompanion.insert(
          id: const Value(68),
          name: 'RENOVACIÓN POPULAR',
          shortName: const Value('RP'),
          logoUrl: const Value('https://stovotoinformadodev.blob.core.windows.net/contenedor-2/3040.png'),
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
