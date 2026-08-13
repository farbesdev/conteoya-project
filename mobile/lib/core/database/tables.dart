import 'package:drift/drift.dart';

@DataClassName('LocalAct')
class LocalActsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientActUuid => text().unique()();
  IntColumn get electionId => integer()();
  IntColumn get electoralLevelId => integer()();
  TextColumn get pollingStationCode => text()();
  TextColumn get actCode => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('DRAFT'))();
  IntColumn get serverActId => integer().nullable()();
  DateTimeColumn get capturedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get confirmedAt => dateTime().nullable()();
}

@DataClassName('LocalActTotal')
class LocalActTotalsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientActUuid => text().unique()();
  IntColumn get registeredVoters => integer()();
  IntColumn get votersWhoVoted => integer()();
  IntColumn get totalVotes => integer()();
  IntColumn get blankVotes => integer().withDefault(const Constant(0))();
  IntColumn get nullVotes => integer().withDefault(const Constant(0))();
  IntColumn get challengedVotes => integer().withDefault(const Constant(0))();
  BoolColumn get isValidTotal => boolean().withDefault(const Constant(true))();
}

@DataClassName('LocalActResult')
class LocalActResultsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientActUuid => text()();
  IntColumn get politicalOrganizationId => integer().nullable()();
  TextColumn get politicalOrganizationName => text().nullable()();
  IntColumn get electoralListId => integer().nullable()();
  IntColumn get candidateId => integer().nullable()();
  TextColumn get candidateName => text().nullable()();
  IntColumn get votes => integer().withDefault(const Constant(0))();
  TextColumn get source => text().withDefault(const Constant('MANUAL'))();
  RealColumn get confidence => real().nullable()();
}

@DataClassName('LocalActEvidence')
class LocalActEvidenceTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientActUuid => text()();
  TextColumn get localFilePath => text()();
  TextColumn get sha256Hash => text()();
  TextColumn get fileMime => text().withDefault(const Constant('image/jpeg'))();
  IntColumn get fileSizeBytes => integer()();
  IntColumn get widthPx => integer().nullable()();
  IntColumn get heightPx => integer().nullable()();
  TextColumn get storageKey => text().nullable()();
  BoolColumn get isUploaded => boolean().withDefault(const Constant(false))();
  DateTimeColumn get capturedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('LocalSyncOperation')
class LocalSyncOperationsTable extends Table {
  TextColumn get clientOperationId => text()(); // UUID
  TextColumn get deviceUuid => text().nullable()();
  TextColumn get personeroId => text().nullable()();
  TextColumn get entityType => text()(); // 'acts' | 'act_evidence'
  TextColumn get entityId => text()();
  TextColumn get operation => text().withDefault(const Constant('CREATE'))();
  TextColumn get payloadJson => text()();
  TextColumn get checksum => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get processedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {clientOperationId};
}

@DataClassName('LocalPollingStation')
class LocalPollingStationsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()();
  TextColumn get locationName => text()();
  TextColumn get districtCode => text().withDefault(const Constant('150101'))();
  TextColumn get districtName => text().withDefault(const Constant('LIMA - CERCADO'))();
  TextColumn get provinceName => text().withDefault(const Constant('LIMA'))();
  TextColumn get departmentName => text().withDefault(const Constant('LIMA'))();
  IntColumn get registeredVoters => integer().withDefault(const Constant(300))();
  TextColumn get status => text().withDefault(const Constant('ACTIVA'))();
}

@DataClassName('LocalPoliticalOrganization')
class LocalPoliticalOrganizationsTable extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get shortName => text().nullable()();
  TextColumn get logoUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalPersonero')
class LocalPersonerosTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dni => text().unique()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get pollingStationCode => text()();
  TextColumn get phoneNumber => text().nullable()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

