import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../domain/personero_model.dart';

class PersoneroValidationException implements Exception {
  final String message;
  PersoneroValidationException(this.message);

  @override
  String toString() => message;
}

class PersonerosRepository {
  final AppDatabase db;
  final ApiClient? apiClient;

  PersonerosRepository({required this.db, this.apiClient});

  /// Consulta personeros paginados del backend API (para Admin/Director) de forma remota
  Future<({List<PersoneroModel> items, bool hasMore, int total})> fetchRemotePersoneros({
    String search = '',
    int page = 1,
    int perPage = 15,
  }) async {
    if (apiClient == null) return (items: <PersoneroModel>[], hasMore: false, total: 0);
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      final response = await apiClient!.get<Map<String, Object?>>(
        '/personeros',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final dataList = response.data!['data'] as List<Object?>? ?? [];
        final meta = response.data!['meta'] as Map<String, Object?>? ?? {};
        final hasMore = (meta['has_more'] as bool?) ?? false;
        final total = (meta['total'] as int?) ?? 0;

        final items = <PersoneroModel>[];
        for (final item in dataList) {
          if (item is Map<String, Object?>) {
            final id = (item['id'] as int?) ?? 0;
            final dni = item['dni']?.toString() ?? '';
            final firstName = item['first_name']?.toString() ?? '';
            final lastName = item['last_name']?.toString() ?? '';
            final rawCodes = item['polling_station_codes'];
            List<String> stationCodes = [];
            if (rawCodes is List) {
              stationCodes = rawCodes.map((c) => c.toString()).toList();
            } else if (item['polling_station_code'] != null && item['polling_station_code'].toString().isNotEmpty) {
              stationCodes = [item['polling_station_code'].toString()];
            }
            final phone = item['phone_number']?.toString();
            final email = item['email']?.toString();
            final isActive = (item['is_active'] as bool?) ?? false;
            final politicalOrg = item['political_organization_name']?.toString();
            final status = item['status']?.toString();
            final personeroType = item['personero_type']?.toString();

            items.add(
              PersoneroModel(
                id: id,
                dni: dni,
                firstName: firstName,
                lastName: lastName,
                pollingStationCodes: stationCodes,
                phoneNumber: phone,
                email: email,
                isActive: isActive,
                politicalOrganizationName: politicalOrg,
                status: status,
                personeroType: personeroType,
                createdAt: DateTime.now(),
              ),
            );
          }
        }
        return (items: items, hasMore: hasMore, total: total);
      }
    } catch (_) {}
    return (items: <PersoneroModel>[], hasMore: false, total: 0);
  }

  Stream<List<PersoneroModel>> watchPersoneros() {
    return db.watchAllPersoneros().map((list) => list.map(_mapToModel).toList());
  }

  Future<List<PersoneroModel>> getAllPersoneros() async {
    final list = await db.getAllPersoneros();
    return list.map(_mapToModel).toList();
  }

  Future<PersoneroModel?> getPersoneroByDni(String dni) async {
    final entity = await db.getPersoneroByDni(dni.trim());
    if (entity == null) return null;
    return _mapToModel(entity);
  }

  Future<PersoneroModel?> getPersoneroByStation(String pollingStationCode) async {
    final entity = await db.getPersoneroByStation(pollingStationCode.trim());
    if (entity == null) return null;
    return _mapToModel(entity);
  }

  Future<void> createPersonero({
    required String dni,
    required String firstName,
    required String lastName,
    List<String>? pollingStationCodes,
    String? pollingStationCode,
    String? phoneNumber,
    String? email,
  }) async {
    final cleanDni = dni.trim();
    final cleanFirst = firstName.trim();
    final cleanLast = lastName.trim();
    final List<String> cleanStations = (pollingStationCodes ?? (pollingStationCode != null ? [pollingStationCode] : []))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // 1. Validar DNI (8 dígitos numéricos peruanos)
    if (!RegExp(r'^\d{8}$').hasMatch(cleanDni)) {
      throw PersoneroValidationException('El DNI debe contener exactamente 8 dígitos numéricos.');
    }

    // 2. Validar Nombres y Apellidos obligatorios
    if (cleanFirst.isEmpty || cleanLast.isEmpty) {
      throw PersoneroValidationException('Los nombres y apellidos son obligatorios.');
    }

    // 3. Validar Asignación obligatoria de Mesa
    if (cleanStations.isEmpty) {
      throw PersoneroValidationException('Debe asignar al menos una mesa de votación al personero.');
    }

    final primaryStation = cleanStations.first;

    // 4. Validar que no exista personero con el mismo DNI
    final existingDni = await db.getPersoneroByDni(cleanDni);
    if (existingDni != null) {
      throw PersoneroValidationException('Ya existe un personero registrado con el DNI $cleanDni.');
    }

    // 5. Insertar en Drift SQLite
    await db.insertPersonero(
      LocalPersonerosTableCompanion.insert(
        dni: cleanDni,
        firstName: cleanFirst,
        lastName: cleanLast,
        pollingStationCode: primaryStation,
        phoneNumber: phoneNumber != null && phoneNumber.trim().isNotEmpty
            ? Value(phoneNumber.trim())
            : const Value.absent(),
        email: email != null && email.trim().isNotEmpty
            ? Value(email.trim())
            : const Value.absent(),
      ),
    );

    // 6. Encolar operación de sincronización para enviar a API/VPS (UUIDv4 válido para PostgreSQL)
    final clientOpId = const Uuid().v4();
    await db.enqueueSyncOperation(
      LocalSyncOperationsTableCompanion.insert(
        clientOperationId: clientOpId,
        entityType: 'personeros',
        entityId: cleanDni,
        operation: const Value('CREATE'),
        payloadJson: jsonEncode({
          'document_number': cleanDni,
          'first_name': cleanFirst,
          'last_name': cleanLast,
          'name': '$cleanFirst $cleanLast',
          'polling_station_code': primaryStation,
          'polling_station_codes': cleanStations,
          'phone_number': phoneNumber?.trim(),
          'email': email?.trim() ?? 'personero_$cleanDni@conteoya.pe',
        }),
        status: const Value('PENDING'),
      ),
    );
  }

  Future<void> updatePersonero({
    required int id,
    required String dni,
    required String firstName,
    required String lastName,
    List<String>? pollingStationCodes,
    String? pollingStationCode,
    String? phoneNumber,
    String? email,
  }) async {
    final cleanDni = dni.trim();
    final cleanFirst = firstName.trim();
    final cleanLast = lastName.trim();
    final List<String> cleanStations = (pollingStationCodes ?? (pollingStationCode != null ? [pollingStationCode] : []))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // 1. Validar DNI
    if (!RegExp(r'^\d{8}$').hasMatch(cleanDni)) {
      throw PersoneroValidationException('El DNI debe contener exactamente 8 dígitos numéricos.');
    }

    // 2. Validar Nombres
    if (cleanFirst.isEmpty || cleanLast.isEmpty) {
      throw PersoneroValidationException('Los nombres y apellidos son obligatorios.');
    }

    // 3. Validar Asignación obligatoria
    if (cleanStations.isEmpty) {
      throw PersoneroValidationException('Debe asignar al menos una mesa de votación al personero.');
    }

    final primaryStation = cleanStations.first;

    // 4. Validar que el DNI no pertenezca a OTRO personero
    final existingDni = await db.getPersoneroByDni(cleanDni);
    if (existingDni != null && existingDni.id != id) {
      throw PersoneroValidationException('El DNI $cleanDni ya pertenece a otro personero.');
    }

    // 5. Actualizar en Drift SQLite
    await db.updatePersonero(
      LocalPersonerosTableCompanion(
        id: Value(id),
        dni: Value(cleanDni),
        firstName: Value(cleanFirst),
        lastName: Value(cleanLast),
        pollingStationCode: Value(primaryStation),
        phoneNumber: Value(phoneNumber?.trim()),
        email: Value(email?.trim()),
      ),
    );

    // 6. Encolar operación de sincronización UPDATE
    final clientOpId = const Uuid().v4();
    await db.enqueueSyncOperation(
      LocalSyncOperationsTableCompanion.insert(
        clientOperationId: clientOpId,
        entityType: 'personeros',
        entityId: cleanDni,
        operation: const Value('UPDATE'),
        payloadJson: jsonEncode({
          'document_number': cleanDni,
          'first_name': cleanFirst,
          'last_name': cleanLast,
          'name': '$cleanFirst $cleanLast'.trim(),
          'polling_station_code': primaryStation,
          'polling_station_codes': cleanStations,
          'phone_number': phoneNumber?.trim(),
          'email': email?.trim() ?? 'personero_$cleanDni@conteoya.pe',
        }),
        status: const Value('PENDING'),
      ),
    );
  }

  Future<void> deletePersonero(int id) async {
    final existing = await (db.select(db.localPersonerosTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await db.deletePersonero(id);

      final clientOpId = const Uuid().v4();
      await db.enqueueSyncOperation(
        LocalSyncOperationsTableCompanion.insert(
          clientOperationId: clientOpId,
          entityType: 'personeros',
          entityId: existing.dni,
          operation: const Value('DELETE'),
          payloadJson: jsonEncode({
            'document_number': existing.dni,
            'email': existing.email ?? 'personero_${existing.dni}@conteoya.pe',
          }),
          status: const Value('PENDING'),
        ),
      );
    }
  }

  Future<bool> togglePersoneroAccess(int id) async {
    final existing = await (db.select(db.localPersonerosTable)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) return false;

    final newState = !existing.isActive;

    await db.updatePersonero(
      LocalPersonerosTableCompanion(
        id: Value(existing.id),
        dni: Value(existing.dni),
        firstName: Value(existing.firstName),
        lastName: Value(existing.lastName),
        pollingStationCode: Value(existing.pollingStationCode),
        isActive: Value(newState),
      ),
    );

    return newState;
  }

  PersoneroModel _mapToModel(LocalPersonero entity) {
    return PersoneroModel(
      id: entity.id,
      dni: entity.dni,
      firstName: entity.firstName,
      lastName: entity.lastName,
      pollingStationCode: entity.pollingStationCode,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}
