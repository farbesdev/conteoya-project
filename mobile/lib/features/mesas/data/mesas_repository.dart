import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../../../core/database/app_database.dart';
import '../domain/mesa_model.dart';

class MesasRepository {
  final AppDatabase db;
  final ApiClient? apiClient;

  MesasRepository({required this.db, this.apiClient});

  /// Consulta mesas paginadas del backend API (para Admin/Director) y las guarda en SQLite local
  Future<bool> fetchRemotePollingStations({
    String search = '',
    int page = 1,
    int perPage = 10,
  }) async {
    if (apiClient == null) return false;
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      final response = await apiClient!.get<Map<String, Object?>>(
        '/polling-stations',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final dataList = response.data!['data'] as List<Object?>? ?? [];
        final meta = response.data!['meta'] as Map<String, Object?>? ?? {};
        final hasMore = (meta['has_more'] as bool?) ?? false;

        final stationCompanions = <LocalPollingStationsTableCompanion>[];
        for (final item in dataList) {
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
        }
        return hasMore;
      }
    } catch (_) {
      // Si falla la red (modo offline), se maneja silenciosamente
    }
    return false;
  }

  /// Emite la lista reactiva de todas las mesas enriquecidas con su personero y estado de actas
  Stream<List<MesaModel>> watchMesasWithDetails() {
    return db.watchAllPollingStations().asyncMap((stations) async {
      final personeros = await db.getAllPersoneros();
      final personerosByStation = {for (var p in personeros) p.pollingStationCode: p};

      final allActs = await (db.select(db.localActsTable)).get();

      return stations.map((station) {
        final personero = personerosByStation[station.code];

        // Buscar acta regional (level 1)
        final regionalAct = allActs.cast<LocalAct?>().firstWhere(
              (a) => a?.pollingStationCode == station.code && a?.electoralLevelId == 1,
              orElse: () => null,
            );

        // Buscar acta municipal provincial-distrital (level 2 o 3)
        final municipalAct = allActs.cast<LocalAct?>().firstWhere(
              (a) => a?.pollingStationCode == station.code && (a?.electoralLevelId == 2 || a?.electoralLevelId == 3),
              orElse: () => null,
            );

        return MesaModel(
          id: station.id,
          code: station.code,
          locationName: station.locationName,
          districtCode: station.districtCode,
          districtName: station.districtName,
          provinceName: station.provinceName,
          departmentName: station.departmentName,
          registeredVoters: station.registeredVoters,
          status: station.status,
          assignedPersoneroName: personero != null ? '${personero.firstName} ${personero.lastName}' : null,
          assignedPersoneroDni: personero?.dni,
          regionalStatus: ActRegistrationStatus.fromDbStatus(regionalAct?.status),
          municipalStatus: ActRegistrationStatus.fromDbStatus(municipalAct?.status),
        );
      }).toList();
    });
  }

  /// Obtiene la mesa asignada a un código de mesa
  Future<MesaModel?> getMesaByCode(String code) async {
    final cleanCode = code.trim();
    final station = await db.getPollingStationByCode(cleanCode);
    if (station == null) return null;

    final personero = await db.getPersoneroByStation(cleanCode);
    final stationActs = await db.getActsByPollingStation(cleanCode);

    final regionalAct = stationActs.cast<LocalAct?>().firstWhere(
          (a) => a?.electoralLevelId == 1,
          orElse: () => null,
        );

    final municipalAct = stationActs.cast<LocalAct?>().firstWhere(
          (a) => a?.electoralLevelId == 2 || a?.electoralLevelId == 3,
          orElse: () => null,
        );

    return MesaModel(
      id: station.id,
      code: station.code,
      locationName: station.locationName,
      districtCode: station.districtCode,
      districtName: station.districtName,
      provinceName: station.provinceName,
      departmentName: station.departmentName,
      registeredVoters: station.registeredVoters,
      status: station.status,
      assignedPersoneroName: personero != null ? '${personero.firstName} ${personero.lastName}' : null,
      assignedPersoneroDni: personero?.dni,
      regionalStatus: ActRegistrationStatus.fromDbStatus(regionalAct?.status),
      municipalStatus: ActRegistrationStatus.fromDbStatus(municipalAct?.status),
    );
  }

  /// Registra una nueva mesa de votación
  Future<void> createMesa({
    required String code,
    required String locationName,
    String? districtName,
    String? provinceName,
    String? departmentName,
    int registeredVoters = 300,
  }) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      throw Exception('El código o número de mesa es obligatorio.');
    }

    final existing = await db.getPollingStationByCode(cleanCode);
    if (existing != null) {
      throw Exception('La mesa con código $cleanCode ya se encuentra registrada.');
    }

    final cleanLocation = locationName.trim().isEmpty ? 'LOCAL DE VOTACIÓN PRINCIPAL' : locationName.trim();
    final cleanDistrict = districtName ?? 'LIMA - CERCADO';
    final cleanProvince = provinceName ?? 'LIMA';
    final cleanDepartment = departmentName ?? 'LIMA';
    final cleanVoters = registeredVoters > 0 ? registeredVoters : 300;

    await db.insertPollingStation(
      LocalPollingStationsTableCompanion.insert(
        code: cleanCode,
        locationName: cleanLocation,
        districtName: Value(cleanDistrict),
        provinceName: Value(cleanProvince),
        departmentName: Value(cleanDepartment),
        registeredVoters: Value(cleanVoters),
      ),
    );

    // Encolar operación de sincronización ascendente (Push -> VPS con UUIDv4 válido)
    await db.enqueueSyncOperation(
      LocalSyncOperationsTableCompanion.insert(
        clientOperationId: const Uuid().v4(),
        entityType: 'polling_stations',
        entityId: cleanCode,
        operation: const Value('CREATE'),
        payloadJson: jsonEncode({
          'code': cleanCode,
          'location_name': cleanLocation,
          'district_name': cleanDistrict,
          'province_name': cleanProvince,
          'department_name': cleanDepartment,
          'registered_voters': cleanVoters,
          'status': 'ACTIVE',
        }),
        status: const Value('PENDING'),
      ),
    );
  }

  Future<void> updateMesa({
    required String code,
    required String locationName,
    String? districtName,
    String? provinceName,
    String? departmentName,
    int registeredVoters = 300,
  }) async {
    final cleanCode = code.trim();
    final cleanLocation = locationName.trim();
    final cleanVoters = registeredVoters > 0 ? registeredVoters : 300;

    await db.updatePollingStation(
      LocalPollingStationsTableCompanion(
        code: Value(cleanCode),
        locationName: Value(cleanLocation),
        districtName: districtName != null ? Value(districtName) : const Value.absent(),
        provinceName: provinceName != null ? Value(provinceName) : const Value.absent(),
        departmentName: departmentName != null ? Value(departmentName) : const Value.absent(),
        registeredVoters: Value(cleanVoters),
      ),
    );

    await db.enqueueSyncOperation(
      LocalSyncOperationsTableCompanion.insert(
        clientOperationId: const Uuid().v4(),
        entityType: 'polling_stations',
        entityId: cleanCode,
        operation: const Value('UPDATE'),
        payloadJson: jsonEncode({
          'code': cleanCode,
          'location_name': cleanLocation,
          'district_name': districtName,
          'province_name': provinceName,
          'department_name': departmentName,
          'registered_voters': cleanVoters,
          'status': 'ACTIVE',
        }),
        status: const Value('PENDING'),
      ),
    );
  }

  Future<void> deleteMesa(String code) async {
    final cleanCode = code.trim();
    await db.deletePollingStationByCode(cleanCode);

    await db.enqueueSyncOperation(
      LocalSyncOperationsTableCompanion.insert(
        clientOperationId: const Uuid().v4(),
        entityType: 'polling_stations',
        entityId: cleanCode,
        operation: const Value('DELETE'),
        payloadJson: jsonEncode({
          'code': cleanCode,
        }),
        status: const Value('PENDING'),
      ),
    );
  }
}
