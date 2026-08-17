class ActWarning {
  final String code;
  final String message;
  final String severity;

  const ActWarning({
    required this.code,
    required this.message,
    this.severity = 'WARNING',
  });
}

class ActValidationResult {
  final bool isValid;
  final List<ActWarning> warnings;

  const ActValidationResult({
    required this.isValid,
    required this.warnings,
  });
}

class ActValidator {
  static ActValidationResult validate({
    required int registeredVoters,
    required int votersWhoVoted,
    required int totalVotes,
    required int blankVotes,
    required int nullVotes,
    required int challengedVotes,
    required List<int> candidateVotes,
  }) {
    final warnings = <ActWarning>[];

    // 1. Suma de votos por lista + blancos + nulos + impugnados == total emitido
    final sumCandidates = candidateVotes.fold<int>(0, (prev, elem) => prev + elem);
    final expectedTotal = sumCandidates + blankVotes + nullVotes + challengedVotes;

    if (expectedTotal != totalVotes) {
      warnings.add(ActWarning(
        code: 'TOTAL_MISMATCH',
        message: 'La suma de votos ($expectedTotal) difiere del total emitido declarado ($totalVotes).',
      ));
    }

    // 2. Ciudadanos que votaron <= Electores hábiles
    if (votersWhoVoted > registeredVoters) {
      warnings.add(ActWarning(
        code: 'VOTERS_EXCEED_REGISTERED',
        message: 'Los ciudadanos que votaron ($votersWhoVoted) superan los electores hábiles ($registeredVoters).',
      ));
    }

    // 3. Total de votos emitidos <= Electores hábiles
    if (totalVotes > registeredVoters) {
      warnings.add(ActWarning(
        code: 'VOTES_EXCEED_REGISTERED',
        message: 'El total de votos ($totalVotes) supera los electores hábiles ($registeredVoters).',
      ));
    }

    // 4. Total de votos emitidos > Ciudadanos que votaron
    if (totalVotes > votersWhoVoted) {
      warnings.add(ActWarning(
        code: 'VOTES_EXCEED_ATTENDANCE',
        message: 'El total de votos emitidos ($totalVotes) es mayor a los ciudadanos que votaron ($votersWhoVoted).',
      ));
    }

    return ActValidationResult(
      isValid: warnings.isEmpty,
      warnings: warnings,
    );
  }

  static ActValidationResult validateMunicipal({
    required int registeredVoters,
    required int votersWhoVoted,
    required int provTotalVotes,
    required int provBlankVotes,
    required int provNullVotes,
    required int provChallengedVotes,
    required List<int> provCandidateVotes,
    required int distTotalVotes,
    required int distBlankVotes,
    required int distNullVotes,
    required int distChallengedVotes,
    required List<int> distCandidateVotes,
  }) {
    final warnings = <ActWarning>[];

    // 1. Verificación Total Provincial
    final sumProvCandidates = provCandidateVotes.fold<int>(0, (prev, elem) => prev + elem);
    final expectedProvTotal = sumProvCandidates + provBlankVotes + provNullVotes + provChallengedVotes;
    if (expectedProvTotal != provTotalVotes) {
      warnings.add(ActWarning(
        code: 'PROV_TOTAL_MISMATCH',
        message: 'Provincial: La suma de votos ($expectedProvTotal) difiere del total emitido declarado ($provTotalVotes).',
      ));
    }

    // 2. Verificación Total Distrital
    final sumDistCandidates = distCandidateVotes.fold<int>(0, (prev, elem) => prev + elem);
    final expectedDistTotal = sumDistCandidates + distBlankVotes + distNullVotes + distChallengedVotes;
    if (expectedDistTotal != distTotalVotes) {
      warnings.add(ActWarning(
        code: 'DIST_TOTAL_MISMATCH',
        message: 'Distrital: La suma de votos ($expectedDistTotal) difiere del total emitido declarado ($distTotalVotes).',
      ));
    }

    // 3. Asistencia vs Electores Hábiles
    if (votersWhoVoted > registeredVoters) {
      warnings.add(ActWarning(
        code: 'VOTERS_EXCEED_REGISTERED',
        message: 'Los ciudadanos que votaron ($votersWhoVoted) superan los electores hábiles ($registeredVoters).',
      ));
    }

    if (provTotalVotes > registeredVoters) {
      warnings.add(ActWarning(
        code: 'PROV_VOTES_EXCEED_REGISTERED',
        message: 'El total de votos provincial ($provTotalVotes) supera los electores hábiles ($registeredVoters).',
      ));
    }

    if (distTotalVotes > registeredVoters) {
      warnings.add(ActWarning(
        code: 'DIST_VOTES_EXCEED_REGISTERED',
        message: 'El total de votos distrital ($distTotalVotes) supera los electores hábiles ($registeredVoters).',
      ));
    }

    return ActValidationResult(
      isValid: warnings.isEmpty,
      warnings: warnings,
    );
  }
}
