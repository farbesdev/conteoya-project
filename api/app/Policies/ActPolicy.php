<?php

namespace App\Policies;

use App\Models\Act;
use App\Models\PollingStation;
use App\Models\Role;
use App\Models\User;

class ActPolicy
{
    /**
     * Determina si el usuario puede ver el acta.
     */
    public function view(User $user, Act $act): bool
    {
        if ($user->role === Role::ADMIN || $user->role === Role::DIRECTOR) {
            return true;
        }

        if ($user->role === Role::PERSONERO) {
            $personeroId = $user->personero?->id;
            if (!$personeroId) {
                return false;
            }

            // Es el creador o tiene la mesa asignada
            return $act->captured_by_personero_id === $personeroId
                || $user->personero->pollingStations()->where('polling_stations.id', $act->polling_station_id)->exists();
        }

        return false;
    }

    /**
     * Determina si el usuario puede crear un acta para una mesa dada.
     */
    public function create(User $user, ?PollingStation $station = null): bool
    {
        if ($user->role === Role::ADMIN || $user->role === Role::DIRECTOR) {
            return true;
        }

        if ($user->role === Role::PERSONERO && $station) {
            return $user->personero?->pollingStations()
                ->where('polling_stations.id', $station->id)
                ->exists() ?? false;
        }

        return $user->role === Role::PERSONERO;
    }

    /**
     * Determina si el usuario puede confirmar el acta.
     */
    public function confirm(User $user, Act $act): bool
    {
        if ($user->role === Role::ADMIN || $user->role === Role::DIRECTOR) {
            return true;
        }

        if ($user->role === Role::PERSONERO) {
            $personeroId = $user->personero?->id;
            return $personeroId && (
                $act->captured_by_personero_id === $personeroId
                || $user->personero->pollingStations()->where('polling_stations.id', $act->polling_station_id)->exists()
            );
        }

        return false;
    }

    /**
     * Determina si el usuario puede subir evidencias para el acta.
     */
    public function upload(User $user, Act $act): bool
    {
        if ($user->role === Role::ADMIN || $user->role === Role::DIRECTOR) {
            return true;
        }

        if ($user->role === Role::PERSONERO) {
            $personeroId = $user->personero?->id;
            return $personeroId && (
                $act->captured_by_personero_id === $personeroId
                || $user->personero->pollingStations()->where('polling_stations.id', $act->polling_station_id)->exists()
            );
        }

        return false;
    }

    /**
     * Determina si el usuario puede actualizar el acta.
     */
    public function update(User $user, Act $act): bool
    {
        if ($user->role === Role::ADMIN || $user->role === Role::DIRECTOR) {
            return true;
        }

        if ($user->role === Role::PERSONERO && $act->status === 'DRAFT') {
            $personeroId = $user->personero?->id;
            return $personeroId && (
                $act->captured_by_personero_id === $personeroId
                || $user->personero->pollingStations()->where('polling_stations.id', $act->polling_station_id)->exists()
            );
        }

        return false;
    }

    /**
     * Determina si el usuario puede eliminar el acta.
     */
    public function delete(User $user, Act $act): bool
    {
        return $user->role === Role::ADMIN;
    }
}
