<?php

namespace App\Domain\Acts\DTOs;

final class ExtractionFieldConfidence
{
    public function __construct(
        public readonly string $field,
        public readonly mixed $value,
        public readonly float $confidence, // 0.0 – 1.0
        public readonly bool $requiresReview = false,
    ) {}

    public function toArray(): array
    {
        return [
            'field'           => $this->field,
            'value'           => $this->value,
            'confidence'      => round($this->confidence, 4),
            'requires_review' => $this->requiresReview || $this->confidence < 0.85,
        ];
    }
}
