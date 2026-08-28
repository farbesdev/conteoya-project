<?php

namespace App\Http\Requests;

use App\Models\Act;
use App\Models\Role;
use Illuminate\Foundation\Http\FormRequest;

class RecognizeActRequest extends FormRequest
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

        $act = $this->route('act');
        if ($act) {
            if (!$act instanceof Act) {
                $act = Act::find($act);
            }
            if ($act) {
                $personeroId = $user->personero?->id;
                return $personeroId && (
                    $act->captured_by_personero_id === $personeroId
                    || $user->personero->pollingStations()->where('polling_stations.id', $act->polling_station_id)->exists()
                );
            }
        }

        return $user->role === Role::PERSONERO;
    }

    public function rules(): array
    {
        return [
            'image'                => ['nullable', 'file', 'mimes:jpeg,jpg,png,webp', 'max:20480'],
            'image_url'            => ['nullable', 'string', 'url'],
            'act_evidence_id'      => ['nullable', 'integer', 'exists:act_evidence,id'],
            'polling_station_code' => ['nullable', 'string', 'exists:polling_stations,code'],
            'electoral_level_id'   => ['nullable', 'integer', 'exists:electoral_levels,id'],
            'registered_voters'    => ['nullable', 'integer', 'min:0'],
        ];
    }
}
