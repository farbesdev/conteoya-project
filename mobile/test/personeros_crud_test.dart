import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conteoya_mobile/core/database/app_database.dart';
import 'package:conteoya_mobile/features/personeros/data/personeros_repository.dart';

void main() {
  late AppDatabase db;
  late PersonerosRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.seedInitialDataIfEmpty();
    repo = PersonerosRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('PersonerosRepository permite crear personero válido con mesa asignada', () async {
    await repo.createPersonero(
      dni: '45678901',
      firstName: 'Carlos',
      lastName: 'Gutiérrez',
      pollingStationCode: '030392',
      phoneNumber: '+51 999 888 777',
      email: 'cgutierrez@conteoya.pe',
    );

    final personero = await repo.getPersoneroByDni('45678901');
    expect(personero, isNotNull);
    expect(personero!.firstName, 'Carlos');
    expect(personero.lastName, 'Gutiérrez');
    expect(personero.pollingStationCode, '030392');
  });

  test('PersonerosRepository rechaza DNI inválido que no tenga 8 dígitos numéricos', () async {
    expect(
      () => repo.createPersonero(
        dni: '1234', // Inválido
        firstName: 'Carlos',
        lastName: 'Gutiérrez',
        pollingStationCode: '030392',
      ),
      throwsA(isA<PersoneroValidationException>()),
    );

    expect(
      () => repo.createPersonero(
        dni: '1234567A', // Letras
        firstName: 'Carlos',
        lastName: 'Gutiérrez',
        pollingStationCode: '030392',
      ),
      throwsA(isA<PersoneroValidationException>()),
    );
  });

  test('PersonerosRepository rechaza DNI duplicado', () async {
    // 12345678 ya fue sembrado en seedInitialDataIfEmpty
    expect(
      () => repo.createPersonero(
        dni: '12345678',
        firstName: 'Otro',
        lastName: 'Personero',
        pollingStationCode: '030393',
      ),
      throwsA(isA<PersoneroValidationException>()),
    );
  });

  test('PersonerosRepository permite asignación de múltiples personeros a la misma mesa', () async {
    await repo.createPersonero(
      dni: '99887766',
      firstName: 'Nuevo',
      lastName: 'Personero',
      pollingStationCode: '030390',
    );
    final p = await repo.getPersoneroByDni('99887766');
    expect(p?.dni, '99887766');
  });

  test('PersonerosRepository permite actualizar y eliminar personero', () async {
    final personero = await repo.getPersoneroByDni('12345678');
    expect(personero, isNotNull);

    // Actualizar nombres y teléfono
    await repo.updatePersonero(
      id: personero!.id,
      dni: '12345678',
      firstName: 'Juan Actualizado',
      lastName: 'Pérez García',
      pollingStationCode: '030390',
      phoneNumber: '+51 900 000 000',
    );

    final updated = await repo.getPersoneroByDni('12345678');
    expect(updated!.firstName, 'Juan Actualizado');
    expect(updated.phoneNumber, '+51 900 000 000');

    // Eliminar personero
    await repo.deletePersonero(personero.id);
    final deleted = await repo.getPersoneroByDni('12345678');
    expect(deleted, isNull);
  });
}
