<?php

namespace App\Events;

use App\Models\Act;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class ActConfirmedEvent implements ShouldBroadcastNow
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public Act $act
    ) {}

    /**
     * Canales por los que se transmite el evento.
     * Canal público 'election-results' para actualizar el dashboard web y la app móvil en vivo.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    public function broadcastOn(): array
    {
        return [
            new Channel('election-results'),
            new Channel('election.' . $this->act->election_id),
        ];
    }

    /**
     * Nombre del evento en el cliente WebSockets.
     */
    public function broadcastAs(): string
    {
        return 'act.confirmed';
    }

    /**
     * Carga útil que se envía por WebSocket.
     */
    public function broadcastWith(): array
    {
        return [
            'act_id'             => $this->act->id,
            'act_code'           => $this->act->act_code,
            'election_id'        => $this->act->election_id,
            'electoral_level_id' => $this->act->electoral_level_id,
            'polling_station_id' => $this->act->polling_station_id,
            'polling_station'    => $this->act->pollingStation?->code,
            'department_name'    => $this->act->pollingStation?->department_name,
            'province_name'      => $this->act->pollingStation?->province_name,
            'district_name'      => $this->act->pollingStation?->district_name,
            'status'             => $this->act->status,
            'confirmed_at'       => $this->act->confirmed_at?->toIso8601String() ?? now()->toIso8601String(),
            'total_votes'        => $this->act->totals?->total_votes ?? 0,
        ];
    }
}
