<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'role_id',
        'is_active',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password'          => 'hashed',
            'is_active'         => 'boolean',
        ];
    }

    /**
     * Rol del usuario (relación con tabla roles).
     */
    public function roleModel(): BelongsTo
    {
        return $this->belongsTo(Role::class, 'role_id');
    }

    /**
     * Perfil de Personero asociado al usuario.
     */
    public function personero(): HasOne
    {
        return $this->hasOne(Personero::class, 'user_id');
    }

    /**
     * Verifica si el usuario tiene un rol específico.
     */
    public function hasRole(string $roleName): bool
    {
        return $this->role === $roleName;
    }

    public function isAdmin(): bool
    {
        return $this->role === Role::ADMIN || $this->role === 'ADMIN';
    }

    public function isDirector(): bool
    {
        return $this->role === Role::DIRECTOR || $this->role === 'DIRECTOR';
    }

    public function isPersonero(): bool
    {
        return $this->role === Role::PERSONERO || $this->role === 'PERSONERO';
    }
}
