<?php

namespace App\Infrastructure\Ocr;

use App\Contracts\ActRecognitionProviderInterface;
use App\Domain\Acts\DTOs\ActExtractionResult;
use App\Domain\Acts\DTOs\ExtractionFieldConfidence;

class MockActRecognitionProvider implements ActRecognitionProviderInterface
{
    protected ?ActExtractionResult $customResult = null;

    public function setMockResult(ActExtractionResult $result): void
    {
        $this->customResult = $result;
    }

    public function extract(string $imagePath, string $mimeType = 'image/jpeg', array $context = []): ActExtractionResult
    {
        if ($this->customResult !== null) {
            return $this->customResult;
        }

        $pollingStationCode = $context['polling_station_code'] ?? '030390';
        $registeredVoters   = (int)($context['registered_voters'] ?? 300);
        $votersWhoVoted     = (int)($context['voters_who_voted'] ?? min($registeredVoters, max(10, (int)($registeredVoters * 0.88))));

        $blankVotes      = 1;
        $nullVotes       = 4;
        $challengedVotes = 0;
        $validVotes      = max(0, $votersWhoVoted - ($blankVotes + $nullVotes + $challengedVotes));

        $results = [];
        if (!empty($context['organizations'])) {
            $numOrgs = count($context['organizations']);
            $weights = array_map(fn($i) => 1.0 + (sin(($i + 1) * 1.3) + 1.0) * 1.5, range(0, $numOrgs - 1));
            $sumWeights = array_sum($weights) ?: 1;
            $votesList = [];
            foreach ($weights as $w) {
                $votesList[] = (int)(($w / $sumWeights) * $validVotes);
            }
            $diff = $validVotes - array_sum($votesList);
            for ($k = 0; $k < abs($diff); $k++) {
                $idx = $k % $numOrgs;
                if ($diff > 0) {
                    $votesList[$idx]++;
                } elseif ($votesList[$idx] > 0) {
                    $votesList[$idx]--;
                }
            }

            foreach ($context['organizations'] as $idx => $org) {
                $orgId = $org['id'] ?? ($idx + 1);
                $orgName = $org['name'] ?? ("Organización " . ($idx + 1));
                $orgVotes = $votesList[$idx] ?? 0;
                $conf = ($idx === 1 && $numOrgs > 2) ? 0.82 : round(0.90 + (($idx % 4) * 0.02), 2);
                $results[] = [
                    'political_organization_id'   => $orgId,
                    'political_organization_name' => $orgName,
                    'electoral_list_id'           => $org['electoral_list_id'] ?? null,
                    'candidate_id'                => null,
                    'votes'                       => $orgVotes,
                    'confidence'                  => $conf,
                ];
            }
        } else {
            $results = [
                ['political_organization_id' => 1, 'political_organization_name' => 'Organización 1', 'electoral_list_id' => 1, 'candidate_id' => null, 'votes' => (int)($validVotes * 0.5), 'confidence' => 0.98],
                ['political_organization_id' => 2, 'political_organization_name' => 'Organización 2', 'electoral_list_id' => 2, 'candidate_id' => null, 'votes' => (int)($validVotes * 0.35), 'confidence' => 0.94],
                ['political_organization_id' => 3, 'political_organization_name' => 'Organización 3', 'electoral_list_id' => 3, 'candidate_id' => null, 'votes' => max(0, $validVotes - (int)($validVotes * 0.85)), 'confidence' => 0.78],
            ];
        }

        $sumResults = array_sum(array_column($results, 'votes'));
        $totalVotes = $sumResults + $blankVotes + $nullVotes + $challengedVotes;

        $confidenceMap = [
            new ExtractionFieldConfidence('electores_habiles', $registeredVoters, 0.98),
            new ExtractionFieldConfidence('votantes', $votersWhoVoted, 0.95),
            new ExtractionFieldConfidence('total_votos', $totalVotes, 0.96),
            new ExtractionFieldConfidence('votos_blancos', $blankVotes, 0.90),
            new ExtractionFieldConfidence('votos_nulos', $nullVotes, 0.88),
            new ExtractionFieldConfidence('votos_impugnados', $challengedVotes, 0.99),
        ];

        foreach ($results as $idx => $r) {
            $name = $r['political_organization_name'] ?? ('partido_' . ($idx + 1) . '_votos');
            $confidenceMap[] = new ExtractionFieldConfidence($name, $r['votes'], $r['confidence'], $r['confidence'] < 0.85);
        }

        return new ActExtractionResult(
            providerName: $this->getName(),
            pollingStationCode: $pollingStationCode,
            registeredVoters: $registeredVoters,
            votersWhoVoted: $votersWhoVoted,
            totalVotes: $totalVotes,
            blankVotes: $blankVotes,
            nullVotes: $nullVotes,
            challengedVotes: $challengedVotes,
            results: $results,
            confidenceMap: $confidenceMap,
            rawResponse: [
                'status' => 'success',
                'engine' => 'mock_ocr_ia_engine_v1',
                'bounding_boxes' => [],
            ],
            processedAt: now()->toIso8601String()
        );
    }

    public function getName(): string
    {
        return 'MOCK_OCR_AI';
    }
}
