<?php

namespace App\Domain\Acts;

use App\Domain\Acts\DTOs\ActTotalsDTO;
use App\Domain\Acts\DTOs\ActValidationResult;

class ActValidationService
{
    /**
     * Valida la coherencia de los totales y resultados del acta.
     * Retorna warnings estructurados sin bloquear el registro.
     *
     * @param ActTotalsDTO $totals
     * @param array $results Array de resultados de listas / candidatos
     * @return ActValidationResult
     */
    public function validate(ActTotalsDTO $totals, array $results): ActValidationResult
    {
        $warnings = [];

        // 1. Suma de votos de organizaciones + blancos + nulos + impugnados == total_votes
        $sumResults = 0;
        foreach ($results as $res) {
            $sumResults += (int)($res['votes'] ?? 0);
        }

        $expectedTotal = $sumResults + $totals->blankVotes + $totals->nullVotes + $totals->challengedVotes;

        if ($expectedTotal !== $totals->totalVotes) {
            $warnings[] = [
                'code'     => 'TOTAL_MISMATCH',
                'severity' => 'WARNING',
                'message'  => "La suma de votos ({$expectedTotal}) no coincide con el total de votos emitidos declarado ({$totals->totalVotes}).",
                'details'  => [
                    'sum_results'      => $sumResults,
                    'blank_votes'      => $totals->blankVotes,
                    'null_votes'       => $totals->nullVotes,
                    'challenged_votes' => $totals->challengedVotes,
                    'expected_total'   => $expectedTotal,
                    'declared_total'   => $totals->totalVotes,
                    'difference'       => $expectedTotal - $totals->totalVotes,
                ],
            ];
        }

        // 2. Ciudadanos que votaron <= Electores hábiles
        if ($totals->votersWhoVoted > $totals->registeredVoters) {
            $warnings[] = [
                'code'     => 'VOTERS_EXCEED_REGISTERED',
                'severity' => 'WARNING',
                'message'  => "El número de ciudadanos que votaron ({$totals->votersWhoVoted}) supera a los electores hábiles ({$totals->registeredVoters}).",
                'details'  => [
                    'voters_who_voted'  => $totals->votersWhoVoted,
                    'registered_voters' => $totals->registeredVoters,
                ],
            ];
        }

        // 3. Total de votos emitidos <= Electores hábiles
        if ($totals->totalVotes > $totals->registeredVoters) {
            $warnings[] = [
                'code'     => 'VOTES_EXCEED_REGISTERED',
                'severity' => 'WARNING',
                'message'  => "El total de votos emitidos ({$totals->totalVotes}) supera a los electores hábiles ({$totals->registeredVoters}).",
                'details'  => [
                    'total_votes'       => $totals->totalVotes,
                    'registered_voters' => $totals->registeredVoters,
                ],
            ];
        }

        // 4. Total de votos emitidos > Ciudadanos que votaron
        if ($totals->totalVotes > $totals->votersWhoVoted) {
            $warnings[] = [
                'code'     => 'VOTES_EXCEED_ATTENDANCE',
                'severity' => 'WARNING',
                'message'  => "El total de votos emitidos ({$totals->totalVotes}) es mayor que los ciudadanos que votaron ({$totals->votersWhoVoted}).",
                'details'  => [
                    'total_votes'      => $totals->totalVotes,
                    'voters_who_voted' => $totals->votersWhoVoted,
                ],
            ];
        }

        return new ActValidationResult(
            isValidTotal: empty($warnings),
            warnings: $warnings
        );
    }
}
