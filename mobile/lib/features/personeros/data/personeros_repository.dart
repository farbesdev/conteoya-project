import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../domain/personero_model.dart';

class PersoneroValidationException implements Exception {
  final String message;
  PersoneroValidationException(this.message);

  @override
  String toString() => message;
}

class PersonerosRepository {
  final AppDatabase db;

  PersonerosRepository({required this.db});

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
    required String pollingStationCode,
    String? phoneNumber,
    String? email,
  }) async {
    final cleanDni = dni.trim();
    final cleanFirst = firstName.trim();
    final cleanLast = lastName.trim();
    final cleanStation = pollingStationCode.trim();

    // 1. Validar DNI (8 dígitos numéricos peruanos)
    if (!RegExp(r'^\d{8}$').hasMatch(cleanDni)) {
      throw PersoneroValidationException('El DNI debe contener exactamente 8 dígitos numéricos.');
    }

    // 2. Validar Nombres y Apellidos obligatorios
    if (cleanFirst.isEmpty || cleanLast.isEmpty) {
      throw PersoneroValidationException('Los nombres y apellidos son obligatorios.');
    }

    // 3. Validar Asignación obligatoria de Mesa
    if (cleanStation.isEmpty) {
      throw PersoneroValidationException('Debe asignar una mesa de votación al personero.');
    }

    // 4. Validar que no exista personero con el mismo DNI
    final existingDni = await db.getPersoneroByDni(cleanDni);
    if (existingDni != null) {
      throw PersoneroValidationException('Ya existe un personero registrado con el DNI $cleanDni.');
    }

    // 5. Validar que la mesa no esté ya asignada a otro personero
    final existingStationPersonero = await db.getPersoneroByStation(cleanStation);
    if (existingStationPersonero != null) {
      throw PersoneroValidationException(
        'La mesa $cleanStation ya se encuentra asignada al personero ${existingStationPersonero.firstName} ${existingStationPersonero.lastName}.',
      );
    }

    // 6. Insertar en Drift SQLite
    await db.insertPersonero(
      LocalPersonerosTableCompanion.insert(
        dni: cleanDni,
        firstName: cleanFirst,
        lastName: cleanLast,
        pollingStationCode: cleanStation,
        phoneNumber: phoneNumber != null && phoneNumber.trim().isNotEmpty
            ? Value(phoneNumber.trim())
            : const Value.absent(),
        email: email != null && email.trim().isNotEmpty
            ? Value(email.trim())
            : const Value.absent(),
      ),
    );
  }

  Future<void> updatePersonero({
    required int id,
    required String dni,
    required String firstName,
    required String lastName,
    required String pollingStationCode,
    String? phoneNumber,
    String? email,
  }) async {
    final cleanDni = dni.trim();
    final cleanFirst = firstName.trim();
    final cleanLast = lastName.trim();
    final cleanStation = pollingStationCode.trim();

    // 1. Validar DNI
    if (!RegExp(r'^\d{8}$').hasMatch(cleanDni)) {
      throw PersoneroValidationException('El DNI debe contener exactamente 8 dígitos numéricos.');
    }

    // 2. Validar Nombres
    if (cleanFirst.isEmpty || cleanLast.isEmpty) {
      throw PersoneroValidationException('Los nombres y apellidos son obligatorios.');
    }

    // 3. Validar Asignación obligatoria
    if (cleanStation.isEmpty) {
      throw PersoneroValidationException('Debe asignar una mesa de votación al personero.');
    }

    // 4. Validar que el DNI no pertenezca a OTRO personero
    final existingDni = await db.getPersoneroByDni(cleanDni);
    if (existingDni != null && existingDni.id != id) {
      throw PersoneroValidationException('El DNI $cleanDni ya pertenece a otro personero.');
    }

    // 5. Validar que la mesa no esté asignada a OTRO personero
    final existingStationPersonero = await db.getPersoneroByStation(cleanStation);
    if (existingStationPersonero != null && existingStationPersonero.id != id) {
      throw PersoneroValidationException(
        'La mesa $cleanStation ya está asignada a ${existingStationPersonero.firstName} ${existingStationPersonero.lastName}.',
      );
    }

    // 6. Actualizar en Drift SQLite
    await db.updatePersonero(
      LocalPersonerosTableCompanion(
        id: Value(id),
        dni: Value(cleanDni),
        firstName: Value(cleanFirst),
        lastName: Value(cleanLast),
        pollingStationCode: Value(cleanStation),
        phoneNumber: Value(phoneNumber?.trim()),
        email: Value(email?.trim()),
      ),
    );
  }

  Future<void> deletePersonero(int id) async {
    await db.deletePersonero(id);
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
      createdAt: entity.createdAt,
    );
  }
}
