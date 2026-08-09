<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ActResult extends Model
{
    protected $fillable = [
        'act_id',
        'political_organization_id',
        'electoral_list_id',
        'candidate_id',
        'votes',
        'source',
        'confidence'
    ];

    public function act()
    {
        return $this->belongsTo(Act::class, 'act_id');
    }

    public function politicalOrganization()
    {
        return $this->belongsTo(PoliticalOrganization::class, 'political_organization_id');
    }

    public function electoralList()
    {
        return $this->belongsTo(ElectoralList::class, 'electoral_list_id');
    }

    public function candidate()
    {
        return $this->belongsTo(Candidate::class, 'candidate_id');
    }
}
