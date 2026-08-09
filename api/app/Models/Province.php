<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Province extends Model
{
    protected $primaryKey = 'code';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = ['code', 'department_code', 'name'];

    public function department()
    {
        return $this->belongsTo(Department::class, 'department_code', 'code');
    }

    public function districts()
    {
        return $this->hasMany(District::class, 'province_code', 'code');
    }
}
