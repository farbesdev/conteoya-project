<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ActTotal extends Model
{
    protected $fillable = [
        'act_id',
        'registered_voters',
        'voters_who_voted',
        'total_votes',
        'blank_votes',
        'null_votes',
        'challenged_votes',
        'is_valid_total'
    ];

    public function act()
    {
        return $this->belongsTo(Act::class, 'act_id');
    }
}
