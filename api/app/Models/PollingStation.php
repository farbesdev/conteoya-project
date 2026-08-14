<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PollingStation extends Model
{
    protected $fillable = [
        'electoral_location_id',
        'code',
        'registered_voters',
        'status',
        'odpe',
        'pdf_file',
        'pdf_page',
        'department_name',
        'province_name',
        'district_name',
    ];

    public function electoralLocation()
    {
        return $this->belongsTo(ElectoralLocation::class, 'electoral_location_id');
    }
}
