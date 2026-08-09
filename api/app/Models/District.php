<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class District extends Model
{
    protected $primaryKey = 'code';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = ['code', 'province_code', 'department_code', 'name'];

    public function province()
    {
        return $this->belongsTo(Province::class, 'province_code', 'code');
    }

    public function department()
    {
        return $this->belongsTo(Department::class, 'department_code', 'code');
    }
}
