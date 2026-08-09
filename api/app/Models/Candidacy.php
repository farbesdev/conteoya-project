<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Candidacy extends Model
{
    protected $fillable = [
        'electoral_list_id',
        'candidate_id',
        'position',
        'list_number',
        'status'
    ];

    public function electoralList()
    {
        return $this->belongsTo(ElectoralList::class, 'electoral_list_id');
    }

    public function candidate()
    {
        return $this->belongsTo(Candidate::class, 'candidate_id');
    }
}
