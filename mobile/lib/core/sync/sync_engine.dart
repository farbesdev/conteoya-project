import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import 'backoff_calculator.dart';

enum SyncEngineState { idle, syncing, offline, error }

class SyncEngine {
  final AppDatabase db;
  final ApiClient apiClient;
  final Connectivity connectivity;

  Timer? _periodicTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  final StreamController<SyncEngineState> _stateController =
      StreamController<SyncEngineState>.broadcast();

  Stream<SyncEngineState> get stateStream => _stateController.stream;

  SyncEngine({
    required this.db,
    required this.apiClient,
    Connectivity? connectivity,
  }) : connectivity = connectivity ?? Connectivity();

  void start() {
    // Sincronización periódica cada 30 segundos
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) => syncPendingOperations());

    // Escuchar cambios de conectividad
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        _stateController.add(SyncEngineState.idle);
        syncPendingOperations();
      } else {
        _stateController.add(SyncEngineState.offline);
      }
    });

    // Intento inicial
    syncPendingOperations();
  }

  void stop() {
    _periodicTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Ejecuta un ciclo de sincronización de operaciones pendientes (push) y luego descarga datos del servidor (pull)
  Future<Map<String, int>> syncPendingOperations() async {
    if (_isSyncing) return {'polling_stations': 0, 'personeros': 0, 'political_organizations': 0};
    _isSyncing = true;
    _stateController.add(SyncEngineState.syncing);

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString('conteoya_user_session');
      String userRole = 'PERSONERO';
      if (sessionJson != null) {
        try {
          final Map<String, dynamic> data = jsonDecode(sessionJson) as Map<String, dynamic>;
          userRole = data['role']?.toString().toUpperCase() ?? 'PERSONERO';
        } catch (_) {}
      }

      final isPersonero = userRole == 'PERSONERO';

      // 1. SINCRONIZACIÓN DESCENDENTE (PULL): Descargar mesas, personeros y catálogos actualizados desde el VPS
      final pullMetrics = await pullLatestDataFromBackend(isPersonero: isPersonero);

      // 2. SINCRONIZACIÓN ASCENDENTE (PUSH): Enviar operaciones pendientes al VPS (POST /api/v1/sync)
      // Si el rol es PERSONERO, únicamente se envían 'acts' y 'act_evidence'
      final rawPendingOps = await db.getPendingSyncOperations();
      final pendingOps = isPersonero
          ? rawPendingOps.where((op) => op.entityType == 'acts' || op.entityType == 'act_evidence').toList()
          : rawPendingOps;

      if (pendingOps.isNotEmpty) {
        final operationsPayload = pendingOps.map((op) {
          final Map<String, Object?> parsedPayload =
              jsonDecode(op.payloadJson) as Map<String, Object?>;
          return {
            'client_operation_id': op.clientOperationId,
            'entity_type': op.entityType,
            'entity_id': op.entityId,
            'operation': op.operation,
            'payload': parsedPayload,
            'checksum': op.checksum,
          };
        }).toList();

        final response = await apiClient.post<Map<String, Object?>>(
          '/sync',
          data: {
            'device_uuid': pendingOps.first.deviceUuid,
            'operations': operationsPayload,
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          final dataList = response.data!['data'] as List<Object?>? ?? [];
          for (final item in dataList) {
            if (item is Map<String, Object?>) {
              final clientOpId = item['client_operation_id'] as String?;
              final status = item['status'] as String? ?? 'FAILED';

              if (clientOpId != null) {
                if (status == 'SYNCED') {
                  await db.updateSyncOpStatus(clientOpId, 'SYNCED');

                  // Encontrar la operación para actualizar el estado de entidades locales
                  final op = pendingOps.firstWhere((o) => o.clientOperationId == clientOpId);
                  if (op.entityType == 'acts') {
                    if (op.operation == 'DELETE') {
                      await db.deleteActByClientUuid(op.entityId);
                    } else {
                      final serverActId = (item['result'] as Map<String, Object?>?)?['act_id'] as int?;
                      await db.updateActStatus(op.entityId, 'SYNCED', serverActId: serverActId);
                    }
                  } else if (op.entityType == 'personeros' && op.operation == 'DELETE') {
                    await db.deletePersoneroByDni(op.entityId);
                  } else if (op.entityType == 'polling_stations' && op.operation == 'DELETE') {
                    await db.deletePollingStationByCode(op.entityId);
                  }
                } else {
                  final error = item['error'] as String? ?? 'Error en sincronización';
                  final op = pendingOps.firstWhere((o) => o.clientOperationId == clientOpId);
                  final nextDelay = ExponentialBackoff.calculateDelay(op.attempts + 1);
                  await db.updateSyncOpStatus(
                    clientOpId,
                    'FAILED',
                    error: error,
                    nextSchedule: DateTime.now().add(nextDelay),
                  );
                }
              }
            }
          }
        }
      }

      _stateController.add(SyncEngineState.idle);
      return pullMetrics;
    } catch (e) {
      _stateController.add(SyncEngineState.error);
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Descarga y actualiza localmente en SQLite los catálogos, mesas y personeros desde el servidor backend (PostgreSQL)
  Future<Map<String, int>> pullLatestDataFromBackend({bool isPersonero = false}) async {
    final response = await apiClient.get<Map<String, Object?>>('/sync/pull');

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data!['data'] as Map<String, Object?>? ?? {};

      // 1. Descargar y upsert de Mesas
      final stationsList = data['polling_stations'] as List<Object?>? ?? [];
      final stationCompanions = <LocalPollingStationsTableCompanion>[];
      for (final item in stationsList) {
        if (item is Map<String, Object?>) {
          final code = item['code'] as String?;
          if (code != null) {
            stationCompanions.add(
              LocalPollingStationsTableCompanion.insert(
                code: code,
                locationName: item['location_name']?.toString() ?? 'LOCAL DE VOTACIÓN',
                districtCode: Value(item['district_code']?.toString() ?? '000000'),
                districtName: Value(item['district_name']?.toString() ?? 'DISTRITO'),
                provinceName: Value(item['province_name']?.toString() ?? 'PROVINCIA'),
                departmentName: Value(item['department_name']?.toString() ?? 'DEPARTAMENTO'),
                registeredVoters: Value((item['registered_voters'] as int?) ?? 300),
                status: Value(item['status']?.toString() ?? 'ACTIVE'),
              ),
            );
          }
        }
      }
      if (stationCompanions.isNotEmpty) {
        await db.savePollingStations(stationCompanions);

        // Eliminar mesas locales que ya no existen en el servidor (salvo operaciones locales pendientes)
        if (!isPersonero) {
          final serverCodes = stationCompanions.map((s) => s.code.value).toSet();
          final allLocalStations = await db.getAllPollingStations();
          final pendingOps = await db.getPendingSyncOperations();
          final pendingEntityIds = pendingOps.map((op) => op.entityId).toSet();

          for (final localS in allLocalStations) {
            if (!serverCodes.contains(localS.code) && !pendingEntityIds.contains(localS.code)) {
              await db.deletePollingStationByCode(localS.code);
            }
          }
        }
      }

      // 2. Descargar y upsert de Personeros
      final personerosList = data['personeros'] as List<Object?>? ?? [];
      final personeroCompanions = <LocalPersonerosTableCompanion>[];
      for (final item in personerosList) {
        if (item is Map<String, Object?>) {
          final dni = item['dni']?.toString();
          final firstName = item['first_name']?.toString() ?? 'Personero';
          final lastName = item['last_name']?.toString() ?? ' ';
          final stationCode = item['polling_station_code']?.toString() ?? '030390';
          if (dni != null && dni.isNotEmpty) {
            personeroCompanions.add(
              LocalPersonerosTableCompanion.insert(
                dni: dni,
                firstName: firstName,
                lastName: lastName,
                pollingStationCode: stationCode,
                phoneNumber: Value(item['phone_number']?.toString()),
                email: Value(item['email']?.toString()),
              ),
            );
          }
        }
      }
      if (personeroCompanions.isNotEmpty) {
        await db.savePersoneros(personeroCompanions);

        // Eliminar personeros locales que fueron eliminados en el servidor
        if (!isPersonero) {
          final serverDnis = personeroCompanions.map((p) => p.dni.value).toSet();
          final allLocalPersoneros = await db.getAllPersoneros();
          final pendingOps = await db.getPendingSyncOperations();
          final pendingEntityIds = pendingOps.map((op) => op.entityId).toSet();

          for (final localP in allLocalPersoneros) {
            if (!serverDnis.contains(localP.dni) && !pendingEntityIds.contains(localP.dni)) {
              await db.deletePersonero(localP.id);
            }
          }
        }
      }

      // 3. Descargar y upsert de Organizaciones Políticas
      final orgsList = data['political_organizations'] as List<Object?>? ?? [];
      final orgCompanions = <LocalPoliticalOrganizationsTableCompanion>[];
      for (final item in orgsList) {
        if (item is Map<String, Object?>) {
          final id = item['id'] as int?;
          final name = item['name'] as String?;
          if (id != null && name != null) {
            orgCompanions.add(
              LocalPoliticalOrganizationsTableCompanion.insert(
                id: Value(id),
                name: name,
                shortName: Value(item['short_name']?.toString()),
                logoUrl: Value(item['logo_url']?.toString()),
              ),
            );
          }
        }
      }
      if (orgCompanions.isNotEmpty) {
        await db.savePoliticalOrganizations(orgCompanions);
      }

      return {
        'polling_stations': stationCompanions.length,
        'personeros': personeroCompanions.length,
        'political_organizations': orgCompanions.length,
      };
    }

    return {'polling_stations': 0, 'personeros': 0, 'political_organizations': 0};
  }
}
