<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ElectoralList extends Model
{
    protected $fillable = [
        'jee_solicitud_id',
        'political_organization_id',
        'electoral_level_id',
        'department_code',
        'province_code',
        'district_code',
        'status'
    ];

    public function politicalOrganization()
    {
        return $this->belongsTo(PoliticalOrganization::class, 'political_organization_id');
    }

    public function electoralLevel()
    {
        return $this->belongsTo(ElectoralLevel::class, 'electoral_level_id');
    }

    public function department()
    {
        return $this->belongsTo(Department::class, 'department_code', 'code');
    }

    public function province()
    {
        return $this->belongsTo(Province::class, 'province_code', 'code');
    }

    public function district()
    {
        return $this->belongsTo(District::class, 'district_code', 'code');
    }

    public function candidacies()
    {
        return $this->hasMany(Candidacy::class, 'electoral_list_id');
    }
}
