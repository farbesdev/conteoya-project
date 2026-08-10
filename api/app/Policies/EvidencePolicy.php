<?php

namespace App\Policies;

use App\Models\Act;
use App\Models\ActEvidence;
use App\Models\Role;
use App\Models\User;

class EvidencePolicy
{
    /**
     * Determina si el usuario puede subir evidencia para un acta.
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
     * Determina si el usuario puede ver la evidencia.
     */
    public function view(User $user, ActEvidence $evidence): bool
    {
        if ($user->role === Role::ADMIN || $user->role === Role::DIRECTOR) {
            return true;
        }

        if ($user->role === Role::PERSONERO) {
            $personeroId = $user->personero?->id;
            $act = $evidence->act;
            return $personeroId && $act && (
                $act->captured_by_personero_id === $personeroId
                || $user->personero->pollingStations()->where('polling_stations.id', $act->polling_station_id)->exists()
            );
        }

        return false;
    }
}
