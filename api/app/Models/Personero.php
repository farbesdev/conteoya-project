<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Personero extends Model
{
    protected $fillable = [
        'user_id',
        'document_number',
        'phone_number'
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function devices()
    {
        return $this->hasMany(Device::class, 'personero_id');
    }

    public function pollingStations()
    {
        return $this->belongsToMany(PollingStation::class, 'personero_polling_station', 'personero_id', 'polling_station_id')
                    ->withPivot('assigned_at');
    }
}
