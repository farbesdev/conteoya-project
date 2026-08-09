<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PoliticalOrganization extends Model
{
    protected $fillable = [
        'jee_id',
        'name',
        'short_name',
        'org_type',
        'logo_url',
        'local_logo_url'
    ];

    public function electoralLists()
    {
        return $this->hasMany(ElectoralList::class, 'political_organization_id');
    }
}
