<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ActTotalsResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'                => $this->id,
            'registered_voters' => $this->registered_voters,
            'voters_who_voted'  => $this->voters_who_voted,
            'total_votes'       => $this->total_votes,
            'blank_votes'       => $this->blank_votes,
            'null_votes'        => $this->null_votes,
            'challenged_votes'  => $this->challenged_votes,
            'is_valid_total'    => (bool)$this->is_valid_total,
        ];
    }
}
