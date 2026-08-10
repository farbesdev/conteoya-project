<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ActResultResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'                        => $this->id,
            'political_organization_id' => $this->political_organization_id,
            'political_organization'    => $this->whenLoaded('politicalOrganization', fn () => [
                'id'         => $this->politicalOrganization->id,
                'name'       => $this->politicalOrganization->name,
                'short_name' => $this->politicalOrganization->short_name,
                'logo_url'   => $this->politicalOrganization->logo_url,
            ]),
            'electoral_list_id'         => $this->electoral_list_id,
            'candidate_id'              => $this->candidate_id,
            'candidate'                 => $this->whenLoaded('candidate', fn () => [
                'id'        => $this->candidate->id,
                'full_name' => $this->candidate->full_name,
                'photo_url' => $this->candidate->photo_url,
            ]),
            'votes'                     => $this->votes,
            'source'                    => $this->source,
            'confidence'                => $this->confidence !== null ? (float)$this->confidence : null,
        ];
    }
}
