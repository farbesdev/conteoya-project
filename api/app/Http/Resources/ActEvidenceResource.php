<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ActEvidenceResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id'               => $this->id,
            'act_id'           => $this->act_id,
            'storage_provider' => $this->storage_provider,
            'object_key'       => $this->object_key,
            'file_mime'        => $this->file_mime,
            'file_size_bytes'  => $this->file_size_bytes,
            'sha256_hash'      => $this->sha256_hash,
            'width_px'         => $this->width_px,
            'height_px'        => $this->height_px,
            'captured_at'      => $this->captured_at?->toIso8601String(),
            'created_at'       => $this->created_at?->toIso8601String(),
        ];
    }
}
