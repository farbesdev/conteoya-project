<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Personero extends Model
{
    protected $fillable = [
        'user_id',
        'election_id',
        'political_organization_id',
        'document_number',
        'full_name',
        'first_name',
        'email',
        'personero_type',
        'id_tipo_personero',
        'phone_number',
        'status',
        'expediente_ext',
        'codigo_declara',
        'jee_personero_declara_id',
        'political_organization_name',
        'jee_name',
        'jee_id',
        'department_name',
        'province_name',
        'district_name',
        'abogado_responsable',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function election()
    {
        return $this->belongsTo(Election::class, 'election_id');
    }

    public function politicalOrganization()
    {
        return $this->belongsTo(PoliticalOrganization::class, 'political_organization_id');
    }

    public function devices()
    {
        return $this->hasMany(Device::class, 'personero_id');
    }

    public function pollingStations()
    {
        return $this->belongsToMany(PollingStation::class, 'personero_polling_station', 'personero_id', 'polling_station_id')
                    ->withPivot('assigned_at');
    }
}
