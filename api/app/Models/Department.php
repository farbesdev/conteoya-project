<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Department extends Model
{
    protected $primaryKey = 'code';
    public $incrementing = false;
    protected $keyType = 'string';

    protected $fillable = ['code', 'name'];

    public function provinces()
    {
        return $this->hasMany(Province::class, 'department_code', 'code');
    }
}
