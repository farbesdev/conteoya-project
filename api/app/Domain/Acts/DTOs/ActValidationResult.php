<?php

namespace App\Domain\Acts\DTOs;

final class ActValidationResult
{
    /**
     * @param array<int, array{code: string, message: string, severity: string, details?: array}> $warnings
     */
    public function __construct(
        public readonly bool $isValidTotal,
        public readonly array $warnings = [],
    ) {}

    public function hasWarnings(): bool
    {
        return !empty($this->warnings);
    }

    public function toArray(): array
    {
        return [
            'is_valid_total' => $this->isValidTotal,
            'warnings'       => $this->warnings,
        ];
    }
}
