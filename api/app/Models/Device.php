<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Device extends Model
{
    protected $fillable = [
        'personero_id',
        'device_uuid',
        'device_model',
        'os_version',
        'app_version',
        'last_active_at'
    ];

    public function personero()
    {
        return $this->belongsTo(Personero::class, 'personero_id');
    }
}
