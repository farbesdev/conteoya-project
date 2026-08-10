<?php

namespace App\Domain\Acts\DTOs;

final class ActTotalsDTO
{
    public function __construct(
        public readonly int $registeredVoters,
        public readonly int $votersWhoVoted,
        public readonly int $totalVotes,
        public readonly int $blankVotes = 0,
        public readonly int $nullVotes = 0,
        public readonly int $challengedVotes = 0,
    ) {}

    public static function fromArray(array $data): self
    {
        return new self(
            registeredVoters: (int)($data['registered_voters'] ?? 0),
            votersWhoVoted:   (int)($data['voters_who_voted'] ?? 0),
            totalVotes:       (int)($data['total_votes'] ?? 0),
            blankVotes:       (int)($data['blank_votes'] ?? 0),
            nullVotes:        (int)($data['null_votes'] ?? 0),
            challengedVotes:  (int)($data['challenged_votes'] ?? 0),
        );
    }

    public function toArray(): array
    {
        return [
            'registered_voters' => $this->registeredVoters,
            'voters_who_voted'  => $this->votersWhoVoted,
            'total_votes'       => $this->totalVotes,
            'blank_votes'       => $this->blankVotes,
            'null_votes'        => $this->nullVotes,
            'challenged_votes'  => $this->challengedVotes,
        ];
    }
}
