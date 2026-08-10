import 'package:flutter_test/flutter_test.dart';
import 'package:conteoya_mobile/features/acts/domain/act_validator.dart';

void main() {
  group('ActValidator Tests', () {
    test('Valida correctamente totales consistentes', () {
      final result = ActValidator.validate(
        registeredVoters: 300,
        votersWhoVoted: 280,
        totalVotes: 280,
        blankVotes: 15,
        nullVotes: 10,
        challengedVotes: 5,
        candidateVotes: [150, 100], // 150 + 100 + 15 + 10 + 5 = 280
      );

      expect(result.isValid, isTrue);
      expect(result.warnings, isEmpty);
    });

    test('Detecta discrepancia en suma de votos (TOTAL_MISMATCH)', () {
      final result = ActValidator.validate(
        registeredVoters: 300,
        votersWhoVoted: 280,
        totalVotes: 290, // Total declarado 290
        blankVotes: 10,
        nullVotes: 10,
        challengedVotes: 0,
        candidateVotes: [150, 100], // Suma real: 270 != 290
      );

      expect(result.isValid, isFalse);
      expect(result.warnings.any((w) => w.code == 'TOTAL_MISMATCH'), isTrue);
    });

    test('Detecta ciudadanos que votaron mayor a electores hábiles', () {
      final result = ActValidator.validate(
        registeredVoters: 200,
        votersWhoVoted: 250, // Mayor que 200
        totalVotes: 250,
        blankVotes: 0,
        nullVotes: 0,
        challengedVotes: 0,
        candidateVotes: [250],
      );

      expect(result.isValid, isFalse);
      expect(result.warnings.any((w) => w.code == 'VOTERS_EXCEED_REGISTERED'), isTrue);
    });
  });
}
