<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Act extends Model
{
    protected $fillable = [
        'election_id',
        'electoral_level_id',
        'polling_station_id',
        'act_code',
        'status',
        'captured_by_personero_id',
        'captured_at',
        'confirmed_at'
    ];

    public function election()
    {
        return $this->belongsTo(Election::class, 'election_id');
    }

    public function electoralLevel()
    {
        return $this->belongsTo(ElectoralLevel::class, 'electoral_level_id');
    }

    public function pollingStation()
    {
        return $this->belongsTo(PollingStation::class, 'polling_station_id');
    }

    public function capturedByPersonero()
    {
        return $this->belongsTo(Personero::class, 'captured_by_personero_id');
    }

    public function totals()
    {
        return $this->hasOne(ActTotal::class, 'act_id');
    }

    public function results()
    {
        return $this->hasMany(ActResult::class, 'act_id');
    }

    public function evidences()
    {
        return $this->hasMany(ActEvidence::class, 'act_id');
    }
}
