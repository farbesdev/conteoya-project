<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ActResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'                  => $this->id,
            'act_code'            => $this->act_code,
            'status'              => $this->status,
            'election_id'         => $this->election_id,
            'electoral_level_id'  => $this->electoral_level_id,
            'polling_station_id'  => $this->polling_station_id,
            'polling_station'     => $this->whenLoaded('pollingStation', fn () => [
                'id'                => $this->pollingStation->id,
                'code'              => $this->pollingStation->code,
                'registered_voters' => $this->pollingStation->registered_voters,
            ]),
            'captured_by'         => $this->whenLoaded('capturedByPersonero', fn () => [
                'id'              => $this->capturedByPersonero->id,
                'document_number' => $this->capturedByPersonero->document_number,
                'name'            => $this->capturedByPersonero->user?->name,
            ]),
            'captured_at'         => is_string($this->captured_at) ? $this->captured_at : $this->captured_at?->toIso8601String(),
            'confirmed_at'        => is_string($this->confirmed_at) ? $this->confirmed_at : $this->confirmed_at?->toIso8601String(),
            'totals'              => new ActTotalsResource($this->whenLoaded('totals')),
            'results'             => ActResultResource::collection($this->whenLoaded('results')),
            'evidences'           => ActEvidenceResource::collection($this->whenLoaded('evidences')),
            'evidence_count'      => $this->when($this->relationLoaded('evidences'), fn () => $this->evidences->count()),
            'has_ai_source'       => $this->when($this->relationLoaded('results'), fn () => $this->results->contains('source', 'AI') || $this->results->contains('source', 'OCR')),
            'created_at'          => is_string($this->created_at) ? $this->created_at : $this->created_at?->toIso8601String(),
            'updated_at'          => is_string($this->updated_at) ? $this->updated_at : $this->updated_at?->toIso8601String(),
        ];
    }
}
