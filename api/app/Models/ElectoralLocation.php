<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ElectoralLocation extends Model
{
    protected $fillable = [
        'district_code',
        'name',
        'address',
        'latitude',
        'longitude'
    ];

    public function district()
    {
        return $this->belongsTo(District::class, 'district_code', 'code');
    }

    public function pollingStations()
    {
        return $this->hasMany(PollingStation::class, 'electoral_location_id');
    }
}
