<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SyncOperationResource extends JsonResource
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
            'client_operation_id' => $this->client_operation_id,
            'entity_type'         => $this->entity_type,
            'entity_id'           => $this->entity_id,
            'operation'           => $this->operation,
            'status'              => $this->status,
            'attempts'            => $this->attempts,
            'last_error'          => $this->last_error,
            'processed_at'        => $this->processed_at?->toIso8601String(),
            'created_at'          => $this->created_at?->toIso8601String(),
        ];
    }
}
