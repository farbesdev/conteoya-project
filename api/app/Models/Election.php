<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Election extends Model
{
    protected $fillable = [
        'code',
        'name',
        'date',
        'status'
    ];

    public function levels()
    {
        return $this->hasMany(ElectoralLevel::class, 'election_id');
    }
}
