<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Role extends Model
{
    // Roles del sistema ConteoYA
    const ADMIN     = 'ADMIN';
    const DIRECTOR  = 'DIRECTOR';
    const PERSONERO = 'PERSONERO';

    protected $fillable = [
        'id',
        'name',
        'display_name',
        'description',
    ];

    /**
     * Usuarios con este rol.
     */
    public function users(): HasMany
    {
        return $this->hasMany(User::class, 'role_id');
    }
}
