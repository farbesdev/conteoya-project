import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conteoya_mobile/core/database/app_database.dart';
import 'package:conteoya_mobile/features/acts/domain/act_validator.dart';
import 'package:conteoya_mobile/features/acts/domain/electoral_level.dart';
import 'package:conteoya_mobile/features/mesas/data/mesas_repository.dart';

void main() {
  late AppDatabase db;
  late MesasRepository mesasRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.seedInitialDataIfEmpty();
    mesasRepo = MesasRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Electoral levels contienen las opciones de Acta Regional y Municipal', () {
    expect(kElectoralLevels.length, greaterThanOrEqualTo(2));
    final regional = getElectoralLevelById(1);
    expect(regional.code, 'REGIONAL_GOBERNADOR');
    expect(regional.shortTitle, 'Gobernador Regional');

    final municipal = getElectoralLevelById(2);
    expect(municipal.code, 'MUNICIPAL_PROVINCIAL');
    expect(municipal.shortTitle, 'Municipal Provincial');
  });

  test('MesasRepository consulta mesas iniciales y estado de actas', () async {
    final mesa = await mesasRepo.getMesaByCode('030390');
    expect(mesa, isNotNull);
    expect(mesa!.code, '030390');
    expect(mesa.locationName, 'I.E. NUESTRA SEÑORA DE GUADALUPE');
    expect(mesa.hasPersoneroAssigned, isTrue);
    expect(mesa.assignedPersoneroName, contains('Juan'));
    expect(mesa.regionalStatus.isPendiente, isTrue);
    expect(mesa.municipalStatus.isPendiente, isTrue);
    expect(mesa.registeredActsCount, 0);
  });

  test('ActValidator calcula soft warnings cuando no cuadran los totales', () {
    final result = ActValidator.validate(
      registeredVoters: 300,
      votersWhoVoted: 280,
      totalVotes: 280,
      blankVotes: 10,
      nullVotes: 5,
      challengedVotes: 0,
      candidateVotes: [85, 70, 55, 30, 25], // Suma: 265 + 15 = 280 (Exacto)
    );

    expect(result.isValid, isTrue);
    expect(result.warnings, isEmpty);

    final mismatched = ActValidator.validate(
      registeredVoters: 300,
      votersWhoVoted: 280,
      totalVotes: 280,
      blankVotes: 20, // Suma dará 290 != 280
      nullVotes: 5,
      challengedVotes: 0,
      candidateVotes: [85, 70, 55, 30, 25],
    );

    expect(mismatched.isValid, isFalse);
    expect(mismatched.warnings, isNotEmpty);
    expect(mismatched.warnings.any((w) => w.code == 'TOTAL_MISMATCH'), isTrue);
  });
}
