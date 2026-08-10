<?php

namespace App\Http\Requests;

use App\Models\Act;
use App\Models\Role;
use Illuminate\Foundation\Http\FormRequest;

class ConfirmActRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        if (!$user) {
            return false;
        }

        if ($user->role === Role::ADMIN || $user->role === Role::DIRECTOR) {
            return true;
        }

        /** @var Act $act */
        $act = $this->route('act');
        if (!$act instanceof Act) {
            $act = Act::find($act);
        }

        if (!$act) {
            return false;
        }

        $personeroId = $user->personero?->id;
        return $personeroId && (
            $act->captured_by_personero_id === $personeroId
            || $user->personero->pollingStations()->where('polling_stations.id', $act->polling_station_id)->exists()
        );
    }

    public function rules(): array
    {
        return [
            'client_operation_id' => ['nullable', 'uuid'],
        ];
    }
}
