<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Election extends Model
{
    protected $fillable = [
        'code',
        'name',
        'date',
        'status',
        'jee_proceso_electoral_id',
    ];

    public function levels()
    {
        return $this->hasMany(ElectoralLevel::class, 'election_id');
    }

    public function personeros()
    {
        return $this->hasMany(Personero::class, 'election_id');
    }
}
