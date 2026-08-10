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
        $registeredVoters   = $context['registered_voters'] ?? 300;
        $votersWhoVoted     = $context['voters_who_voted'] ?? 280;

        $results = [];
        if (!empty($context['organizations'])) {
            foreach ($context['organizations'] as $idx => $org) {
                $results[] = [
                    'political_organization_id' => $org['id'] ?? ($idx + 1),
                    'electoral_list_id'         => $org['electoral_list_id'] ?? null,
                    'candidate_id'              => null,
                    'votes'                     => 80 + ($idx * 15),
                    'confidence'                => 0.96,
                ];
            }
        } else {
            $results = [
                ['political_organization_id' => 1, 'electoral_list_id' => 1, 'candidate_id' => null, 'votes' => 120, 'confidence' => 0.98],
                ['political_organization_id' => 2, 'electoral_list_id' => 2, 'candidate_id' => null, 'votes' => 95, 'confidence' => 0.94],
                ['political_organization_id' => 3, 'electoral_list_id' => 3, 'candidate_id' => null, 'votes' => 45, 'confidence' => 0.78], // Baja confianza de ejemplo (< 0.85)
            ];
        }

        $blankVotes      = 10;
        $nullVotes       = 8;
        $challengedVotes = 2;
        $sumResults      = array_sum(array_column($results, 'votes'));
        $totalVotes      = $sumResults + $blankVotes + $nullVotes + $challengedVotes;

        $confidenceMap = [
            new ExtractionFieldConfidence('polling_station_code', $pollingStationCode, 0.99),
            new ExtractionFieldConfidence('registered_voters', $registeredVoters, 0.99),
            new ExtractionFieldConfidence('voters_who_voted', $votersWhoVoted, 0.95),
            new ExtractionFieldConfidence('blank_votes', $blankVotes, 0.92),
            new ExtractionFieldConfidence('null_votes', $nullVotes, 0.88),
            new ExtractionFieldConfidence('challenged_votes', $challengedVotes, 0.75, true), // Baja confianza
            new ExtractionFieldConfidence('total_votes', $totalVotes, 0.96),
        ];

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
