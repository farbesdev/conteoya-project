import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../domain/mesa_model.dart';

class MesasRepository {
  final AppDatabase db;

  MesasRepository({required this.db});

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
}
