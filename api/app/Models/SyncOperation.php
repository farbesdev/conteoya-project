<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SyncOperation extends Model
{
    protected $fillable = [
        'client_operation_id',
        'device_id',
        'personero_id',
        'entity_type',
        'entity_id',
        'operation',
        'payload',
        'attempts',
        'status',
        'last_error',
        'processed_at'
    ];

    protected $casts = [
        'payload' => 'array',
        'processed_at' => 'datetime',
    ];

    public function device()
    {
        return $this->belongsTo(Device::class, 'device_id');
    }

    public function personero()
    {
        return $this->belongsTo(Personero::class, 'personero_id');
    }
}
