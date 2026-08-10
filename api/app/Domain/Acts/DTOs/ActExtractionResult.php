<?php

namespace App\Domain\Acts\DTOs;

final class ActExtractionResult
{
    /**
     * @param ExtractionFieldConfidence[] $confidenceMap
     * @param array<int, array{political_organization_id: int|null, list_id: int|null, candidate_id: int|null, votes: int, confidence: float}> $results
     */
    public function __construct(
        public readonly string $providerName,
        public readonly ?string $pollingStationCode,
        public readonly ?int $registeredVoters,
        public readonly ?int $votersWhoVoted,
        public readonly ?int $totalVotes,
        public readonly ?int $blankVotes,
        public readonly ?int $nullVotes,
        public readonly ?int $challengedVotes,
        public readonly array $results,
        public readonly array $confidenceMap,
        public readonly array $rawResponse,
        public readonly string $processedAt,
    ) {}

    public function hasLowConfidenceFields(float $threshold = 0.85): bool
    {
        foreach ($this->confidenceMap as $item) {
            if ($item instanceof ExtractionFieldConfidence && $item->confidence < $threshold) {
                return true;
            }
        }
        return false;
    }

    public function toArray(): array
    {
        return [
            'provider_name'         => $this->providerName,
            'polling_station_code'  => $this->pollingStationCode,
            'registered_voters'     => $this->registeredVoters,
            'voters_who_voted'      => $this->votersWhoVoted,
            'total_votes'           => $this->totalVotes,
            'blank_votes'           => $this->blankVotes,
            'null_votes'            => $this->nullVotes,
            'challenged_votes'      => $this->challengedVotes,
            'results'               => $this->results,
            'confidence_map'        => array_map(
                fn ($c) => $c instanceof ExtractionFieldConfidence ? $c->toArray() : $c,
                $this->confidenceMap
            ),
            'has_low_confidence'    => $this->hasLowConfidenceFields(),
            'processed_at'          => $this->processedAt,
        ];
    }
}
