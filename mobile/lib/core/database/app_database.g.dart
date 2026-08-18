// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalActsTableTable extends LocalActsTable
    with TableInfo<$LocalActsTableTable, LocalAct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalActsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientActUuidMeta = const VerificationMeta(
    'clientActUuid',
  );
  @override
  late final GeneratedColumn<String> clientActUuid = GeneratedColumn<String>(
    'client_act_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _electionIdMeta = const VerificationMeta(
    'electionId',
  );
  @override
  late final GeneratedColumn<int> electionId = GeneratedColumn<int>(
    'election_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _electoralLevelIdMeta = const VerificationMeta(
    'electoralLevelId',
  );
  @override
  late final GeneratedColumn<int> electoralLevelId = GeneratedColumn<int>(
    'electoral_level_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pollingStationCodeMeta =
      const VerificationMeta('pollingStationCode');
  @override
  late final GeneratedColumn<String> pollingStationCode =
      GeneratedColumn<String>(
        'polling_station_code',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _actCodeMeta = const VerificationMeta(
    'actCode',
  );
  @override
  late final GeneratedColumn<String> actCode = GeneratedColumn<String>(
    'act_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('DRAFT'),
  );
  static const VerificationMeta _serverActIdMeta = const VerificationMeta(
    'serverActId',
  );
  @override
  late final GeneratedColumn<int> serverActId = GeneratedColumn<int>(
    'server_act_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientActUuid,
    electionId,
    electoralLevelId,
    pollingStationCode,
    actCode,
    status,
    serverActId,
    capturedAt,
    confirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_acts_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_act_uuid')) {
      context.handle(
        _clientActUuidMeta,
        clientActUuid.isAcceptableOrUnknown(
          data['client_act_uuid']!,
          _clientActUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientActUuidMeta);
    }
    if (data.containsKey('election_id')) {
      context.handle(
        _electionIdMeta,
        electionId.isAcceptableOrUnknown(data['election_id']!, _electionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_electionIdMeta);
    }
    if (data.containsKey('electoral_level_id')) {
      context.handle(
        _electoralLevelIdMeta,
        electoralLevelId.isAcceptableOrUnknown(
          data['electoral_level_id']!,
          _electoralLevelIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_electoralLevelIdMeta);
    }
    if (data.containsKey('polling_station_code')) {
      context.handle(
        _pollingStationCodeMeta,
        pollingStationCode.isAcceptableOrUnknown(
          data['polling_station_code']!,
          _pollingStationCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pollingStationCodeMeta);
    }
    if (data.containsKey('act_code')) {
      context.handle(
        _actCodeMeta,
        actCode.isAcceptableOrUnknown(data['act_code']!, _actCodeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('server_act_id')) {
      context.handle(
        _serverActIdMeta,
        serverActId.isAcceptableOrUnknown(
          data['server_act_id']!,
          _serverActIdMeta,
        ),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientActUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_act_uuid'],
      )!,
      electionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}election_id'],
      )!,
      electoralLevelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}electoral_level_id'],
      )!,
      pollingStationCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}polling_station_code'],
      )!,
      actCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}act_code'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      serverActId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_act_id'],
      ),
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      ),
    );
  }

  @override
  $LocalActsTableTable createAlias(String alias) {
    return $LocalActsTableTable(attachedDatabase, alias);
  }
}

class LocalAct extends DataClass implements Insertable<LocalAct> {
  final int id;
  final String clientActUuid;
  final int electionId;
  final int electoralLevelId;
  final String pollingStationCode;
  final String? actCode;
  final String status;
  final int? serverActId;
  final DateTime capturedAt;
  final DateTime? confirmedAt;
  const LocalAct({
    required this.id,
    required this.clientActUuid,
    required this.electionId,
    required this.electoralLevelId,
    required this.pollingStationCode,
    this.actCode,
    required this.status,
    this.serverActId,
    required this.capturedAt,
    this.confirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_act_uuid'] = Variable<String>(clientActUuid);
    map['election_id'] = Variable<int>(electionId);
    map['electoral_level_id'] = Variable<int>(electoralLevelId);
    map['polling_station_code'] = Variable<String>(pollingStationCode);
    if (!nullToAbsent || actCode != null) {
      map['act_code'] = Variable<String>(actCode);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || serverActId != null) {
      map['server_act_id'] = Variable<int>(serverActId);
    }
    map['captured_at'] = Variable<DateTime>(capturedAt);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    return map;
  }

  LocalActsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalActsTableCompanion(
      id: Value(id),
      clientActUuid: Value(clientActUuid),
      electionId: Value(electionId),
      electoralLevelId: Value(electoralLevelId),
      pollingStationCode: Value(pollingStationCode),
      actCode: actCode == null && nullToAbsent
          ? const Value.absent()
          : Value(actCode),
      status: Value(status),
      serverActId: serverActId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverActId),
      capturedAt: Value(capturedAt),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
    );
  }

  factory LocalAct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAct(
      id: serializer.fromJson<int>(json['id']),
      clientActUuid: serializer.fromJson<String>(json['clientActUuid']),
      electionId: serializer.fromJson<int>(json['electionId']),
      electoralLevelId: serializer.fromJson<int>(json['electoralLevelId']),
      pollingStationCode: serializer.fromJson<String>(
        json['pollingStationCode'],
      ),
      actCode: serializer.fromJson<String?>(json['actCode']),
      status: serializer.fromJson<String>(json['status']),
      serverActId: serializer.fromJson<int?>(json['serverActId']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientActUuid': serializer.toJson<String>(clientActUuid),
      'electionId': serializer.toJson<int>(electionId),
      'electoralLevelId': serializer.toJson<int>(electoralLevelId),
      'pollingStationCode': serializer.toJson<String>(pollingStationCode),
      'actCode': serializer.toJson<String?>(actCode),
      'status': serializer.toJson<String>(status),
      'serverActId': serializer.toJson<int?>(serverActId),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
    };
  }

  LocalAct copyWith({
    int? id,
    String? clientActUuid,
    int? electionId,
    int? electoralLevelId,
    String? pollingStationCode,
    Value<String?> actCode = const Value.absent(),
    String? status,
    Value<int?> serverActId = const Value.absent(),
    DateTime? capturedAt,
    Value<DateTime?> confirmedAt = const Value.absent(),
  }) => LocalAct(
    id: id ?? this.id,
    clientActUuid: clientActUuid ?? this.clientActUuid,
    electionId: electionId ?? this.electionId,
    electoralLevelId: electoralLevelId ?? this.electoralLevelId,
    pollingStationCode: pollingStationCode ?? this.pollingStationCode,
    actCode: actCode.present ? actCode.value : this.actCode,
    status: status ?? this.status,
    serverActId: serverActId.present ? serverActId.value : this.serverActId,
    capturedAt: capturedAt ?? this.capturedAt,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
  );
  LocalAct copyWithCompanion(LocalActsTableCompanion data) {
    return LocalAct(
      id: data.id.present ? data.id.value : this.id,
      clientActUuid: data.clientActUuid.present
          ? data.clientActUuid.value
          : this.clientActUuid,
      electionId: data.electionId.present
          ? data.electionId.value
          : this.electionId,
      electoralLevelId: data.electoralLevelId.present
          ? data.electoralLevelId.value
          : this.electoralLevelId,
      pollingStationCode: data.pollingStationCode.present
          ? data.pollingStationCode.value
          : this.pollingStationCode,
      actCode: data.actCode.present ? data.actCode.value : this.actCode,
      status: data.status.present ? data.status.value : this.status,
      serverActId: data.serverActId.present
          ? data.serverActId.value
          : this.serverActId,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAct(')
          ..write('id: $id, ')
          ..write('clientActUuid: $clientActUuid, ')
          ..write('electionId: $electionId, ')
          ..write('electoralLevelId: $electoralLevelId, ')
          ..write('pollingStationCode: $pollingStationCode, ')
          ..write('actCode: $actCode, ')
          ..write('status: $status, ')
          ..write('serverActId: $serverActId, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientActUuid,
    electionId,
    electoralLevelId,
    pollingStationCode,
    actCode,
    status,
    serverActId,
    capturedAt,
    confirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAct &&
          other.id == this.id &&
          other.clientActUuid == this.clientActUuid &&
          other.electionId == this.electionId &&
          other.electoralLevelId == this.electoralLevelId &&
          other.pollingStationCode == this.pollingStationCode &&
          other.actCode == this.actCode &&
          other.status == this.status &&
          other.serverActId == this.serverActId &&
          other.capturedAt == this.capturedAt &&
          other.confirmedAt == this.confirmedAt);
}

class LocalActsTableCompanion extends UpdateCompanion<LocalAct> {
  final Value<int> id;
  final Value<String> clientActUuid;
  final Value<int> electionId;
  final Value<int> electoralLevelId;
  final Value<String> pollingStationCode;
  final Value<String?> actCode;
  final Value<String> status;
  final Value<int?> serverActId;
  final Value<DateTime> capturedAt;
  final Value<DateTime?> confirmedAt;
  const LocalActsTableCompanion({
    this.id = const Value.absent(),
    this.clientActUuid = const Value.absent(),
    this.electionId = const Value.absent(),
    this.electoralLevelId = const Value.absent(),
    this.pollingStationCode = const Value.absent(),
    this.actCode = const Value.absent(),
    this.status = const Value.absent(),
    this.serverActId = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
  });
  LocalActsTableCompanion.insert({
    this.id = const Value.absent(),
    required String clientActUuid,
    required int electionId,
    required int electoralLevelId,
    required String pollingStationCode,
    this.actCode = const Value.absent(),
    this.status = const Value.absent(),
    this.serverActId = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
  }) : clientActUuid = Value(clientActUuid),
       electionId = Value(electionId),
       electoralLevelId = Value(electoralLevelId),
       pollingStationCode = Value(pollingStationCode);
  static Insertable<LocalAct> custom({
    Expression<int>? id,
    Expression<String>? clientActUuid,
    Expression<int>? electionId,
    Expression<int>? electoralLevelId,
    Expression<String>? pollingStationCode,
    Expression<String>? actCode,
    Expression<String>? status,
    Expression<int>? serverActId,
    Expression<DateTime>? capturedAt,
    Expression<DateTime>? confirmedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientActUuid != null) 'client_act_uuid': clientActUuid,
      if (electionId != null) 'election_id': electionId,
      if (electoralLevelId != null) 'electoral_level_id': electoralLevelId,
      if (pollingStationCode != null)
        'polling_station_code': pollingStationCode,
      if (actCode != null) 'act_code': actCode,
      if (status != null) 'status': status,
      if (serverActId != null) 'server_act_id': serverActId,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
    });
  }

  LocalActsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? clientActUuid,
    Value<int>? electionId,
    Value<int>? electoralLevelId,
    Value<String>? pollingStationCode,
    Value<String?>? actCode,
    Value<String>? status,
    Value<int?>? serverActId,
    Value<DateTime>? capturedAt,
    Value<DateTime?>? confirmedAt,
  }) {
    return LocalActsTableCompanion(
      id: id ?? this.id,
      clientActUuid: clientActUuid ?? this.clientActUuid,
      electionId: electionId ?? this.electionId,
      electoralLevelId: electoralLevelId ?? this.electoralLevelId,
      pollingStationCode: pollingStationCode ?? this.pollingStationCode,
      actCode: actCode ?? this.actCode,
      status: status ?? this.status,
      serverActId: serverActId ?? this.serverActId,
      capturedAt: capturedAt ?? this.capturedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientActUuid.present) {
      map['client_act_uuid'] = Variable<String>(clientActUuid.value);
    }
    if (electionId.present) {
      map['election_id'] = Variable<int>(electionId.value);
    }
    if (electoralLevelId.present) {
      map['electoral_level_id'] = Variable<int>(electoralLevelId.value);
    }
    if (pollingStationCode.present) {
      map['polling_station_code'] = Variable<String>(pollingStationCode.value);
    }
    if (actCode.present) {
      map['act_code'] = Variable<String>(actCode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (serverActId.present) {
      map['server_act_id'] = Variable<int>(serverActId.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalActsTableCompanion(')
          ..write('id: $id, ')
          ..write('clientActUuid: $clientActUuid, ')
          ..write('electionId: $electionId, ')
          ..write('electoralLevelId: $electoralLevelId, ')
          ..write('pollingStationCode: $pollingStationCode, ')
          ..write('actCode: $actCode, ')
          ..write('status: $status, ')
          ..write('serverActId: $serverActId, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalActTotalsTableTable extends LocalActTotalsTable
    with TableInfo<$LocalActTotalsTableTable, LocalActTotal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalActTotalsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientActUuidMeta = const VerificationMeta(
    'clientActUuid',
  );
  @override
  late final GeneratedColumn<String> clientActUuid = GeneratedColumn<String>(
    'client_act_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _registeredVotersMeta = const VerificationMeta(
    'registeredVoters',
  );
  @override
  late final GeneratedColumn<int> registeredVoters = GeneratedColumn<int>(
    'registered_voters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _votersWhoVotedMeta = const VerificationMeta(
    'votersWhoVoted',
  );
  @override
  late final GeneratedColumn<int> votersWhoVoted = GeneratedColumn<int>(
    'voters_who_voted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalVotesMeta = const VerificationMeta(
    'totalVotes',
  );
  @override
  late final GeneratedColumn<int> totalVotes = GeneratedColumn<int>(
    'total_votes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _blankVotesMeta = const VerificationMeta(
    'blankVotes',
  );
  @override
  late final GeneratedColumn<int> blankVotes = GeneratedColumn<int>(
    'blank_votes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nullVotesMeta = const VerificationMeta(
    'nullVotes',
  );
  @override
  late final GeneratedColumn<int> nullVotes = GeneratedColumn<int>(
    'null_votes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _challengedVotesMeta = const VerificationMeta(
    'challengedVotes',
  );
  @override
  late final GeneratedColumn<int> challengedVotes = GeneratedColumn<int>(
    'challenged_votes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isValidTotalMeta = const VerificationMeta(
    'isValidTotal',
  );
  @override
  late final GeneratedColumn<bool> isValidTotal = GeneratedColumn<bool>(
    'is_valid_total',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_valid_total" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientActUuid,
    registeredVoters,
    votersWhoVoted,
    totalVotes,
    blankVotes,
    nullVotes,
    challengedVotes,
    isValidTotal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_act_totals_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalActTotal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_act_uuid')) {
      context.handle(
        _clientActUuidMeta,
        clientActUuid.isAcceptableOrUnknown(
          data['client_act_uuid']!,
          _clientActUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientActUuidMeta);
    }
    if (data.containsKey('registered_voters')) {
      context.handle(
        _registeredVotersMeta,
        registeredVoters.isAcceptableOrUnknown(
          data['registered_voters']!,
          _registeredVotersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_registeredVotersMeta);
    }
    if (data.containsKey('voters_who_voted')) {
      context.handle(
        _votersWhoVotedMeta,
        votersWhoVoted.isAcceptableOrUnknown(
          data['voters_who_voted']!,
          _votersWhoVotedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_votersWhoVotedMeta);
    }
    if (data.containsKey('total_votes')) {
      context.handle(
        _totalVotesMeta,
        totalVotes.isAcceptableOrUnknown(data['total_votes']!, _totalVotesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalVotesMeta);
    }
    if (data.containsKey('blank_votes')) {
      context.handle(
        _blankVotesMeta,
        blankVotes.isAcceptableOrUnknown(data['blank_votes']!, _blankVotesMeta),
      );
    }
    if (data.containsKey('null_votes')) {
      context.handle(
        _nullVotesMeta,
        nullVotes.isAcceptableOrUnknown(data['null_votes']!, _nullVotesMeta),
      );
    }
    if (data.containsKey('challenged_votes')) {
      context.handle(
        _challengedVotesMeta,
        challengedVotes.isAcceptableOrUnknown(
          data['challenged_votes']!,
          _challengedVotesMeta,
        ),
      );
    }
    if (data.containsKey('is_valid_total')) {
      context.handle(
        _isValidTotalMeta,
        isValidTotal.isAcceptableOrUnknown(
          data['is_valid_total']!,
          _isValidTotalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalActTotal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalActTotal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientActUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_act_uuid'],
      )!,
      registeredVoters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}registered_voters'],
      )!,
      votersWhoVoted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}voters_who_voted'],
      )!,
      totalVotes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_votes'],
      )!,
      blankVotes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}blank_votes'],
      )!,
      nullVotes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}null_votes'],
      )!,
      challengedVotes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}challenged_votes'],
      )!,
      isValidTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_valid_total'],
      )!,
    );
  }

  @override
  $LocalActTotalsTableTable createAlias(String alias) {
    return $LocalActTotalsTableTable(attachedDatabase, alias);
  }
}

class LocalActTotal extends DataClass implements Insertable<LocalActTotal> {
  final int id;
  final String clientActUuid;
  final int registeredVoters;
  final int votersWhoVoted;
  final int totalVotes;
  final int blankVotes;
  final int nullVotes;
  final int challengedVotes;
  final bool isValidTotal;
  const LocalActTotal({
    required this.id,
    required this.clientActUuid,
    required this.registeredVoters,
    required this.votersWhoVoted,
    required this.totalVotes,
    required this.blankVotes,
    required this.nullVotes,
    required this.challengedVotes,
    required this.isValidTotal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_act_uuid'] = Variable<String>(clientActUuid);
    map['registered_voters'] = Variable<int>(registeredVoters);
    map['voters_who_voted'] = Variable<int>(votersWhoVoted);
    map['total_votes'] = Variable<int>(totalVotes);
    map['blank_votes'] = Variable<int>(blankVotes);
    map['null_votes'] = Variable<int>(nullVotes);
    map['challenged_votes'] = Variable<int>(challengedVotes);
    map['is_valid_total'] = Variable<bool>(isValidTotal);
    return map;
  }

  LocalActTotalsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalActTotalsTableCompanion(
      id: Value(id),
      clientActUuid: Value(clientActUuid),
      registeredVoters: Value(registeredVoters),
      votersWhoVoted: Value(votersWhoVoted),
      totalVotes: Value(totalVotes),
      blankVotes: Value(blankVotes),
      nullVotes: Value(nullVotes),
      challengedVotes: Value(challengedVotes),
      isValidTotal: Value(isValidTotal),
    );
  }

  factory LocalActTotal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalActTotal(
      id: serializer.fromJson<int>(json['id']),
      clientActUuid: serializer.fromJson<String>(json['clientActUuid']),
      registeredVoters: serializer.fromJson<int>(json['registeredVoters']),
      votersWhoVoted: serializer.fromJson<int>(json['votersWhoVoted']),
      totalVotes: serializer.fromJson<int>(json['totalVotes']),
      blankVotes: serializer.fromJson<int>(json['blankVotes']),
      nullVotes: serializer.fromJson<int>(json['nullVotes']),
      challengedVotes: serializer.fromJson<int>(json['challengedVotes']),
      isValidTotal: serializer.fromJson<bool>(json['isValidTotal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientActUuid': serializer.toJson<String>(clientActUuid),
      'registeredVoters': serializer.toJson<int>(registeredVoters),
      'votersWhoVoted': serializer.toJson<int>(votersWhoVoted),
      'totalVotes': serializer.toJson<int>(totalVotes),
      'blankVotes': serializer.toJson<int>(blankVotes),
      'nullVotes': serializer.toJson<int>(nullVotes),
      'challengedVotes': serializer.toJson<int>(challengedVotes),
      'isValidTotal': serializer.toJson<bool>(isValidTotal),
    };
  }

  LocalActTotal copyWith({
    int? id,
    String? clientActUuid,
    int? registeredVoters,
    int? votersWhoVoted,
    int? totalVotes,
    int? blankVotes,
    int? nullVotes,
    int? challengedVotes,
    bool? isValidTotal,
  }) => LocalActTotal(
    id: id ?? this.id,
    clientActUuid: clientActUuid ?? this.clientActUuid,
    registeredVoters: registeredVoters ?? this.registeredVoters,
    votersWhoVoted: votersWhoVoted ?? this.votersWhoVoted,
    totalVotes: totalVotes ?? this.totalVotes,
    blankVotes: blankVotes ?? this.blankVotes,
    nullVotes: nullVotes ?? this.nullVotes,
    challengedVotes: challengedVotes ?? this.challengedVotes,
    isValidTotal: isValidTotal ?? this.isValidTotal,
  );
  LocalActTotal copyWithCompanion(LocalActTotalsTableCompanion data) {
    return LocalActTotal(
      id: data.id.present ? data.id.value : this.id,
      clientActUuid: data.clientActUuid.present
          ? data.clientActUuid.value
          : this.clientActUuid,
      registeredVoters: data.registeredVoters.present
          ? data.registeredVoters.value
          : this.registeredVoters,
      votersWhoVoted: data.votersWhoVoted.present
          ? data.votersWhoVoted.value
          : this.votersWhoVoted,
      totalVotes: data.totalVotes.present
          ? data.totalVotes.value
          : this.totalVotes,
      blankVotes: data.blankVotes.present
          ? data.blankVotes.value
          : this.blankVotes,
      nullVotes: data.nullVotes.present ? data.nullVotes.value : this.nullVotes,
      challengedVotes: data.challengedVotes.present
          ? data.challengedVotes.value
          : this.challengedVotes,
      isValidTotal: data.isValidTotal.present
          ? data.isValidTotal.value
          : this.isValidTotal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalActTotal(')
          ..write('id: $id, ')
          ..write('clientActUuid: $clientActUuid, ')
          ..write('registeredVoters: $registeredVoters, ')
          ..write('votersWhoVoted: $votersWhoVoted, ')
          ..write('totalVotes: $totalVotes, ')
          ..write('blankVotes: $blankVotes, ')
          ..write('nullVotes: $nullVotes, ')
          ..write('challengedVotes: $challengedVotes, ')
          ..write('isValidTotal: $isValidTotal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientActUuid,
    registeredVoters,
    votersWhoVoted,
    totalVotes,
    blankVotes,
    nullVotes,
    challengedVotes,
    isValidTotal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalActTotal &&
          other.id == this.id &&
          other.clientActUuid == this.clientActUuid &&
          other.registeredVoters == this.registeredVoters &&
          other.votersWhoVoted == this.votersWhoVoted &&
          other.totalVotes == this.totalVotes &&
          other.blankVotes == this.blankVotes &&
          other.nullVotes == this.nullVotes &&
          other.challengedVotes == this.challengedVotes &&
          other.isValidTotal == this.isValidTotal);
}

class LocalActTotalsTableCompanion extends UpdateCompanion<LocalActTotal> {
  final Value<int> id;
  final Value<String> clientActUuid;
  final Value<int> registeredVoters;
  final Value<int> votersWhoVoted;
  final Value<int> totalVotes;
  final Value<int> blankVotes;
  final Value<int> nullVotes;
  final Value<int> challengedVotes;
  final Value<bool> isValidTotal;
  const LocalActTotalsTableCompanion({
    this.id = const Value.absent(),
    this.clientActUuid = const Value.absent(),
    this.registeredVoters = const Value.absent(),
    this.votersWhoVoted = const Value.absent(),
    this.totalVotes = const Value.absent(),
    this.blankVotes = const Value.absent(),
    this.nullVotes = const Value.absent(),
    this.challengedVotes = const Value.absent(),
    this.isValidTotal = const Value.absent(),
  });
  LocalActTotalsTableCompanion.insert({
    this.id = const Value.absent(),
    required String clientActUuid,
    required int registeredVoters,
    required int votersWhoVoted,
    required int totalVotes,
    this.blankVotes = const Value.absent(),
    this.nullVotes = const Value.absent(),
    this.challengedVotes = const Value.absent(),
    this.isValidTotal = const Value.absent(),
  }) : clientActUuid = Value(clientActUuid),
       registeredVoters = Value(registeredVoters),
       votersWhoVoted = Value(votersWhoVoted),
       totalVotes = Value(totalVotes);
  static Insertable<LocalActTotal> custom({
    Expression<int>? id,
    Expression<String>? clientActUuid,
    Expression<int>? registeredVoters,
    Expression<int>? votersWhoVoted,
    Expression<int>? totalVotes,
    Expression<int>? blankVotes,
    Expression<int>? nullVotes,
    Expression<int>? challengedVotes,
    Expression<bool>? isValidTotal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientActUuid != null) 'client_act_uuid': clientActUuid,
      if (registeredVoters != null) 'registered_voters': registeredVoters,
      if (votersWhoVoted != null) 'voters_who_voted': votersWhoVoted,
      if (totalVotes != null) 'total_votes': totalVotes,
      if (blankVotes != null) 'blank_votes': blankVotes,
      if (nullVotes != null) 'null_votes': nullVotes,
      if (challengedVotes != null) 'challenged_votes': challengedVotes,
      if (isValidTotal != null) 'is_valid_total': isValidTotal,
    });
  }

  LocalActTotalsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? clientActUuid,
    Value<int>? registeredVoters,
    Value<int>? votersWhoVoted,
    Value<int>? totalVotes,
    Value<int>? blankVotes,
    Value<int>? nullVotes,
    Value<int>? challengedVotes,
    Value<bool>? isValidTotal,
  }) {
    return LocalActTotalsTableCompanion(
      id: id ?? this.id,
      clientActUuid: clientActUuid ?? this.clientActUuid,
      registeredVoters: registeredVoters ?? this.registeredVoters,
      votersWhoVoted: votersWhoVoted ?? this.votersWhoVoted,
      totalVotes: totalVotes ?? this.totalVotes,
      blankVotes: blankVotes ?? this.blankVotes,
      nullVotes: nullVotes ?? this.nullVotes,
      challengedVotes: challengedVotes ?? this.challengedVotes,
      isValidTotal: isValidTotal ?? this.isValidTotal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientActUuid.present) {
      map['client_act_uuid'] = Variable<String>(clientActUuid.value);
    }
    if (registeredVoters.present) {
      map['registered_voters'] = Variable<int>(registeredVoters.value);
    }
    if (votersWhoVoted.present) {
      map['voters_who_voted'] = Variable<int>(votersWhoVoted.value);
    }
    if (totalVotes.present) {
      map['total_votes'] = Variable<int>(totalVotes.value);
    }
    if (blankVotes.present) {
      map['blank_votes'] = Variable<int>(blankVotes.value);
    }
    if (nullVotes.present) {
      map['null_votes'] = Variable<int>(nullVotes.value);
    }
    if (challengedVotes.present) {
      map['challenged_votes'] = Variable<int>(challengedVotes.value);
    }
    if (isValidTotal.present) {
      map['is_valid_total'] = Variable<bool>(isValidTotal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalActTotalsTableCompanion(')
          ..write('id: $id, ')
          ..write('clientActUuid: $clientActUuid, ')
          ..write('registeredVoters: $registeredVoters, ')
          ..write('votersWhoVoted: $votersWhoVoted, ')
          ..write('totalVotes: $totalVotes, ')
          ..write('blankVotes: $blankVotes, ')
          ..write('nullVotes: $nullVotes, ')
          ..write('challengedVotes: $challengedVotes, ')
          ..write('isValidTotal: $isValidTotal')
          ..write(')'))
        .toString();
  }
}

class $LocalActResultsTableTable extends LocalActResultsTable
    with TableInfo<$LocalActResultsTableTable, LocalActResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalActResultsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientActUuidMeta = const VerificationMeta(
    'clientActUuid',
  );
  @override
  late final GeneratedColumn<String> clientActUuid = GeneratedColumn<String>(
    'client_act_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _politicalOrganizationIdMeta =
      const VerificationMeta('politicalOrganizationId');
  @override
  late final GeneratedColumn<int> politicalOrganizationId =
      GeneratedColumn<int>(
        'political_organization_id',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _politicalOrganizationNameMeta =
      const VerificationMeta('politicalOrganizationName');
  @override
  late final GeneratedColumn<String> politicalOrganizationName =
      GeneratedColumn<String>(
        'political_organization_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _electoralListIdMeta = const VerificationMeta(
    'electoralListId',
  );
  @override
  late final GeneratedColumn<int> electoralListId = GeneratedColumn<int>(
    'electoral_list_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _candidateIdMeta = const VerificationMeta(
    'candidateId',
  );
  @override
  late final GeneratedColumn<int> candidateId = GeneratedColumn<int>(
    'candidate_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _candidateNameMeta = const VerificationMeta(
    'candidateName',
  );
  @override
  late final GeneratedColumn<String> candidateName = GeneratedColumn<String>(
    'candidate_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _votesMeta = const VerificationMeta('votes');
  @override
  late final GeneratedColumn<int> votes = GeneratedColumn<int>(
    'votes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('MANUAL'),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientActUuid,
    politicalOrganizationId,
    politicalOrganizationName,
    electoralListId,
    candidateId,
    candidateName,
    votes,
    source,
    confidence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_act_results_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalActResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_act_uuid')) {
      context.handle(
        _clientActUuidMeta,
        clientActUuid.isAcceptableOrUnknown(
          data['client_act_uuid']!,
          _clientActUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientActUuidMeta);
    }
    if (data.containsKey('political_organization_id')) {
      context.handle(
        _politicalOrganizationIdMeta,
        politicalOrganizationId.isAcceptableOrUnknown(
          data['political_organization_id']!,
          _politicalOrganizationIdMeta,
        ),
      );
    }
    if (data.containsKey('political_organization_name')) {
      context.handle(
        _politicalOrganizationNameMeta,
        politicalOrganizationName.isAcceptableOrUnknown(
          data['political_organization_name']!,
          _politicalOrganizationNameMeta,
        ),
      );
    }
    if (data.containsKey('electoral_list_id')) {
      context.handle(
        _electoralListIdMeta,
        electoralListId.isAcceptableOrUnknown(
          data['electoral_list_id']!,
          _electoralListIdMeta,
        ),
      );
    }
    if (data.containsKey('candidate_id')) {
      context.handle(
        _candidateIdMeta,
        candidateId.isAcceptableOrUnknown(
          data['candidate_id']!,
          _candidateIdMeta,
        ),
      );
    }
    if (data.containsKey('candidate_name')) {
      context.handle(
        _candidateNameMeta,
        candidateName.isAcceptableOrUnknown(
          data['candidate_name']!,
          _candidateNameMeta,
        ),
      );
    }
    if (data.containsKey('votes')) {
      context.handle(
        _votesMeta,
        votes.isAcceptableOrUnknown(data['votes']!, _votesMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalActResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalActResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientActUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_act_uuid'],
      )!,
      politicalOrganizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}political_organization_id'],
      ),
      politicalOrganizationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}political_organization_name'],
      ),
      electoralListId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}electoral_list_id'],
      ),
      candidateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}candidate_id'],
      ),
      candidateName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}candidate_name'],
      ),
      votes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}votes'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
    );
  }

  @override
  $LocalActResultsTableTable createAlias(String alias) {
    return $LocalActResultsTableTable(attachedDatabase, alias);
  }
}

class LocalActResult extends DataClass implements Insertable<LocalActResult> {
  final int id;
  final String clientActUuid;
  final int? politicalOrganizationId;
  final String? politicalOrganizationName;
  final int? electoralListId;
  final int? candidateId;
  final String? candidateName;
  final int votes;
  final String source;
  final double? confidence;
  const LocalActResult({
    required this.id,
    required this.clientActUuid,
    this.politicalOrganizationId,
    this.politicalOrganizationName,
    this.electoralListId,
    this.candidateId,
    this.candidateName,
    required this.votes,
    required this.source,
    this.confidence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_act_uuid'] = Variable<String>(clientActUuid);
    if (!nullToAbsent || politicalOrganizationId != null) {
      map['political_organization_id'] = Variable<int>(politicalOrganizationId);
    }
    if (!nullToAbsent || politicalOrganizationName != null) {
      map['political_organization_name'] = Variable<String>(
        politicalOrganizationName,
      );
    }
    if (!nullToAbsent || electoralListId != null) {
      map['electoral_list_id'] = Variable<int>(electoralListId);
    }
    if (!nullToAbsent || candidateId != null) {
      map['candidate_id'] = Variable<int>(candidateId);
    }
    if (!nullToAbsent || candidateName != null) {
      map['candidate_name'] = Variable<String>(candidateName);
    }
    map['votes'] = Variable<int>(votes);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    return map;
  }

  LocalActResultsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalActResultsTableCompanion(
      id: Value(id),
      clientActUuid: Value(clientActUuid),
      politicalOrganizationId: politicalOrganizationId == null && nullToAbsent
          ? const Value.absent()
          : Value(politicalOrganizationId),
      politicalOrganizationName:
          politicalOrganizationName == null && nullToAbsent
          ? const Value.absent()
          : Value(politicalOrganizationName),
      electoralListId: electoralListId == null && nullToAbsent
          ? const Value.absent()
          : Value(electoralListId),
      candidateId: candidateId == null && nullToAbsent
          ? const Value.absent()
          : Value(candidateId),
      candidateName: candidateName == null && nullToAbsent
          ? const Value.absent()
          : Value(candidateName),
      votes: Value(votes),
      source: Value(source),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
    );
  }

  factory LocalActResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalActResult(
      id: serializer.fromJson<int>(json['id']),
      clientActUuid: serializer.fromJson<String>(json['clientActUuid']),
      politicalOrganizationId: serializer.fromJson<int?>(
        json['politicalOrganizationId'],
      ),
      politicalOrganizationName: serializer.fromJson<String?>(
        json['politicalOrganizationName'],
      ),
      electoralListId: serializer.fromJson<int?>(json['electoralListId']),
      candidateId: serializer.fromJson<int?>(json['candidateId']),
      candidateName: serializer.fromJson<String?>(json['candidateName']),
      votes: serializer.fromJson<int>(json['votes']),
      source: serializer.fromJson<String>(json['source']),
      confidence: serializer.fromJson<double?>(json['confidence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientActUuid': serializer.toJson<String>(clientActUuid),
      'politicalOrganizationId': serializer.toJson<int?>(
        politicalOrganizationId,
      ),
      'politicalOrganizationName': serializer.toJson<String?>(
        politicalOrganizationName,
      ),
      'electoralListId': serializer.toJson<int?>(electoralListId),
      'candidateId': serializer.toJson<int?>(candidateId),
      'candidateName': serializer.toJson<String?>(candidateName),
      'votes': serializer.toJson<int>(votes),
      'source': serializer.toJson<String>(source),
      'confidence': serializer.toJson<double?>(confidence),
    };
  }

  LocalActResult copyWith({
    int? id,
    String? clientActUuid,
    Value<int?> politicalOrganizationId = const Value.absent(),
    Value<String?> politicalOrganizationName = const Value.absent(),
    Value<int?> electoralListId = const Value.absent(),
    Value<int?> candidateId = const Value.absent(),
    Value<String?> candidateName = const Value.absent(),
    int? votes,
    String? source,
    Value<double?> confidence = const Value.absent(),
  }) => LocalActResult(
    id: id ?? this.id,
    clientActUuid: clientActUuid ?? this.clientActUuid,
    politicalOrganizationId: politicalOrganizationId.present
        ? politicalOrganizationId.value
        : this.politicalOrganizationId,
    politicalOrganizationName: politicalOrganizationName.present
        ? politicalOrganizationName.value
        : this.politicalOrganizationName,
    electoralListId: electoralListId.present
        ? electoralListId.value
        : this.electoralListId,
    candidateId: candidateId.present ? candidateId.value : this.candidateId,
    candidateName: candidateName.present
        ? candidateName.value
        : this.candidateName,
    votes: votes ?? this.votes,
    source: source ?? this.source,
    confidence: confidence.present ? confidence.value : this.confidence,
  );
  LocalActResult copyWithCompanion(LocalActResultsTableCompanion data) {
    return LocalActResult(
      id: data.id.present ? data.id.value : this.id,
      clientActUuid: data.clientActUuid.present
          ? data.clientActUuid.value
          : this.clientActUuid,
      politicalOrganizationId: data.politicalOrganizationId.present
          ? data.politicalOrganizationId.value
          : this.politicalOrganizationId,
      politicalOrganizationName: data.politicalOrganizationName.present
          ? data.politicalOrganizationName.value
          : this.politicalOrganizationName,
      electoralListId: data.electoralListId.present
          ? data.electoralListId.value
          : this.electoralListId,
      candidateId: data.candidateId.present
          ? data.candidateId.value
          : this.candidateId,
      candidateName: data.candidateName.present
          ? data.candidateName.value
          : this.candidateName,
      votes: data.votes.present ? data.votes.value : this.votes,
      source: data.source.present ? data.source.value : this.source,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalActResult(')
          ..write('id: $id, ')
          ..write('clientActUuid: $clientActUuid, ')
          ..write('politicalOrganizationId: $politicalOrganizationId, ')
          ..write('politicalOrganizationName: $politicalOrganizationName, ')
          ..write('electoralListId: $electoralListId, ')
          ..write('candidateId: $candidateId, ')
          ..write('candidateName: $candidateName, ')
          ..write('votes: $votes, ')
          ..write('source: $source, ')
          ..write('confidence: $confidence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientActUuid,
    politicalOrganizationId,
    politicalOrganizationName,
    electoralListId,
    candidateId,
    candidateName,
    votes,
    source,
    confidence,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalActResult &&
          other.id == this.id &&
          other.clientActUuid == this.clientActUuid &&
          other.politicalOrganizationId == this.politicalOrganizationId &&
          other.politicalOrganizationName == this.politicalOrganizationName &&
          other.electoralListId == this.electoralListId &&
          other.candidateId == this.candidateId &&
          other.candidateName == this.candidateName &&
          other.votes == this.votes &&
          other.source == this.source &&
          other.confidence == this.confidence);
}

class LocalActResultsTableCompanion extends UpdateCompanion<LocalActResult> {
  final Value<int> id;
  final Value<String> clientActUuid;
  final Value<int?> politicalOrganizationId;
  final Value<String?> politicalOrganizationName;
  final Value<int?> electoralListId;
  final Value<int?> candidateId;
  final Value<String?> candidateName;
  final Value<int> votes;
  final Value<String> source;
  final Value<double?> confidence;
  const LocalActResultsTableCompanion({
    this.id = const Value.absent(),
    this.clientActUuid = const Value.absent(),
    this.politicalOrganizationId = const Value.absent(),
    this.politicalOrganizationName = const Value.absent(),
    this.electoralListId = const Value.absent(),
    this.candidateId = const Value.absent(),
    this.candidateName = const Value.absent(),
    this.votes = const Value.absent(),
    this.source = const Value.absent(),
    this.confidence = const Value.absent(),
  });
  LocalActResultsTableCompanion.insert({
    this.id = const Value.absent(),
    required String clientActUuid,
    this.politicalOrganizationId = const Value.absent(),
    this.politicalOrganizationName = const Value.absent(),
    this.electoralListId = const Value.absent(),
    this.candidateId = const Value.absent(),
    this.candidateName = const Value.absent(),
    this.votes = const Value.absent(),
    this.source = const Value.absent(),
    this.confidence = const Value.absent(),
  }) : clientActUuid = Value(clientActUuid);
  static Insertable<LocalActResult> custom({
    Expression<int>? id,
    Expression<String>? clientActUuid,
    Expression<int>? politicalOrganizationId,
    Expression<String>? politicalOrganizationName,
    Expression<int>? electoralListId,
    Expression<int>? candidateId,
    Expression<String>? candidateName,
    Expression<int>? votes,
    Expression<String>? source,
    Expression<double>? confidence,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientActUuid != null) 'client_act_uuid': clientActUuid,
      if (politicalOrganizationId != null)
        'political_organization_id': politicalOrganizationId,
      if (politicalOrganizationName != null)
        'political_organization_name': politicalOrganizationName,
      if (electoralListId != null) 'electoral_list_id': electoralListId,
      if (candidateId != null) 'candidate_id': candidateId,
      if (candidateName != null) 'candidate_name': candidateName,
      if (votes != null) 'votes': votes,
      if (source != null) 'source': source,
      if (confidence != null) 'confidence': confidence,
    });
  }

  LocalActResultsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? clientActUuid,
    Value<int?>? politicalOrganizationId,
    Value<String?>? politicalOrganizationName,
    Value<int?>? electoralListId,
    Value<int?>? candidateId,
    Value<String?>? candidateName,
    Value<int>? votes,
    Value<String>? source,
    Value<double?>? confidence,
  }) {
    return LocalActResultsTableCompanion(
      id: id ?? this.id,
      clientActUuid: clientActUuid ?? this.clientActUuid,
      politicalOrganizationId:
          politicalOrganizationId ?? this.politicalOrganizationId,
      politicalOrganizationName:
          politicalOrganizationName ?? this.politicalOrganizationName,
      electoralListId: electoralListId ?? this.electoralListId,
      candidateId: candidateId ?? this.candidateId,
      candidateName: candidateName ?? this.candidateName,
      votes: votes ?? this.votes,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientActUuid.present) {
      map['client_act_uuid'] = Variable<String>(clientActUuid.value);
    }
    if (politicalOrganizationId.present) {
      map['political_organization_id'] = Variable<int>(
        politicalOrganizationId.value,
      );
    }
    if (politicalOrganizationName.present) {
      map['political_organization_name'] = Variable<String>(
        politicalOrganizationName.value,
      );
    }
    if (electoralListId.present) {
      map['electoral_list_id'] = Variable<int>(electoralListId.value);
    }
    if (candidateId.present) {
      map['candidate_id'] = Variable<int>(candidateId.value);
    }
    if (candidateName.present) {
      map['candidate_name'] = Variable<String>(candidateName.value);
    }
    if (votes.present) {
      map['votes'] = Variable<int>(votes.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalActResultsTableCompanion(')
          ..write('id: $id, ')
          ..write('clientActUuid: $clientActUuid, ')
          ..write('politicalOrganizationId: $politicalOrganizationId, ')
          ..write('politicalOrganizationName: $politicalOrganizationName, ')
          ..write('electoralListId: $electoralListId, ')
          ..write('candidateId: $candidateId, ')
          ..write('candidateName: $candidateName, ')
          ..write('votes: $votes, ')
          ..write('source: $source, ')
          ..write('confidence: $confidence')
          ..write(')'))
        .toString();
  }
}

class $LocalActEvidenceTableTable extends LocalActEvidenceTable
    with TableInfo<$LocalActEvidenceTableTable, LocalActEvidence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalActEvidenceTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientActUuidMeta = const VerificationMeta(
    'clientActUuid',
  );
  @override
  late final GeneratedColumn<String> clientActUuid = GeneratedColumn<String>(
    'client_act_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localFilePathMeta = const VerificationMeta(
    'localFilePath',
  );
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256HashMeta = const VerificationMeta(
    'sha256Hash',
  );
  @override
  late final GeneratedColumn<String> sha256Hash = GeneratedColumn<String>(
    'sha256_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileMimeMeta = const VerificationMeta(
    'fileMime',
  );
  @override
  late final GeneratedColumn<String> fileMime = GeneratedColumn<String>(
    'file_mime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('image/jpeg'),
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthPxMeta = const VerificationMeta(
    'widthPx',
  );
  @override
  late final GeneratedColumn<int> widthPx = GeneratedColumn<int>(
    'width_px',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightPxMeta = const VerificationMeta(
    'heightPx',
  );
  @override
  late final GeneratedColumn<int> heightPx = GeneratedColumn<int>(
    'height_px',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storageKeyMeta = const VerificationMeta(
    'storageKey',
  );
  @override
  late final GeneratedColumn<String> storageKey = GeneratedColumn<String>(
    'storage_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isUploadedMeta = const VerificationMeta(
    'isUploaded',
  );
  @override
  late final GeneratedColumn<bool> isUploaded = GeneratedColumn<bool>(
    'is_uploaded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_uploaded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientActUuid,
    localFilePath,
    sha256Hash,
    fileMime,
    fileSizeBytes,
    widthPx,
    heightPx,
    storageKey,
    isUploaded,
    capturedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_act_evidence_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalActEvidence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_act_uuid')) {
      context.handle(
        _clientActUuidMeta,
        clientActUuid.isAcceptableOrUnknown(
          data['client_act_uuid']!,
          _clientActUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientActUuidMeta);
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
        _localFilePathMeta,
        localFilePath.isAcceptableOrUnknown(
          data['local_file_path']!,
          _localFilePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localFilePathMeta);
    }
    if (data.containsKey('sha256_hash')) {
      context.handle(
        _sha256HashMeta,
        sha256Hash.isAcceptableOrUnknown(data['sha256_hash']!, _sha256HashMeta),
      );
    } else if (isInserting) {
      context.missing(_sha256HashMeta);
    }
    if (data.containsKey('file_mime')) {
      context.handle(
        _fileMimeMeta,
        fileMime.isAcceptableOrUnknown(data['file_mime']!, _fileMimeMeta),
      );
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('width_px')) {
      context.handle(
        _widthPxMeta,
        widthPx.isAcceptableOrUnknown(data['width_px']!, _widthPxMeta),
      );
    }
    if (data.containsKey('height_px')) {
      context.handle(
        _heightPxMeta,
        heightPx.isAcceptableOrUnknown(data['height_px']!, _heightPxMeta),
      );
    }
    if (data.containsKey('storage_key')) {
      context.handle(
        _storageKeyMeta,
        storageKey.isAcceptableOrUnknown(data['storage_key']!, _storageKeyMeta),
      );
    }
    if (data.containsKey('is_uploaded')) {
      context.handle(
        _isUploadedMeta,
        isUploaded.isAcceptableOrUnknown(data['is_uploaded']!, _isUploadedMeta),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalActEvidence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalActEvidence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientActUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_act_uuid'],
      )!,
      localFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_path'],
      )!,
      sha256Hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256_hash'],
      )!,
      fileMime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_mime'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      widthPx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width_px'],
      ),
      heightPx: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height_px'],
      ),
      storageKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_key'],
      ),
      isUploaded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_uploaded'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
    );
  }

  @override
  $LocalActEvidenceTableTable createAlias(String alias) {
    return $LocalActEvidenceTableTable(attachedDatabase, alias);
  }
}

class LocalActEvidence extends DataClass
    implements Insertable<LocalActEvidence> {
  final int id;
  final String clientActUuid;
  final String localFilePath;
  final String sha256Hash;
  final String fileMime;
  final int fileSizeBytes;
  final int? widthPx;
  final int? heightPx;
  final String? storageKey;
  final bool isUploaded;
  final DateTime capturedAt;
  const LocalActEvidence({
    required this.id,
    required this.clientActUuid,
    required this.localFilePath,
    required this.sha256Hash,
    required this.fileMime,
    required this.fileSizeBytes,
    this.widthPx,
    this.heightPx,
    this.storageKey,
    required this.isUploaded,
    required this.capturedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_act_uuid'] = Variable<String>(clientActUuid);
    map['local_file_path'] = Variable<String>(localFilePath);
    map['sha256_hash'] = Variable<String>(sha256Hash);
    map['file_mime'] = Variable<String>(fileMime);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    if (!nullToAbsent || widthPx != null) {
      map['width_px'] = Variable<int>(widthPx);
    }
    if (!nullToAbsent || heightPx != null) {
      map['height_px'] = Variable<int>(heightPx);
    }
    if (!nullToAbsent || storageKey != null) {
      map['storage_key'] = Variable<String>(storageKey);
    }
    map['is_uploaded'] = Variable<bool>(isUploaded);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    return map;
  }

  LocalActEvidenceTableCompanion toCompanion(bool nullToAbsent) {
    return LocalActEvidenceTableCompanion(
      id: Value(id),
      clientActUuid: Value(clientActUuid),
      localFilePath: Value(localFilePath),
      sha256Hash: Value(sha256Hash),
      fileMime: Value(fileMime),
      fileSizeBytes: Value(fileSizeBytes),
      widthPx: widthPx == null && nullToAbsent
          ? const Value.absent()
          : Value(widthPx),
      heightPx: heightPx == null && nullToAbsent
          ? const Value.absent()
          : Value(heightPx),
      storageKey: storageKey == null && nullToAbsent
          ? const Value.absent()
          : Value(storageKey),
      isUploaded: Value(isUploaded),
      capturedAt: Value(capturedAt),
    );
  }

  factory LocalActEvidence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalActEvidence(
      id: serializer.fromJson<int>(json['id']),
      clientActUuid: serializer.fromJson<String>(json['clientActUuid']),
      localFilePath: serializer.fromJson<String>(json['localFilePath']),
      sha256Hash: serializer.fromJson<String>(json['sha256Hash']),
      fileMime: serializer.fromJson<String>(json['fileMime']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      widthPx: serializer.fromJson<int?>(json['widthPx']),
      heightPx: serializer.fromJson<int?>(json['heightPx']),
      storageKey: serializer.fromJson<String?>(json['storageKey']),
      isUploaded: serializer.fromJson<bool>(json['isUploaded']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientActUuid': serializer.toJson<String>(clientActUuid),
      'localFilePath': serializer.toJson<String>(localFilePath),
      'sha256Hash': serializer.toJson<String>(sha256Hash),
      'fileMime': serializer.toJson<String>(fileMime),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'widthPx': serializer.toJson<int?>(widthPx),
      'heightPx': serializer.toJson<int?>(heightPx),
      'storageKey': serializer.toJson<String?>(storageKey),
      'isUploaded': serializer.toJson<bool>(isUploaded),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
    };
  }

  LocalActEvidence copyWith({
    int? id,
    String? clientActUuid,
    String? localFilePath,
    String? sha256Hash,
    String? fileMime,
    int? fileSizeBytes,
    Value<int?> widthPx = const Value.absent(),
    Value<int?> heightPx = const Value.absent(),
    Value<String?> storageKey = const Value.absent(),
    bool? isUploaded,
    DateTime? capturedAt,
  }) => LocalActEvidence(
    id: id ?? this.id,
    clientActUuid: clientActUuid ?? this.clientActUuid,
    localFilePath: localFilePath ?? this.localFilePath,
    sha256Hash: sha256Hash ?? this.sha256Hash,
    fileMime: fileMime ?? this.fileMime,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    widthPx: widthPx.present ? widthPx.value : this.widthPx,
    heightPx: heightPx.present ? heightPx.value : this.heightPx,
    storageKey: storageKey.present ? storageKey.value : this.storageKey,
    isUploaded: isUploaded ?? this.isUploaded,
    capturedAt: capturedAt ?? this.capturedAt,
  );
  LocalActEvidence copyWithCompanion(LocalActEvidenceTableCompanion data) {
    return LocalActEvidence(
      id: data.id.present ? data.id.value : this.id,
      clientActUuid: data.clientActUuid.present
          ? data.clientActUuid.value
          : this.clientActUuid,
      localFilePath: data.localFilePath.present
          ? data.localFilePath.value
          : this.localFilePath,
      sha256Hash: data.sha256Hash.present
          ? data.sha256Hash.value
          : this.sha256Hash,
      fileMime: data.fileMime.present ? data.fileMime.value : this.fileMime,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      widthPx: data.widthPx.present ? data.widthPx.value : this.widthPx,
      heightPx: data.heightPx.present ? data.heightPx.value : this.heightPx,
      storageKey: data.storageKey.present
          ? data.storageKey.value
          : this.storageKey,
      isUploaded: data.isUploaded.present
          ? data.isUploaded.value
          : this.isUploaded,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalActEvidence(')
          ..write('id: $id, ')
          ..write('clientActUuid: $clientActUuid, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('fileMime: $fileMime, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('widthPx: $widthPx, ')
          ..write('heightPx: $heightPx, ')
          ..write('storageKey: $storageKey, ')
          ..write('isUploaded: $isUploaded, ')
          ..write('capturedAt: $capturedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientActUuid,
    localFilePath,
    sha256Hash,
    fileMime,
    fileSizeBytes,
    widthPx,
    heightPx,
    storageKey,
    isUploaded,
    capturedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalActEvidence &&
          other.id == this.id &&
          other.clientActUuid == this.clientActUuid &&
          other.localFilePath == this.localFilePath &&
          other.sha256Hash == this.sha256Hash &&
          other.fileMime == this.fileMime &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.widthPx == this.widthPx &&
          other.heightPx == this.heightPx &&
          other.storageKey == this.storageKey &&
          other.isUploaded == this.isUploaded &&
          other.capturedAt == this.capturedAt);
}

class LocalActEvidenceTableCompanion extends UpdateCompanion<LocalActEvidence> {
  final Value<int> id;
  final Value<String> clientActUuid;
  final Value<String> localFilePath;
  final Value<String> sha256Hash;
  final Value<String> fileMime;
  final Value<int> fileSizeBytes;
  final Value<int?> widthPx;
  final Value<int?> heightPx;
  final Value<String?> storageKey;
  final Value<bool> isUploaded;
  final Value<DateTime> capturedAt;
  const LocalActEvidenceTableCompanion({
    this.id = const Value.absent(),
    this.clientActUuid = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.sha256Hash = const Value.absent(),
    this.fileMime = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.widthPx = const Value.absent(),
    this.heightPx = const Value.absent(),
    this.storageKey = const Value.absent(),
    this.isUploaded = const Value.absent(),
    this.capturedAt = const Value.absent(),
  });
  LocalActEvidenceTableCompanion.insert({
    this.id = const Value.absent(),
    required String clientActUuid,
    required String localFilePath,
    required String sha256Hash,
    this.fileMime = const Value.absent(),
    required int fileSizeBytes,
    this.widthPx = const Value.absent(),
    this.heightPx = const Value.absent(),
    this.storageKey = const Value.absent(),
    this.isUploaded = const Value.absent(),
    this.capturedAt = const Value.absent(),
  }) : clientActUuid = Value(clientActUuid),
       localFilePath = Value(localFilePath),
       sha256Hash = Value(sha256Hash),
       fileSizeBytes = Value(fileSizeBytes);
  static Insertable<LocalActEvidence> custom({
    Expression<int>? id,
    Expression<String>? clientActUuid,
    Expression<String>? localFilePath,
    Expression<String>? sha256Hash,
    Expression<String>? fileMime,
    Expression<int>? fileSizeBytes,
    Expression<int>? widthPx,
    Expression<int>? heightPx,
    Expression<String>? storageKey,
    Expression<bool>? isUploaded,
    Expression<DateTime>? capturedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientActUuid != null) 'client_act_uuid': clientActUuid,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (sha256Hash != null) 'sha256_hash': sha256Hash,
      if (fileMime != null) 'file_mime': fileMime,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (widthPx != null) 'width_px': widthPx,
      if (heightPx != null) 'height_px': heightPx,
      if (storageKey != null) 'storage_key': storageKey,
      if (isUploaded != null) 'is_uploaded': isUploaded,
      if (capturedAt != null) 'captured_at': capturedAt,
    });
  }

  LocalActEvidenceTableCompanion copyWith({
    Value<int>? id,
    Value<String>? clientActUuid,
    Value<String>? localFilePath,
    Value<String>? sha256Hash,
    Value<String>? fileMime,
    Value<int>? fileSizeBytes,
    Value<int?>? widthPx,
    Value<int?>? heightPx,
    Value<String?>? storageKey,
    Value<bool>? isUploaded,
    Value<DateTime>? capturedAt,
  }) {
    return LocalActEvidenceTableCompanion(
      id: id ?? this.id,
      clientActUuid: clientActUuid ?? this.clientActUuid,
      localFilePath: localFilePath ?? this.localFilePath,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      fileMime: fileMime ?? this.fileMime,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      widthPx: widthPx ?? this.widthPx,
      heightPx: heightPx ?? this.heightPx,
      storageKey: storageKey ?? this.storageKey,
      isUploaded: isUploaded ?? this.isUploaded,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientActUuid.present) {
      map['client_act_uuid'] = Variable<String>(clientActUuid.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (sha256Hash.present) {
      map['sha256_hash'] = Variable<String>(sha256Hash.value);
    }
    if (fileMime.present) {
      map['file_mime'] = Variable<String>(fileMime.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (widthPx.present) {
      map['width_px'] = Variable<int>(widthPx.value);
    }
    if (heightPx.present) {
      map['height_px'] = Variable<int>(heightPx.value);
    }
    if (storageKey.present) {
      map['storage_key'] = Variable<String>(storageKey.value);
    }
    if (isUploaded.present) {
      map['is_uploaded'] = Variable<bool>(isUploaded.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalActEvidenceTableCompanion(')
          ..write('id: $id, ')
          ..write('clientActUuid: $clientActUuid, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('fileMime: $fileMime, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('widthPx: $widthPx, ')
          ..write('heightPx: $heightPx, ')
          ..write('storageKey: $storageKey, ')
          ..write('isUploaded: $isUploaded, ')
          ..write('capturedAt: $capturedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncOperationsTableTable extends LocalSyncOperationsTable
    with TableInfo<$LocalSyncOperationsTableTable, LocalSyncOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncOperationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientOperationIdMeta = const VerificationMeta(
    'clientOperationId',
  );
  @override
  late final GeneratedColumn<String> clientOperationId =
      GeneratedColumn<String>(
        'client_operation_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _deviceUuidMeta = const VerificationMeta(
    'deviceUuid',
  );
  @override
  late final GeneratedColumn<String> deviceUuid = GeneratedColumn<String>(
    'device_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personeroIdMeta = const VerificationMeta(
    'personeroId',
  );
  @override
  late final GeneratedColumn<String> personeroId = GeneratedColumn<String>(
    'personero_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CREATE'),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledAtMeta = const VerificationMeta(
    'scheduledAt',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAt = GeneratedColumn<DateTime>(
    'scheduled_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _processedAtMeta = const VerificationMeta(
    'processedAt',
  );
  @override
  late final GeneratedColumn<DateTime> processedAt = GeneratedColumn<DateTime>(
    'processed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientOperationId,
    deviceUuid,
    personeroId,
    entityType,
    entityId,
    operation,
    payloadJson,
    checksum,
    attempts,
    status,
    lastError,
    scheduledAt,
    processedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_operations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_operation_id')) {
      context.handle(
        _clientOperationIdMeta,
        clientOperationId.isAcceptableOrUnknown(
          data['client_operation_id']!,
          _clientOperationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientOperationIdMeta);
    }
    if (data.containsKey('device_uuid')) {
      context.handle(
        _deviceUuidMeta,
        deviceUuid.isAcceptableOrUnknown(data['device_uuid']!, _deviceUuidMeta),
      );
    }
    if (data.containsKey('personero_id')) {
      context.handle(
        _personeroIdMeta,
        personeroId.isAcceptableOrUnknown(
          data['personero_id']!,
          _personeroIdMeta,
        ),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('scheduled_at')) {
      context.handle(
        _scheduledAtMeta,
        scheduledAt.isAcceptableOrUnknown(
          data['scheduled_at']!,
          _scheduledAtMeta,
        ),
      );
    }
    if (data.containsKey('processed_at')) {
      context.handle(
        _processedAtMeta,
        processedAt.isAcceptableOrUnknown(
          data['processed_at']!,
          _processedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientOperationId};
  @override
  LocalSyncOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncOperation(
      clientOperationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_operation_id'],
      )!,
      deviceUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_uuid'],
      ),
      personeroId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personero_id'],
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      scheduledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at'],
      )!,
      processedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}processed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalSyncOperationsTableTable createAlias(String alias) {
    return $LocalSyncOperationsTableTable(attachedDatabase, alias);
  }
}

class LocalSyncOperation extends DataClass
    implements Insertable<LocalSyncOperation> {
  final String clientOperationId;
  final String? deviceUuid;
  final String? personeroId;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final String? checksum;
  final int attempts;
  final String status;
  final String? lastError;
  final DateTime scheduledAt;
  final DateTime? processedAt;
  final DateTime createdAt;
  const LocalSyncOperation({
    required this.clientOperationId,
    this.deviceUuid,
    this.personeroId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    this.checksum,
    required this.attempts,
    required this.status,
    this.lastError,
    required this.scheduledAt,
    this.processedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_operation_id'] = Variable<String>(clientOperationId);
    if (!nullToAbsent || deviceUuid != null) {
      map['device_uuid'] = Variable<String>(deviceUuid);
    }
    if (!nullToAbsent || personeroId != null) {
      map['personero_id'] = Variable<String>(personeroId);
    }
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    map['attempts'] = Variable<int>(attempts);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['scheduled_at'] = Variable<DateTime>(scheduledAt);
    if (!nullToAbsent || processedAt != null) {
      map['processed_at'] = Variable<DateTime>(processedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalSyncOperationsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncOperationsTableCompanion(
      clientOperationId: Value(clientOperationId),
      deviceUuid: deviceUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceUuid),
      personeroId: personeroId == null && nullToAbsent
          ? const Value.absent()
          : Value(personeroId),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      checksum: checksum == null && nullToAbsent
          ? const Value.absent()
          : Value(checksum),
      attempts: Value(attempts),
      status: Value(status),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      scheduledAt: Value(scheduledAt),
      processedAt: processedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(processedAt),
      createdAt: Value(createdAt),
    );
  }

  factory LocalSyncOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncOperation(
      clientOperationId: serializer.fromJson<String>(json['clientOperationId']),
      deviceUuid: serializer.fromJson<String?>(json['deviceUuid']),
      personeroId: serializer.fromJson<String?>(json['personeroId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      checksum: serializer.fromJson<String?>(json['checksum']),
      attempts: serializer.fromJson<int>(json['attempts']),
      status: serializer.fromJson<String>(json['status']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      scheduledAt: serializer.fromJson<DateTime>(json['scheduledAt']),
      processedAt: serializer.fromJson<DateTime?>(json['processedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientOperationId': serializer.toJson<String>(clientOperationId),
      'deviceUuid': serializer.toJson<String?>(deviceUuid),
      'personeroId': serializer.toJson<String?>(personeroId),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'checksum': serializer.toJson<String?>(checksum),
      'attempts': serializer.toJson<int>(attempts),
      'status': serializer.toJson<String>(status),
      'lastError': serializer.toJson<String?>(lastError),
      'scheduledAt': serializer.toJson<DateTime>(scheduledAt),
      'processedAt': serializer.toJson<DateTime?>(processedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalSyncOperation copyWith({
    String? clientOperationId,
    Value<String?> deviceUuid = const Value.absent(),
    Value<String?> personeroId = const Value.absent(),
    String? entityType,
    String? entityId,
    String? operation,
    String? payloadJson,
    Value<String?> checksum = const Value.absent(),
    int? attempts,
    String? status,
    Value<String?> lastError = const Value.absent(),
    DateTime? scheduledAt,
    Value<DateTime?> processedAt = const Value.absent(),
    DateTime? createdAt,
  }) => LocalSyncOperation(
    clientOperationId: clientOperationId ?? this.clientOperationId,
    deviceUuid: deviceUuid.present ? deviceUuid.value : this.deviceUuid,
    personeroId: personeroId.present ? personeroId.value : this.personeroId,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    checksum: checksum.present ? checksum.value : this.checksum,
    attempts: attempts ?? this.attempts,
    status: status ?? this.status,
    lastError: lastError.present ? lastError.value : this.lastError,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    processedAt: processedAt.present ? processedAt.value : this.processedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalSyncOperation copyWithCompanion(LocalSyncOperationsTableCompanion data) {
    return LocalSyncOperation(
      clientOperationId: data.clientOperationId.present
          ? data.clientOperationId.value
          : this.clientOperationId,
      deviceUuid: data.deviceUuid.present
          ? data.deviceUuid.value
          : this.deviceUuid,
      personeroId: data.personeroId.present
          ? data.personeroId.value
          : this.personeroId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      status: data.status.present ? data.status.value : this.status,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      scheduledAt: data.scheduledAt.present
          ? data.scheduledAt.value
          : this.scheduledAt,
      processedAt: data.processedAt.present
          ? data.processedAt.value
          : this.processedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncOperation(')
          ..write('clientOperationId: $clientOperationId, ')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('personeroId: $personeroId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('checksum: $checksum, ')
          ..write('attempts: $attempts, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('processedAt: $processedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientOperationId,
    deviceUuid,
    personeroId,
    entityType,
    entityId,
    operation,
    payloadJson,
    checksum,
    attempts,
    status,
    lastError,
    scheduledAt,
    processedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncOperation &&
          other.clientOperationId == this.clientOperationId &&
          other.deviceUuid == this.deviceUuid &&
          other.personeroId == this.personeroId &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.checksum == this.checksum &&
          other.attempts == this.attempts &&
          other.status == this.status &&
          other.lastError == this.lastError &&
          other.scheduledAt == this.scheduledAt &&
          other.processedAt == this.processedAt &&
          other.createdAt == this.createdAt);
}

class LocalSyncOperationsTableCompanion
    extends UpdateCompanion<LocalSyncOperation> {
  final Value<String> clientOperationId;
  final Value<String?> deviceUuid;
  final Value<String?> personeroId;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<String?> checksum;
  final Value<int> attempts;
  final Value<String> status;
  final Value<String?> lastError;
  final Value<DateTime> scheduledAt;
  final Value<DateTime?> processedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalSyncOperationsTableCompanion({
    this.clientOperationId = const Value.absent(),
    this.deviceUuid = const Value.absent(),
    this.personeroId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.checksum = const Value.absent(),
    this.attempts = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncOperationsTableCompanion.insert({
    required String clientOperationId,
    this.deviceUuid = const Value.absent(),
    this.personeroId = const Value.absent(),
    required String entityType,
    required String entityId,
    this.operation = const Value.absent(),
    required String payloadJson,
    this.checksum = const Value.absent(),
    this.attempts = const Value.absent(),
    this.status = const Value.absent(),
    this.lastError = const Value.absent(),
    this.scheduledAt = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientOperationId = Value(clientOperationId),
       entityType = Value(entityType),
       entityId = Value(entityId),
       payloadJson = Value(payloadJson);
  static Insertable<LocalSyncOperation> custom({
    Expression<String>? clientOperationId,
    Expression<String>? deviceUuid,
    Expression<String>? personeroId,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<String>? checksum,
    Expression<int>? attempts,
    Expression<String>? status,
    Expression<String>? lastError,
    Expression<DateTime>? scheduledAt,
    Expression<DateTime>? processedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientOperationId != null) 'client_operation_id': clientOperationId,
      if (deviceUuid != null) 'device_uuid': deviceUuid,
      if (personeroId != null) 'personero_id': personeroId,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (checksum != null) 'checksum': checksum,
      if (attempts != null) 'attempts': attempts,
      if (status != null) 'status': status,
      if (lastError != null) 'last_error': lastError,
      if (scheduledAt != null) 'scheduled_at': scheduledAt,
      if (processedAt != null) 'processed_at': processedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncOperationsTableCompanion copyWith({
    Value<String>? clientOperationId,
    Value<String?>? deviceUuid,
    Value<String?>? personeroId,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<String?>? checksum,
    Value<int>? attempts,
    Value<String>? status,
    Value<String?>? lastError,
    Value<DateTime>? scheduledAt,
    Value<DateTime?>? processedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalSyncOperationsTableCompanion(
      clientOperationId: clientOperationId ?? this.clientOperationId,
      deviceUuid: deviceUuid ?? this.deviceUuid,
      personeroId: personeroId ?? this.personeroId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      checksum: checksum ?? this.checksum,
      attempts: attempts ?? this.attempts,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientOperationId.present) {
      map['client_operation_id'] = Variable<String>(clientOperationId.value);
    }
    if (deviceUuid.present) {
      map['device_uuid'] = Variable<String>(deviceUuid.value);
    }
    if (personeroId.present) {
      map['personero_id'] = Variable<String>(personeroId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (scheduledAt.present) {
      map['scheduled_at'] = Variable<DateTime>(scheduledAt.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<DateTime>(processedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncOperationsTableCompanion(')
          ..write('clientOperationId: $clientOperationId, ')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('personeroId: $personeroId, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('checksum: $checksum, ')
          ..write('attempts: $attempts, ')
          ..write('status: $status, ')
          ..write('lastError: $lastError, ')
          ..write('scheduledAt: $scheduledAt, ')
          ..write('processedAt: $processedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPollingStationsTableTable extends LocalPollingStationsTable
    with TableInfo<$LocalPollingStationsTableTable, LocalPollingStation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPollingStationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _districtCodeMeta = const VerificationMeta(
    'districtCode',
  );
  @override
  late final GeneratedColumn<String> districtCode = GeneratedColumn<String>(
    'district_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('150101'),
  );
  static const VerificationMeta _districtNameMeta = const VerificationMeta(
    'districtName',
  );
  @override
  late final GeneratedColumn<String> districtName = GeneratedColumn<String>(
    'district_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LIMA - CERCADO'),
  );
  static const VerificationMeta _provinceNameMeta = const VerificationMeta(
    'provinceName',
  );
  @override
  late final GeneratedColumn<String> provinceName = GeneratedColumn<String>(
    'province_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LIMA'),
  );
  static const VerificationMeta _departmentNameMeta = const VerificationMeta(
    'departmentName',
  );
  @override
  late final GeneratedColumn<String> departmentName = GeneratedColumn<String>(
    'department_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('LIMA'),
  );
  static const VerificationMeta _registeredVotersMeta = const VerificationMeta(
    'registeredVoters',
  );
  @override
  late final GeneratedColumn<int> registeredVoters = GeneratedColumn<int>(
    'registered_voters',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(300),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ACTIVA'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    locationName,
    districtCode,
    districtName,
    provinceName,
    departmentName,
    registeredVoters,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_polling_stations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPollingStation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_locationNameMeta);
    }
    if (data.containsKey('district_code')) {
      context.handle(
        _districtCodeMeta,
        districtCode.isAcceptableOrUnknown(
          data['district_code']!,
          _districtCodeMeta,
        ),
      );
    }
    if (data.containsKey('district_name')) {
      context.handle(
        _districtNameMeta,
        districtName.isAcceptableOrUnknown(
          data['district_name']!,
          _districtNameMeta,
        ),
      );
    }
    if (data.containsKey('province_name')) {
      context.handle(
        _provinceNameMeta,
        provinceName.isAcceptableOrUnknown(
          data['province_name']!,
          _provinceNameMeta,
        ),
      );
    }
    if (data.containsKey('department_name')) {
      context.handle(
        _departmentNameMeta,
        departmentName.isAcceptableOrUnknown(
          data['department_name']!,
          _departmentNameMeta,
        ),
      );
    }
    if (data.containsKey('registered_voters')) {
      context.handle(
        _registeredVotersMeta,
        registeredVoters.isAcceptableOrUnknown(
          data['registered_voters']!,
          _registeredVotersMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPollingStation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPollingStation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      )!,
      districtCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district_code'],
      )!,
      districtName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district_name'],
      )!,
      provinceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}province_name'],
      )!,
      departmentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}department_name'],
      )!,
      registeredVoters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}registered_voters'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $LocalPollingStationsTableTable createAlias(String alias) {
    return $LocalPollingStationsTableTable(attachedDatabase, alias);
  }
}

class LocalPollingStation extends DataClass
    implements Insertable<LocalPollingStation> {
  final int id;
  final String code;
  final String locationName;
  final String districtCode;
  final String districtName;
  final String provinceName;
  final String departmentName;
  final int registeredVoters;
  final String status;
  const LocalPollingStation({
    required this.id,
    required this.code,
    required this.locationName,
    required this.districtCode,
    required this.districtName,
    required this.provinceName,
    required this.departmentName,
    required this.registeredVoters,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['code'] = Variable<String>(code);
    map['location_name'] = Variable<String>(locationName);
    map['district_code'] = Variable<String>(districtCode);
    map['district_name'] = Variable<String>(districtName);
    map['province_name'] = Variable<String>(provinceName);
    map['department_name'] = Variable<String>(departmentName);
    map['registered_voters'] = Variable<int>(registeredVoters);
    map['status'] = Variable<String>(status);
    return map;
  }

  LocalPollingStationsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalPollingStationsTableCompanion(
      id: Value(id),
      code: Value(code),
      locationName: Value(locationName),
      districtCode: Value(districtCode),
      districtName: Value(districtName),
      provinceName: Value(provinceName),
      departmentName: Value(departmentName),
      registeredVoters: Value(registeredVoters),
      status: Value(status),
    );
  }

  factory LocalPollingStation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPollingStation(
      id: serializer.fromJson<int>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      locationName: serializer.fromJson<String>(json['locationName']),
      districtCode: serializer.fromJson<String>(json['districtCode']),
      districtName: serializer.fromJson<String>(json['districtName']),
      provinceName: serializer.fromJson<String>(json['provinceName']),
      departmentName: serializer.fromJson<String>(json['departmentName']),
      registeredVoters: serializer.fromJson<int>(json['registeredVoters']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'code': serializer.toJson<String>(code),
      'locationName': serializer.toJson<String>(locationName),
      'districtCode': serializer.toJson<String>(districtCode),
      'districtName': serializer.toJson<String>(districtName),
      'provinceName': serializer.toJson<String>(provinceName),
      'departmentName': serializer.toJson<String>(departmentName),
      'registeredVoters': serializer.toJson<int>(registeredVoters),
      'status': serializer.toJson<String>(status),
    };
  }

  LocalPollingStation copyWith({
    int? id,
    String? code,
    String? locationName,
    String? districtCode,
    String? districtName,
    String? provinceName,
    String? departmentName,
    int? registeredVoters,
    String? status,
  }) => LocalPollingStation(
    id: id ?? this.id,
    code: code ?? this.code,
    locationName: locationName ?? this.locationName,
    districtCode: districtCode ?? this.districtCode,
    districtName: districtName ?? this.districtName,
    provinceName: provinceName ?? this.provinceName,
    departmentName: departmentName ?? this.departmentName,
    registeredVoters: registeredVoters ?? this.registeredVoters,
    status: status ?? this.status,
  );
  LocalPollingStation copyWithCompanion(
    LocalPollingStationsTableCompanion data,
  ) {
    return LocalPollingStation(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      districtCode: data.districtCode.present
          ? data.districtCode.value
          : this.districtCode,
      districtName: data.districtName.present
          ? data.districtName.value
          : this.districtName,
      provinceName: data.provinceName.present
          ? data.provinceName.value
          : this.provinceName,
      departmentName: data.departmentName.present
          ? data.departmentName.value
          : this.departmentName,
      registeredVoters: data.registeredVoters.present
          ? data.registeredVoters.value
          : this.registeredVoters,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPollingStation(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('locationName: $locationName, ')
          ..write('districtCode: $districtCode, ')
          ..write('districtName: $districtName, ')
          ..write('provinceName: $provinceName, ')
          ..write('departmentName: $departmentName, ')
          ..write('registeredVoters: $registeredVoters, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    locationName,
    districtCode,
    districtName,
    provinceName,
    departmentName,
    registeredVoters,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPollingStation &&
          other.id == this.id &&
          other.code == this.code &&
          other.locationName == this.locationName &&
          other.districtCode == this.districtCode &&
          other.districtName == this.districtName &&
          other.provinceName == this.provinceName &&
          other.departmentName == this.departmentName &&
          other.registeredVoters == this.registeredVoters &&
          other.status == this.status);
}

class LocalPollingStationsTableCompanion
    extends UpdateCompanion<LocalPollingStation> {
  final Value<int> id;
  final Value<String> code;
  final Value<String> locationName;
  final Value<String> districtCode;
  final Value<String> districtName;
  final Value<String> provinceName;
  final Value<String> departmentName;
  final Value<int> registeredVoters;
  final Value<String> status;
  const LocalPollingStationsTableCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.locationName = const Value.absent(),
    this.districtCode = const Value.absent(),
    this.districtName = const Value.absent(),
    this.provinceName = const Value.absent(),
    this.departmentName = const Value.absent(),
    this.registeredVoters = const Value.absent(),
    this.status = const Value.absent(),
  });
  LocalPollingStationsTableCompanion.insert({
    this.id = const Value.absent(),
    required String code,
    required String locationName,
    this.districtCode = const Value.absent(),
    this.districtName = const Value.absent(),
    this.provinceName = const Value.absent(),
    this.departmentName = const Value.absent(),
    this.registeredVoters = const Value.absent(),
    this.status = const Value.absent(),
  }) : code = Value(code),
       locationName = Value(locationName);
  static Insertable<LocalPollingStation> custom({
    Expression<int>? id,
    Expression<String>? code,
    Expression<String>? locationName,
    Expression<String>? districtCode,
    Expression<String>? districtName,
    Expression<String>? provinceName,
    Expression<String>? departmentName,
    Expression<int>? registeredVoters,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (locationName != null) 'location_name': locationName,
      if (districtCode != null) 'district_code': districtCode,
      if (districtName != null) 'district_name': districtName,
      if (provinceName != null) 'province_name': provinceName,
      if (departmentName != null) 'department_name': departmentName,
      if (registeredVoters != null) 'registered_voters': registeredVoters,
      if (status != null) 'status': status,
    });
  }

  LocalPollingStationsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? code,
    Value<String>? locationName,
    Value<String>? districtCode,
    Value<String>? districtName,
    Value<String>? provinceName,
    Value<String>? departmentName,
    Value<int>? registeredVoters,
    Value<String>? status,
  }) {
    return LocalPollingStationsTableCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      locationName: locationName ?? this.locationName,
      districtCode: districtCode ?? this.districtCode,
      districtName: districtName ?? this.districtName,
      provinceName: provinceName ?? this.provinceName,
      departmentName: departmentName ?? this.departmentName,
      registeredVoters: registeredVoters ?? this.registeredVoters,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (districtCode.present) {
      map['district_code'] = Variable<String>(districtCode.value);
    }
    if (districtName.present) {
      map['district_name'] = Variable<String>(districtName.value);
    }
    if (provinceName.present) {
      map['province_name'] = Variable<String>(provinceName.value);
    }
    if (departmentName.present) {
      map['department_name'] = Variable<String>(departmentName.value);
    }
    if (registeredVoters.present) {
      map['registered_voters'] = Variable<int>(registeredVoters.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPollingStationsTableCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('locationName: $locationName, ')
          ..write('districtCode: $districtCode, ')
          ..write('districtName: $districtName, ')
          ..write('provinceName: $provinceName, ')
          ..write('departmentName: $departmentName, ')
          ..write('registeredVoters: $registeredVoters, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $LocalPoliticalOrganizationsTableTable
    extends LocalPoliticalOrganizationsTable
    with
        TableInfo<
          $LocalPoliticalOrganizationsTableTable,
          LocalPoliticalOrganization
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPoliticalOrganizationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shortNameMeta = const VerificationMeta(
    'shortName',
  );
  @override
  late final GeneratedColumn<String> shortName = GeneratedColumn<String>(
    'short_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoUrlMeta = const VerificationMeta(
    'logoUrl',
  );
  @override
  late final GeneratedColumn<String> logoUrl = GeneratedColumn<String>(
    'logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, shortName, logoUrl];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_political_organizations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPoliticalOrganization> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('short_name')) {
      context.handle(
        _shortNameMeta,
        shortName.isAcceptableOrUnknown(data['short_name']!, _shortNameMeta),
      );
    }
    if (data.containsKey('logo_url')) {
      context.handle(
        _logoUrlMeta,
        logoUrl.isAcceptableOrUnknown(data['logo_url']!, _logoUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPoliticalOrganization map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPoliticalOrganization(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      shortName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_name'],
      ),
      logoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo_url'],
      ),
    );
  }

  @override
  $LocalPoliticalOrganizationsTableTable createAlias(String alias) {
    return $LocalPoliticalOrganizationsTableTable(attachedDatabase, alias);
  }
}

class LocalPoliticalOrganization extends DataClass
    implements Insertable<LocalPoliticalOrganization> {
  final int id;
  final String name;
  final String? shortName;
  final String? logoUrl;
  const LocalPoliticalOrganization({
    required this.id,
    required this.name,
    this.shortName,
    this.logoUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || shortName != null) {
      map['short_name'] = Variable<String>(shortName);
    }
    if (!nullToAbsent || logoUrl != null) {
      map['logo_url'] = Variable<String>(logoUrl);
    }
    return map;
  }

  LocalPoliticalOrganizationsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalPoliticalOrganizationsTableCompanion(
      id: Value(id),
      name: Value(name),
      shortName: shortName == null && nullToAbsent
          ? const Value.absent()
          : Value(shortName),
      logoUrl: logoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(logoUrl),
    );
  }

  factory LocalPoliticalOrganization.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPoliticalOrganization(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      shortName: serializer.fromJson<String?>(json['shortName']),
      logoUrl: serializer.fromJson<String?>(json['logoUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'shortName': serializer.toJson<String?>(shortName),
      'logoUrl': serializer.toJson<String?>(logoUrl),
    };
  }

  LocalPoliticalOrganization copyWith({
    int? id,
    String? name,
    Value<String?> shortName = const Value.absent(),
    Value<String?> logoUrl = const Value.absent(),
  }) => LocalPoliticalOrganization(
    id: id ?? this.id,
    name: name ?? this.name,
    shortName: shortName.present ? shortName.value : this.shortName,
    logoUrl: logoUrl.present ? logoUrl.value : this.logoUrl,
  );
  LocalPoliticalOrganization copyWithCompanion(
    LocalPoliticalOrganizationsTableCompanion data,
  ) {
    return LocalPoliticalOrganization(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      shortName: data.shortName.present ? data.shortName.value : this.shortName,
      logoUrl: data.logoUrl.present ? data.logoUrl.value : this.logoUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPoliticalOrganization(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('shortName: $shortName, ')
          ..write('logoUrl: $logoUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, shortName, logoUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPoliticalOrganization &&
          other.id == this.id &&
          other.name == this.name &&
          other.shortName == this.shortName &&
          other.logoUrl == this.logoUrl);
}

class LocalPoliticalOrganizationsTableCompanion
    extends UpdateCompanion<LocalPoliticalOrganization> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> shortName;
  final Value<String?> logoUrl;
  const LocalPoliticalOrganizationsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.shortName = const Value.absent(),
    this.logoUrl = const Value.absent(),
  });
  LocalPoliticalOrganizationsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.shortName = const Value.absent(),
    this.logoUrl = const Value.absent(),
  }) : name = Value(name);
  static Insertable<LocalPoliticalOrganization> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? shortName,
    Expression<String>? logoUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (shortName != null) 'short_name': shortName,
      if (logoUrl != null) 'logo_url': logoUrl,
    });
  }

  LocalPoliticalOrganizationsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? shortName,
    Value<String?>? logoUrl,
  }) {
    return LocalPoliticalOrganizationsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (shortName.present) {
      map['short_name'] = Variable<String>(shortName.value);
    }
    if (logoUrl.present) {
      map['logo_url'] = Variable<String>(logoUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPoliticalOrganizationsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('shortName: $shortName, ')
          ..write('logoUrl: $logoUrl')
          ..write(')'))
        .toString();
  }
}

class $LocalPersonerosTableTable extends LocalPersonerosTable
    with TableInfo<$LocalPersonerosTableTable, LocalPersonero> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPersonerosTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dniMeta = const VerificationMeta('dni');
  @override
  late final GeneratedColumn<String> dni = GeneratedColumn<String>(
    'dni',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pollingStationCodeMeta =
      const VerificationMeta('pollingStationCode');
  @override
  late final GeneratedColumn<String> pollingStationCode =
      GeneratedColumn<String>(
        'polling_station_code',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _phoneNumberMeta = const VerificationMeta(
    'phoneNumber',
  );
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
    'phone_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dni,
    firstName,
    lastName,
    pollingStationCode,
    phoneNumber,
    email,
    isActive,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_personeros_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPersonero> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dni')) {
      context.handle(
        _dniMeta,
        dni.isAcceptableOrUnknown(data['dni']!, _dniMeta),
      );
    } else if (isInserting) {
      context.missing(_dniMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('polling_station_code')) {
      context.handle(
        _pollingStationCodeMeta,
        pollingStationCode.isAcceptableOrUnknown(
          data['polling_station_code']!,
          _pollingStationCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pollingStationCodeMeta);
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPersonero map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPersonero(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dni: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dni'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      pollingStationCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}polling_station_code'],
      )!,
      phoneNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalPersonerosTableTable createAlias(String alias) {
    return $LocalPersonerosTableTable(attachedDatabase, alias);
  }
}

class LocalPersonero extends DataClass implements Insertable<LocalPersonero> {
  final int id;
  final String dni;
  final String firstName;
  final String lastName;
  final String pollingStationCode;
  final String? phoneNumber;
  final String? email;
  final bool isActive;
  final DateTime createdAt;
  const LocalPersonero({
    required this.id,
    required this.dni,
    required this.firstName,
    required this.lastName,
    required this.pollingStationCode,
    this.phoneNumber,
    this.email,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dni'] = Variable<String>(dni);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['polling_station_code'] = Variable<String>(pollingStationCode);
    if (!nullToAbsent || phoneNumber != null) {
      map['phone_number'] = Variable<String>(phoneNumber);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalPersonerosTableCompanion toCompanion(bool nullToAbsent) {
    return LocalPersonerosTableCompanion(
      id: Value(id),
      dni: Value(dni),
      firstName: Value(firstName),
      lastName: Value(lastName),
      pollingStationCode: Value(pollingStationCode),
      phoneNumber: phoneNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneNumber),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory LocalPersonero.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPersonero(
      id: serializer.fromJson<int>(json['id']),
      dni: serializer.fromJson<String>(json['dni']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      pollingStationCode: serializer.fromJson<String>(
        json['pollingStationCode'],
      ),
      phoneNumber: serializer.fromJson<String?>(json['phoneNumber']),
      email: serializer.fromJson<String?>(json['email']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dni': serializer.toJson<String>(dni),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'pollingStationCode': serializer.toJson<String>(pollingStationCode),
      'phoneNumber': serializer.toJson<String?>(phoneNumber),
      'email': serializer.toJson<String?>(email),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalPersonero copyWith({
    int? id,
    String? dni,
    String? firstName,
    String? lastName,
    String? pollingStationCode,
    Value<String?> phoneNumber = const Value.absent(),
    Value<String?> email = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
  }) => LocalPersonero(
    id: id ?? this.id,
    dni: dni ?? this.dni,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    pollingStationCode: pollingStationCode ?? this.pollingStationCode,
    phoneNumber: phoneNumber.present ? phoneNumber.value : this.phoneNumber,
    email: email.present ? email.value : this.email,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalPersonero copyWithCompanion(LocalPersonerosTableCompanion data) {
    return LocalPersonero(
      id: data.id.present ? data.id.value : this.id,
      dni: data.dni.present ? data.dni.value : this.dni,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      pollingStationCode: data.pollingStationCode.present
          ? data.pollingStationCode.value
          : this.pollingStationCode,
      phoneNumber: data.phoneNumber.present
          ? data.phoneNumber.value
          : this.phoneNumber,
      email: data.email.present ? data.email.value : this.email,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPersonero(')
          ..write('id: $id, ')
          ..write('dni: $dni, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('pollingStationCode: $pollingStationCode, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('email: $email, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dni,
    firstName,
    lastName,
    pollingStationCode,
    phoneNumber,
    email,
    isActive,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPersonero &&
          other.id == this.id &&
          other.dni == this.dni &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.pollingStationCode == this.pollingStationCode &&
          other.phoneNumber == this.phoneNumber &&
          other.email == this.email &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class LocalPersonerosTableCompanion extends UpdateCompanion<LocalPersonero> {
  final Value<int> id;
  final Value<String> dni;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> pollingStationCode;
  final Value<String?> phoneNumber;
  final Value<String?> email;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  const LocalPersonerosTableCompanion({
    this.id = const Value.absent(),
    this.dni = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.pollingStationCode = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.email = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalPersonerosTableCompanion.insert({
    this.id = const Value.absent(),
    required String dni,
    required String firstName,
    required String lastName,
    required String pollingStationCode,
    this.phoneNumber = const Value.absent(),
    this.email = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : dni = Value(dni),
       firstName = Value(firstName),
       lastName = Value(lastName),
       pollingStationCode = Value(pollingStationCode);
  static Insertable<LocalPersonero> custom({
    Expression<int>? id,
    Expression<String>? dni,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? pollingStationCode,
    Expression<String>? phoneNumber,
    Expression<String>? email,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dni != null) 'dni': dni,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (pollingStationCode != null)
        'polling_station_code': pollingStationCode,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (email != null) 'email': email,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalPersonerosTableCompanion copyWith({
    Value<int>? id,
    Value<String>? dni,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<String>? pollingStationCode,
    Value<String?>? phoneNumber,
    Value<String?>? email,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
  }) {
    return LocalPersonerosTableCompanion(
      id: id ?? this.id,
      dni: dni ?? this.dni,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      pollingStationCode: pollingStationCode ?? this.pollingStationCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dni.present) {
      map['dni'] = Variable<String>(dni.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (pollingStationCode.present) {
      map['polling_station_code'] = Variable<String>(pollingStationCode.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPersonerosTableCompanion(')
          ..write('id: $id, ')
          ..write('dni: $dni, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('pollingStationCode: $pollingStationCode, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('email: $email, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalActsTableTable localActsTable = $LocalActsTableTable(this);
  late final $LocalActTotalsTableTable localActTotalsTable =
      $LocalActTotalsTableTable(this);
  late final $LocalActResultsTableTable localActResultsTable =
      $LocalActResultsTableTable(this);
  late final $LocalActEvidenceTableTable localActEvidenceTable =
      $LocalActEvidenceTableTable(this);
  late final $LocalSyncOperationsTableTable localSyncOperationsTable =
      $LocalSyncOperationsTableTable(this);
  late final $LocalPollingStationsTableTable localPollingStationsTable =
      $LocalPollingStationsTableTable(this);
  late final $LocalPoliticalOrganizationsTableTable
  localPoliticalOrganizationsTable = $LocalPoliticalOrganizationsTableTable(
    this,
  );
  late final $LocalPersonerosTableTable localPersonerosTable =
      $LocalPersonerosTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localActsTable,
    localActTotalsTable,
    localActResultsTable,
    localActEvidenceTable,
    localSyncOperationsTable,
    localPollingStationsTable,
    localPoliticalOrganizationsTable,
    localPersonerosTable,
  ];
}

typedef $$LocalActsTableTableCreateCompanionBuilder =
    LocalActsTableCompanion Function({
      Value<int> id,
      required String clientActUuid,
      required int electionId,
      required int electoralLevelId,
      required String pollingStationCode,
      Value<String?> actCode,
      Value<String> status,
      Value<int?> serverActId,
      Value<DateTime> capturedAt,
      Value<DateTime?> confirmedAt,
    });
typedef $$LocalActsTableTableUpdateCompanionBuilder =
    LocalActsTableCompanion Function({
      Value<int> id,
      Value<String> clientActUuid,
      Value<int> electionId,
      Value<int> electoralLevelId,
      Value<String> pollingStationCode,
      Value<String?> actCode,
      Value<String> status,
      Value<int?> serverActId,
      Value<DateTime> capturedAt,
      Value<DateTime?> confirmedAt,
    });

class $$LocalActsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalActsTableTable> {
  $$LocalActsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientActUuid => $composableBuilder(
    column: $table.clientActUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get electionId => $composableBuilder(
    column: $table.electionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get electoralLevelId => $composableBuilder(
    column: $table.electoralLevelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pollingStationCode => $composableBuilder(
    column: $table.pollingStationCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actCode => $composableBuilder(
    column: $table.actCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverActId => $composableBuilder(
    column: $table.serverActId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalActsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalActsTableTable> {
  $$LocalActsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientActUuid => $composableBuilder(
    column: $table.clientActUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get electionId => $composableBuilder(
    column: $table.electionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get electoralLevelId => $composableBuilder(
    column: $table.electoralLevelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pollingStationCode => $composableBuilder(
    column: $table.pollingStationCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actCode => $composableBuilder(
    column: $table.actCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverActId => $composableBuilder(
    column: $table.serverActId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalActsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalActsTableTable> {
  $$LocalActsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientActUuid => $composableBuilder(
    column: $table.clientActUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get electionId => $composableBuilder(
    column: $table.electionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get electoralLevelId => $composableBuilder(
    column: $table.electoralLevelId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pollingStationCode => $composableBuilder(
    column: $table.pollingStationCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get actCode =>
      $composableBuilder(column: $table.actCode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get serverActId => $composableBuilder(
    column: $table.serverActId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );
}

class $$LocalActsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalActsTableTable,
          LocalAct,
          $$LocalActsTableTableFilterComposer,
          $$LocalActsTableTableOrderingComposer,
          $$LocalActsTableTableAnnotationComposer,
          $$LocalActsTableTableCreateCompanionBuilder,
          $$LocalActsTableTableUpdateCompanionBuilder,
          (
            LocalAct,
            BaseReferences<_$AppDatabase, $LocalActsTableTable, LocalAct>,
          ),
          LocalAct,
          PrefetchHooks Function()
        > {
  $$LocalActsTableTableTableManager(
    _$AppDatabase db,
    $LocalActsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalActsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalActsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalActsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientActUuid = const Value.absent(),
                Value<int> electionId = const Value.absent(),
                Value<int> electoralLevelId = const Value.absent(),
                Value<String> pollingStationCode = const Value.absent(),
                Value<String?> actCode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> serverActId = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
              }) => LocalActsTableCompanion(
                id: id,
                clientActUuid: clientActUuid,
                electionId: electionId,
                electoralLevelId: electoralLevelId,
                pollingStationCode: pollingStationCode,
                actCode: actCode,
                status: status,
                serverActId: serverActId,
                capturedAt: capturedAt,
                confirmedAt: confirmedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientActUuid,
                required int electionId,
                required int electoralLevelId,
                required String pollingStationCode,
                Value<String?> actCode = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> serverActId = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
              }) => LocalActsTableCompanion.insert(
                id: id,
                clientActUuid: clientActUuid,
                electionId: electionId,
                electoralLevelId: electoralLevelId,
                pollingStationCode: pollingStationCode,
                actCode: actCode,
                status: status,
                serverActId: serverActId,
                capturedAt: capturedAt,
                confirmedAt: confirmedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalActsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalActsTableTable,
      LocalAct,
      $$LocalActsTableTableFilterComposer,
      $$LocalActsTableTableOrderingComposer,
      $$LocalActsTableTableAnnotationComposer,
      $$LocalActsTableTableCreateCompanionBuilder,
      $$LocalActsTableTableUpdateCompanionBuilder,
      (LocalAct, BaseReferences<_$AppDatabase, $LocalActsTableTable, LocalAct>),
      LocalAct,
      PrefetchHooks Function()
    >;
typedef $$LocalActTotalsTableTableCreateCompanionBuilder =
    LocalActTotalsTableCompanion Function({
      Value<int> id,
      required String clientActUuid,
      required int registeredVoters,
      required int votersWhoVoted,
      required int totalVotes,
      Value<int> blankVotes,
      Value<int> nullVotes,
      Value<int> challengedVotes,
      Value<bool> isValidTotal,
    });
typedef $$LocalActTotalsTableTableUpdateCompanionBuilder =
    LocalActTotalsTableCompanion Function({
      Value<int> id,
      Value<String> clientActUuid,
      Value<int> registeredVoters,
      Value<int> votersWhoVoted,
      Value<int> totalVotes,
      Value<int> blankVotes,
      Value<int> nullVotes,
      Value<int> challengedVotes,
      Value<bool> isValidTotal,
    });

class $$LocalActTotalsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalActTotalsTableTable> {
  $$LocalActTotalsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientActUuid => $composableBuilder(
    column: $table.clientActUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get registeredVoters => $composableBuilder(
    column: $table.registeredVoters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get votersWhoVoted => $composableBuilder(
    column: $table.votersWhoVoted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalVotes => $composableBuilder(
    column: $table.totalVotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blankVotes => $composableBuilder(
    column: $table.blankVotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nullVotes => $composableBuilder(
    column: $table.nullVotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get challengedVotes => $composableBuilder(
    column: $table.challengedVotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isValidTotal => $composableBuilder(
    column: $table.isValidTotal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalActTotalsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalActTotalsTableTable> {
  $$LocalActTotalsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientActUuid => $composableBuilder(
    column: $table.clientActUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get registeredVoters => $composableBuilder(
    column: $table.registeredVoters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get votersWhoVoted => $composableBuilder(
    column: $table.votersWhoVoted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalVotes => $composableBuilder(
    column: $table.totalVotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blankVotes => $composableBuilder(
    column: $table.blankVotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nullVotes => $composableBuilder(
    column: $table.nullVotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get challengedVotes => $composableBuilder(
    column: $table.challengedVotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isValidTotal => $composableBuilder(
    column: $table.isValidTotal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalActTotalsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalActTotalsTableTable> {
  $$LocalActTotalsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientActUuid => $composableBuilder(
    column: $table.clientActUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get registeredVoters => $composableBuilder(
    column: $table.registeredVoters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get votersWhoVoted => $composableBuilder(
    column: $table.votersWhoVoted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalVotes => $composableBuilder(
    column: $table.totalVotes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get blankVotes => $composableBuilder(
    column: $table.blankVotes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nullVotes =>
      $composableBuilder(column: $table.nullVotes, builder: (column) => column);

  GeneratedColumn<int> get challengedVotes => $composableBuilder(
    column: $table.challengedVotes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isValidTotal => $composableBuilder(
    column: $table.isValidTotal,
    builder: (column) => column,
  );
}

class $$LocalActTotalsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalActTotalsTableTable,
          LocalActTotal,
          $$LocalActTotalsTableTableFilterComposer,
          $$LocalActTotalsTableTableOrderingComposer,
          $$LocalActTotalsTableTableAnnotationComposer,
          $$LocalActTotalsTableTableCreateCompanionBuilder,
          $$LocalActTotalsTableTableUpdateCompanionBuilder,
          (
            LocalActTotal,
            BaseReferences<
              _$AppDatabase,
              $LocalActTotalsTableTable,
              LocalActTotal
            >,
          ),
          LocalActTotal,
          PrefetchHooks Function()
        > {
  $$LocalActTotalsTableTableTableManager(
    _$AppDatabase db,
    $LocalActTotalsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalActTotalsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalActTotalsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalActTotalsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientActUuid = const Value.absent(),
                Value<int> registeredVoters = const Value.absent(),
                Value<int> votersWhoVoted = const Value.absent(),
                Value<int> totalVotes = const Value.absent(),
                Value<int> blankVotes = const Value.absent(),
                Value<int> nullVotes = const Value.absent(),
                Value<int> challengedVotes = const Value.absent(),
                Value<bool> isValidTotal = const Value.absent(),
              }) => LocalActTotalsTableCompanion(
                id: id,
                clientActUuid: clientActUuid,
                registeredVoters: registeredVoters,
                votersWhoVoted: votersWhoVoted,
                totalVotes: totalVotes,
                blankVotes: blankVotes,
                nullVotes: nullVotes,
                challengedVotes: challengedVotes,
                isValidTotal: isValidTotal,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientActUuid,
                required int registeredVoters,
                required int votersWhoVoted,
                required int totalVotes,
                Value<int> blankVotes = const Value.absent(),
                Value<int> nullVotes = const Value.absent(),
                Value<int> challengedVotes = const Value.absent(),
                Value<bool> isValidTotal = const Value.absent(),
              }) => LocalActTotalsTableCompanion.insert(
                id: id,
                clientActUuid: clientActUuid,
                registeredVoters: registeredVoters,
                votersWhoVoted: votersWhoVoted,
                totalVotes: totalVotes,
                blankVotes: blankVotes,
                nullVotes: nullVotes,
                challengedVotes: challengedVotes,
                isValidTotal: isValidTotal,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalActTotalsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalActTotalsTableTable,
      LocalActTotal,
      $$LocalActTotalsTableTableFilterComposer,
      $$LocalActTotalsTableTableOrderingComposer,
      $$LocalActTotalsTableTableAnnotationComposer,
      $$LocalActTotalsTableTableCreateCompanionBuilder,
      $$LocalActTotalsTableTableUpdateCompanionBuilder,
      (
        LocalActTotal,
        BaseReferences<_$AppDatabase, $LocalActTotalsTableTable, LocalActTotal>,
      ),
      LocalActTotal,
      PrefetchHooks Function()
    >;
typedef $$LocalActResultsTableTableCreateCompanionBuilder =
    LocalActResultsTableCompanion Function({
      Value<int> id,
      required String clientActUuid,
      Value<int?> politicalOrganizationId,
      Value<String?> politicalOrganizationName,
      Value<int?> electoralListId,
      Value<int?> candidateId,
      Value<String?> candidateName,
      Value<int> votes,
      Value<String> source,
      Value<double?> confidence,
    });
typedef $$LocalActResultsTableTableUpdateCompanionBuilder =
    LocalActResultsTableCompanion Function({
      Value<int> id,
      Value<String> clientActUuid,
      Value<int?> politicalOrganizationId,
      Value<String?> politicalOrganizationName,
      Value<int?> electoralListId,
      Value<int?> candidateId,
      Value<String?> candidateName,
      Value<int> votes,
      Value<String> source,
      Value<double?> confidence,
    });

class $$LocalActResultsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalActResultsTableTable> {
  $$LocalActResultsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientActUuid => $composableBuilder(
    column: $table.clientActUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get politicalOrganizationId => $composableBuilder(
    column: $table.politicalOrganizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get politicalOrganizationName => $composableBuilder(
    column: $table.politicalOrganizationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get electoralListId => $composableBuilder(
    column: $table.electoralListId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get candidateId => $composableBuilder(
    column: $table.candidateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get candidateName => $composableBuilder(
    column: $table.candidateName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get votes => $composableBuilder(
    column: $table.votes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalActResultsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalActResultsTableTable> {
  $$LocalActResultsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientActUuid => $composableBuilder(
    column: $table.clientActUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get politicalOrganizationId => $composableBuilder(
    column: $table.politicalOrganizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get politicalOrganizationName => $composableBuilder(
    column: $table.politicalOrganizationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get electoralListId => $composableBuilder(
    column: $table.electoralListId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get candidateId => $composableBuilder(
    column: $table.candidateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get candidateName => $composableBuilder(
    column: $table.candidateName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get votes => $composableBuilder(
    column: $table.votes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalActResultsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalActResultsTableTable> {
  $$LocalActResultsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientActUuid => $composableBuilder(
    column: $table.clientActUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get politicalOrganizationId => $composableBuilder(
    column: $table.politicalOrganizationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get politicalOrganizationName => $composableBuilder(
    column: $table.politicalOrganizationName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get electoralListId => $composableBuilder(
    column: $table.electoralListId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get candidateId => $composableBuilder(
    column: $table.candidateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get candidateName => $composableBuilder(
    column: $table.candidateName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get votes =>
      $composableBuilder(column: $table.votes, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );
}

class $$LocalActResultsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalActResultsTableTable,
          LocalActResult,
          $$LocalActResultsTableTableFilterComposer,
          $$LocalActResultsTableTableOrderingComposer,
          $$LocalActResultsTableTableAnnotationComposer,
          $$LocalActResultsTableTableCreateCompanionBuilder,
          $$LocalActResultsTableTableUpdateCompanionBuilder,
          (
            LocalActResult,
            BaseReferences<
              _$AppDatabase,
              $LocalActResultsTableTable,
              LocalActResult
            >,
          ),
          LocalActResult,
          PrefetchHooks Function()
        > {
  $$LocalActResultsTableTableTableManager(
    _$AppDatabase db,
    $LocalActResultsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalActResultsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalActResultsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalActResultsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientActUuid = const Value.absent(),
                Value<int?> politicalOrganizationId = const Value.absent(),
                Value<String?> politicalOrganizationName = const Value.absent(),
                Value<int?> electoralListId = const Value.absent(),
                Value<int?> candidateId = const Value.absent(),
                Value<String?> candidateName = const Value.absent(),
                Value<int> votes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
              }) => LocalActResultsTableCompanion(
                id: id,
                clientActUuid: clientActUuid,
                politicalOrganizationId: politicalOrganizationId,
                politicalOrganizationName: politicalOrganizationName,
                electoralListId: electoralListId,
                candidateId: candidateId,
                candidateName: candidateName,
                votes: votes,
                source: source,
                confidence: confidence,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientActUuid,
                Value<int?> politicalOrganizationId = const Value.absent(),
                Value<String?> politicalOrganizationName = const Value.absent(),
                Value<int?> electoralListId = const Value.absent(),
                Value<int?> candidateId = const Value.absent(),
                Value<String?> candidateName = const Value.absent(),
                Value<int> votes = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
              }) => LocalActResultsTableCompanion.insert(
                id: id,
                clientActUuid: clientActUuid,
                politicalOrganizationId: politicalOrganizationId,
                politicalOrganizationName: politicalOrganizationName,
                electoralListId: electoralListId,
                candidateId: candidateId,
                candidateName: candidateName,
                votes: votes,
                source: source,
                confidence: confidence,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalActResultsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalActResultsTableTable,
      LocalActResult,
      $$LocalActResultsTableTableFilterComposer,
      $$LocalActResultsTableTableOrderingComposer,
      $$LocalActResultsTableTableAnnotationComposer,
      $$LocalActResultsTableTableCreateCompanionBuilder,
      $$LocalActResultsTableTableUpdateCompanionBuilder,
      (
        LocalActResult,
        BaseReferences<
          _$AppDatabase,
          $LocalActResultsTableTable,
          LocalActResult
        >,
      ),
      LocalActResult,
      PrefetchHooks Function()
    >;
typedef $$LocalActEvidenceTableTableCreateCompanionBuilder =
    LocalActEvidenceTableCompanion Function({
      Value<int> id,
      required String clientActUuid,
      required String localFilePath,
      required String sha256Hash,
      Value<String> fileMime,
      required int fileSizeBytes,
      Value<int?> widthPx,
      Value<int?> heightPx,
      Value<String?> storageKey,
      Value<bool> isUploaded,
      Value<DateTime> capturedAt,
    });
typedef $$LocalActEvidenceTableTableUpdateCompanionBuilder =
    LocalActEvidenceTableCompanion Function({
      Value<int> id,
      Value<String> clientActUuid,
      Value<String> localFilePath,
      Value<String> sha256Hash,
      Value<String> fileMime,
      Value<int> fileSizeBytes,
      Value<int?> widthPx,
      Value<int?> heightPx,
      Value<String?> storageKey,
      Value<bool> isUploaded,
      Value<DateTime> capturedAt,
    });

class $$LocalActEvidenceTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalActEvidenceTableTable> {
  $$LocalActEvidenceTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientActUuid => $composableBuilder(
    column: $table.clientActUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileMime => $composableBuilder(
    column: $table.fileMime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get widthPx => $composableBuilder(
    column: $table.widthPx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get heightPx => $composableBuilder(
    column: $table.heightPx,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageKey => $composableBuilder(
    column: $table.storageKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUploaded => $composableBuilder(
    column: $table.isUploaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalActEvidenceTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalActEvidenceTableTable> {
  $$LocalActEvidenceTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientActUuid => $composableBuilder(
    column: $table.clientActUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileMime => $composableBuilder(
    column: $table.fileMime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get widthPx => $composableBuilder(
    column: $table.widthPx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get heightPx => $composableBuilder(
    column: $table.heightPx,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageKey => $composableBuilder(
    column: $table.storageKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUploaded => $composableBuilder(
    column: $table.isUploaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalActEvidenceTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalActEvidenceTableTable> {
  $$LocalActEvidenceTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientActUuid => $composableBuilder(
    column: $table.clientActUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileMime =>
      $composableBuilder(column: $table.fileMime, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get widthPx =>
      $composableBuilder(column: $table.widthPx, builder: (column) => column);

  GeneratedColumn<int> get heightPx =>
      $composableBuilder(column: $table.heightPx, builder: (column) => column);

  GeneratedColumn<String> get storageKey => $composableBuilder(
    column: $table.storageKey,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUploaded => $composableBuilder(
    column: $table.isUploaded,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );
}

class $$LocalActEvidenceTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalActEvidenceTableTable,
          LocalActEvidence,
          $$LocalActEvidenceTableTableFilterComposer,
          $$LocalActEvidenceTableTableOrderingComposer,
          $$LocalActEvidenceTableTableAnnotationComposer,
          $$LocalActEvidenceTableTableCreateCompanionBuilder,
          $$LocalActEvidenceTableTableUpdateCompanionBuilder,
          (
            LocalActEvidence,
            BaseReferences<
              _$AppDatabase,
              $LocalActEvidenceTableTable,
              LocalActEvidence
            >,
          ),
          LocalActEvidence,
          PrefetchHooks Function()
        > {
  $$LocalActEvidenceTableTableTableManager(
    _$AppDatabase db,
    $LocalActEvidenceTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalActEvidenceTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalActEvidenceTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalActEvidenceTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientActUuid = const Value.absent(),
                Value<String> localFilePath = const Value.absent(),
                Value<String> sha256Hash = const Value.absent(),
                Value<String> fileMime = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<int?> widthPx = const Value.absent(),
                Value<int?> heightPx = const Value.absent(),
                Value<String?> storageKey = const Value.absent(),
                Value<bool> isUploaded = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
              }) => LocalActEvidenceTableCompanion(
                id: id,
                clientActUuid: clientActUuid,
                localFilePath: localFilePath,
                sha256Hash: sha256Hash,
                fileMime: fileMime,
                fileSizeBytes: fileSizeBytes,
                widthPx: widthPx,
                heightPx: heightPx,
                storageKey: storageKey,
                isUploaded: isUploaded,
                capturedAt: capturedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientActUuid,
                required String localFilePath,
                required String sha256Hash,
                Value<String> fileMime = const Value.absent(),
                required int fileSizeBytes,
                Value<int?> widthPx = const Value.absent(),
                Value<int?> heightPx = const Value.absent(),
                Value<String?> storageKey = const Value.absent(),
                Value<bool> isUploaded = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
              }) => LocalActEvidenceTableCompanion.insert(
                id: id,
                clientActUuid: clientActUuid,
                localFilePath: localFilePath,
                sha256Hash: sha256Hash,
                fileMime: fileMime,
                fileSizeBytes: fileSizeBytes,
                widthPx: widthPx,
                heightPx: heightPx,
                storageKey: storageKey,
                isUploaded: isUploaded,
                capturedAt: capturedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalActEvidenceTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalActEvidenceTableTable,
      LocalActEvidence,
      $$LocalActEvidenceTableTableFilterComposer,
      $$LocalActEvidenceTableTableOrderingComposer,
      $$LocalActEvidenceTableTableAnnotationComposer,
      $$LocalActEvidenceTableTableCreateCompanionBuilder,
      $$LocalActEvidenceTableTableUpdateCompanionBuilder,
      (
        LocalActEvidence,
        BaseReferences<
          _$AppDatabase,
          $LocalActEvidenceTableTable,
          LocalActEvidence
        >,
      ),
      LocalActEvidence,
      PrefetchHooks Function()
    >;
typedef $$LocalSyncOperationsTableTableCreateCompanionBuilder =
    LocalSyncOperationsTableCompanion Function({
      required String clientOperationId,
      Value<String?> deviceUuid,
      Value<String?> personeroId,
      required String entityType,
      required String entityId,
      Value<String> operation,
      required String payloadJson,
      Value<String?> checksum,
      Value<int> attempts,
      Value<String> status,
      Value<String?> lastError,
      Value<DateTime> scheduledAt,
      Value<DateTime?> processedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$LocalSyncOperationsTableTableUpdateCompanionBuilder =
    LocalSyncOperationsTableCompanion Function({
      Value<String> clientOperationId,
      Value<String?> deviceUuid,
      Value<String?> personeroId,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> operation,
      Value<String> payloadJson,
      Value<String?> checksum,
      Value<int> attempts,
      Value<String> status,
      Value<String?> lastError,
      Value<DateTime> scheduledAt,
      Value<DateTime?> processedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalSyncOperationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSyncOperationsTableTable> {
  $$LocalSyncOperationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientOperationId => $composableBuilder(
    column: $table.clientOperationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personeroId => $composableBuilder(
    column: $table.personeroId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSyncOperationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSyncOperationsTableTable> {
  $$LocalSyncOperationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientOperationId => $composableBuilder(
    column: $table.clientOperationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personeroId => $composableBuilder(
    column: $table.personeroId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSyncOperationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSyncOperationsTableTable> {
  $$LocalSyncOperationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientOperationId => $composableBuilder(
    column: $table.clientOperationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get personeroId => $composableBuilder(
    column: $table.personeroId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAt => $composableBuilder(
    column: $table.scheduledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalSyncOperationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSyncOperationsTableTable,
          LocalSyncOperation,
          $$LocalSyncOperationsTableTableFilterComposer,
          $$LocalSyncOperationsTableTableOrderingComposer,
          $$LocalSyncOperationsTableTableAnnotationComposer,
          $$LocalSyncOperationsTableTableCreateCompanionBuilder,
          $$LocalSyncOperationsTableTableUpdateCompanionBuilder,
          (
            LocalSyncOperation,
            BaseReferences<
              _$AppDatabase,
              $LocalSyncOperationsTableTable,
              LocalSyncOperation
            >,
          ),
          LocalSyncOperation,
          PrefetchHooks Function()
        > {
  $$LocalSyncOperationsTableTableTableManager(
    _$AppDatabase db,
    $LocalSyncOperationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncOperationsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalSyncOperationsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalSyncOperationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> clientOperationId = const Value.absent(),
                Value<String?> deviceUuid = const Value.absent(),
                Value<String?> personeroId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<DateTime?> processedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncOperationsTableCompanion(
                clientOperationId: clientOperationId,
                deviceUuid: deviceUuid,
                personeroId: personeroId,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                checksum: checksum,
                attempts: attempts,
                status: status,
                lastError: lastError,
                scheduledAt: scheduledAt,
                processedAt: processedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientOperationId,
                Value<String?> deviceUuid = const Value.absent(),
                Value<String?> personeroId = const Value.absent(),
                required String entityType,
                required String entityId,
                Value<String> operation = const Value.absent(),
                required String payloadJson,
                Value<String?> checksum = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> scheduledAt = const Value.absent(),
                Value<DateTime?> processedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncOperationsTableCompanion.insert(
                clientOperationId: clientOperationId,
                deviceUuid: deviceUuid,
                personeroId: personeroId,
                entityType: entityType,
                entityId: entityId,
                operation: operation,
                payloadJson: payloadJson,
                checksum: checksum,
                attempts: attempts,
                status: status,
                lastError: lastError,
                scheduledAt: scheduledAt,
                processedAt: processedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSyncOperationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSyncOperationsTableTable,
      LocalSyncOperation,
      $$LocalSyncOperationsTableTableFilterComposer,
      $$LocalSyncOperationsTableTableOrderingComposer,
      $$LocalSyncOperationsTableTableAnnotationComposer,
      $$LocalSyncOperationsTableTableCreateCompanionBuilder,
      $$LocalSyncOperationsTableTableUpdateCompanionBuilder,
      (
        LocalSyncOperation,
        BaseReferences<
          _$AppDatabase,
          $LocalSyncOperationsTableTable,
          LocalSyncOperation
        >,
      ),
      LocalSyncOperation,
      PrefetchHooks Function()
    >;
typedef $$LocalPollingStationsTableTableCreateCompanionBuilder =
    LocalPollingStationsTableCompanion Function({
      Value<int> id,
      required String code,
      required String locationName,
      Value<String> districtCode,
      Value<String> districtName,
      Value<String> provinceName,
      Value<String> departmentName,
      Value<int> registeredVoters,
      Value<String> status,
    });
typedef $$LocalPollingStationsTableTableUpdateCompanionBuilder =
    LocalPollingStationsTableCompanion Function({
      Value<int> id,
      Value<String> code,
      Value<String> locationName,
      Value<String> districtCode,
      Value<String> districtName,
      Value<String> provinceName,
      Value<String> departmentName,
      Value<int> registeredVoters,
      Value<String> status,
    });

class $$LocalPollingStationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPollingStationsTableTable> {
  $$LocalPollingStationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get districtCode => $composableBuilder(
    column: $table.districtCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get districtName => $composableBuilder(
    column: $table.districtName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provinceName => $composableBuilder(
    column: $table.provinceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get departmentName => $composableBuilder(
    column: $table.departmentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get registeredVoters => $composableBuilder(
    column: $table.registeredVoters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPollingStationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPollingStationsTableTable> {
  $$LocalPollingStationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get districtCode => $composableBuilder(
    column: $table.districtCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get districtName => $composableBuilder(
    column: $table.districtName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provinceName => $composableBuilder(
    column: $table.provinceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get departmentName => $composableBuilder(
    column: $table.departmentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get registeredVoters => $composableBuilder(
    column: $table.registeredVoters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPollingStationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPollingStationsTableTable> {
  $$LocalPollingStationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get districtCode => $composableBuilder(
    column: $table.districtCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get districtName => $composableBuilder(
    column: $table.districtName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provinceName => $composableBuilder(
    column: $table.provinceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get departmentName => $composableBuilder(
    column: $table.departmentName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get registeredVoters => $composableBuilder(
    column: $table.registeredVoters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$LocalPollingStationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPollingStationsTableTable,
          LocalPollingStation,
          $$LocalPollingStationsTableTableFilterComposer,
          $$LocalPollingStationsTableTableOrderingComposer,
          $$LocalPollingStationsTableTableAnnotationComposer,
          $$LocalPollingStationsTableTableCreateCompanionBuilder,
          $$LocalPollingStationsTableTableUpdateCompanionBuilder,
          (
            LocalPollingStation,
            BaseReferences<
              _$AppDatabase,
              $LocalPollingStationsTableTable,
              LocalPollingStation
            >,
          ),
          LocalPollingStation,
          PrefetchHooks Function()
        > {
  $$LocalPollingStationsTableTableTableManager(
    _$AppDatabase db,
    $LocalPollingStationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPollingStationsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalPollingStationsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalPollingStationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> locationName = const Value.absent(),
                Value<String> districtCode = const Value.absent(),
                Value<String> districtName = const Value.absent(),
                Value<String> provinceName = const Value.absent(),
                Value<String> departmentName = const Value.absent(),
                Value<int> registeredVoters = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => LocalPollingStationsTableCompanion(
                id: id,
                code: code,
                locationName: locationName,
                districtCode: districtCode,
                districtName: districtName,
                provinceName: provinceName,
                departmentName: departmentName,
                registeredVoters: registeredVoters,
                status: status,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String code,
                required String locationName,
                Value<String> districtCode = const Value.absent(),
                Value<String> districtName = const Value.absent(),
                Value<String> provinceName = const Value.absent(),
                Value<String> departmentName = const Value.absent(),
                Value<int> registeredVoters = const Value.absent(),
                Value<String> status = const Value.absent(),
              }) => LocalPollingStationsTableCompanion.insert(
                id: id,
                code: code,
                locationName: locationName,
                districtCode: districtCode,
                districtName: districtName,
                provinceName: provinceName,
                departmentName: departmentName,
                registeredVoters: registeredVoters,
                status: status,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPollingStationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPollingStationsTableTable,
      LocalPollingStation,
      $$LocalPollingStationsTableTableFilterComposer,
      $$LocalPollingStationsTableTableOrderingComposer,
      $$LocalPollingStationsTableTableAnnotationComposer,
      $$LocalPollingStationsTableTableCreateCompanionBuilder,
      $$LocalPollingStationsTableTableUpdateCompanionBuilder,
      (
        LocalPollingStation,
        BaseReferences<
          _$AppDatabase,
          $LocalPollingStationsTableTable,
          LocalPollingStation
        >,
      ),
      LocalPollingStation,
      PrefetchHooks Function()
    >;
typedef $$LocalPoliticalOrganizationsTableTableCreateCompanionBuilder =
    LocalPoliticalOrganizationsTableCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> shortName,
      Value<String?> logoUrl,
    });
typedef $$LocalPoliticalOrganizationsTableTableUpdateCompanionBuilder =
    LocalPoliticalOrganizationsTableCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> shortName,
      Value<String?> logoUrl,
    });

class $$LocalPoliticalOrganizationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPoliticalOrganizationsTableTable> {
  $$LocalPoliticalOrganizationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPoliticalOrganizationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPoliticalOrganizationsTableTable> {
  $$LocalPoliticalOrganizationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logoUrl => $composableBuilder(
    column: $table.logoUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPoliticalOrganizationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPoliticalOrganizationsTableTable> {
  $$LocalPoliticalOrganizationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get shortName =>
      $composableBuilder(column: $table.shortName, builder: (column) => column);

  GeneratedColumn<String> get logoUrl =>
      $composableBuilder(column: $table.logoUrl, builder: (column) => column);
}

class $$LocalPoliticalOrganizationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPoliticalOrganizationsTableTable,
          LocalPoliticalOrganization,
          $$LocalPoliticalOrganizationsTableTableFilterComposer,
          $$LocalPoliticalOrganizationsTableTableOrderingComposer,
          $$LocalPoliticalOrganizationsTableTableAnnotationComposer,
          $$LocalPoliticalOrganizationsTableTableCreateCompanionBuilder,
          $$LocalPoliticalOrganizationsTableTableUpdateCompanionBuilder,
          (
            LocalPoliticalOrganization,
            BaseReferences<
              _$AppDatabase,
              $LocalPoliticalOrganizationsTableTable,
              LocalPoliticalOrganization
            >,
          ),
          LocalPoliticalOrganization,
          PrefetchHooks Function()
        > {
  $$LocalPoliticalOrganizationsTableTableTableManager(
    _$AppDatabase db,
    $LocalPoliticalOrganizationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPoliticalOrganizationsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalPoliticalOrganizationsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalPoliticalOrganizationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> shortName = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
              }) => LocalPoliticalOrganizationsTableCompanion(
                id: id,
                name: name,
                shortName: shortName,
                logoUrl: logoUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> shortName = const Value.absent(),
                Value<String?> logoUrl = const Value.absent(),
              }) => LocalPoliticalOrganizationsTableCompanion.insert(
                id: id,
                name: name,
                shortName: shortName,
                logoUrl: logoUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPoliticalOrganizationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPoliticalOrganizationsTableTable,
      LocalPoliticalOrganization,
      $$LocalPoliticalOrganizationsTableTableFilterComposer,
      $$LocalPoliticalOrganizationsTableTableOrderingComposer,
      $$LocalPoliticalOrganizationsTableTableAnnotationComposer,
      $$LocalPoliticalOrganizationsTableTableCreateCompanionBuilder,
      $$LocalPoliticalOrganizationsTableTableUpdateCompanionBuilder,
      (
        LocalPoliticalOrganization,
        BaseReferences<
          _$AppDatabase,
          $LocalPoliticalOrganizationsTableTable,
          LocalPoliticalOrganization
        >,
      ),
      LocalPoliticalOrganization,
      PrefetchHooks Function()
    >;
typedef $$LocalPersonerosTableTableCreateCompanionBuilder =
    LocalPersonerosTableCompanion Function({
      Value<int> id,
      required String dni,
      required String firstName,
      required String lastName,
      required String pollingStationCode,
      Value<String?> phoneNumber,
      Value<String?> email,
      Value<bool> isActive,
      Value<DateTime> createdAt,
    });
typedef $$LocalPersonerosTableTableUpdateCompanionBuilder =
    LocalPersonerosTableCompanion Function({
      Value<int> id,
      Value<String> dni,
      Value<String> firstName,
      Value<String> lastName,
      Value<String> pollingStationCode,
      Value<String?> phoneNumber,
      Value<String?> email,
      Value<bool> isActive,
      Value<DateTime> createdAt,
    });

class $$LocalPersonerosTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPersonerosTableTable> {
  $$LocalPersonerosTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dni => $composableBuilder(
    column: $table.dni,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pollingStationCode => $composableBuilder(
    column: $table.pollingStationCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPersonerosTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPersonerosTableTable> {
  $$LocalPersonerosTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dni => $composableBuilder(
    column: $table.dni,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pollingStationCode => $composableBuilder(
    column: $table.pollingStationCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPersonerosTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPersonerosTableTable> {
  $$LocalPersonerosTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dni =>
      $composableBuilder(column: $table.dni, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get pollingStationCode => $composableBuilder(
    column: $table.pollingStationCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalPersonerosTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPersonerosTableTable,
          LocalPersonero,
          $$LocalPersonerosTableTableFilterComposer,
          $$LocalPersonerosTableTableOrderingComposer,
          $$LocalPersonerosTableTableAnnotationComposer,
          $$LocalPersonerosTableTableCreateCompanionBuilder,
          $$LocalPersonerosTableTableUpdateCompanionBuilder,
          (
            LocalPersonero,
            BaseReferences<
              _$AppDatabase,
              $LocalPersonerosTableTable,
              LocalPersonero
            >,
          ),
          LocalPersonero,
          PrefetchHooks Function()
        > {
  $$LocalPersonerosTableTableTableManager(
    _$AppDatabase db,
    $LocalPersonerosTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPersonerosTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPersonerosTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalPersonerosTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> dni = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> pollingStationCode = const Value.absent(),
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocalPersonerosTableCompanion(
                id: id,
                dni: dni,
                firstName: firstName,
                lastName: lastName,
                pollingStationCode: pollingStationCode,
                phoneNumber: phoneNumber,
                email: email,
                isActive: isActive,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String dni,
                required String firstName,
                required String lastName,
                required String pollingStationCode,
                Value<String?> phoneNumber = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LocalPersonerosTableCompanion.insert(
                id: id,
                dni: dni,
                firstName: firstName,
                lastName: lastName,
                pollingStationCode: pollingStationCode,
                phoneNumber: phoneNumber,
                email: email,
                isActive: isActive,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPersonerosTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPersonerosTableTable,
      LocalPersonero,
      $$LocalPersonerosTableTableFilterComposer,
      $$LocalPersonerosTableTableOrderingComposer,
      $$LocalPersonerosTableTableAnnotationComposer,
      $$LocalPersonerosTableTableCreateCompanionBuilder,
      $$LocalPersonerosTableTableUpdateCompanionBuilder,
      (
        LocalPersonero,
        BaseReferences<
          _$AppDatabase,
          $LocalPersonerosTableTable,
          LocalPersonero
        >,
      ),
      LocalPersonero,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalActsTableTableTableManager get localActsTable =>
      $$LocalActsTableTableTableManager(_db, _db.localActsTable);
  $$LocalActTotalsTableTableTableManager get localActTotalsTable =>
      $$LocalActTotalsTableTableTableManager(_db, _db.localActTotalsTable);
  $$LocalActResultsTableTableTableManager get localActResultsTable =>
      $$LocalActResultsTableTableTableManager(_db, _db.localActResultsTable);
  $$LocalActEvidenceTableTableTableManager get localActEvidenceTable =>
      $$LocalActEvidenceTableTableTableManager(_db, _db.localActEvidenceTable);
  $$LocalSyncOperationsTableTableTableManager get localSyncOperationsTable =>
      $$LocalSyncOperationsTableTableTableManager(
        _db,
        _db.localSyncOperationsTable,
      );
  $$LocalPollingStationsTableTableTableManager get localPollingStationsTable =>
      $$LocalPollingStationsTableTableTableManager(
        _db,
        _db.localPollingStationsTable,
      );
  $$LocalPoliticalOrganizationsTableTableTableManager
  get localPoliticalOrganizationsTable =>
      $$LocalPoliticalOrganizationsTableTableTableManager(
        _db,
        _db.localPoliticalOrganizationsTable,
      );
  $$LocalPersonerosTableTableTableManager get localPersonerosTable =>
      $$LocalPersonerosTableTableTableManager(_db, _db.localPersonerosTable);
}
