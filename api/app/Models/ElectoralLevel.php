<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ElectoralLevel extends Model
{
    protected $fillable = [
        'election_id',
        'code',
        'name',
        'has_preferential_vote'
    ];

    public function election()
    {
        return $this->belongsTo(Election::class, 'election_id');
    }
}
