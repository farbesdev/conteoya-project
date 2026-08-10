<?php

namespace App\Http\Requests;

use App\Models\Act;
use App\Models\Role;
use Illuminate\Foundation\Http\FormRequest;

class ConfirmEvidenceRequest extends FormRequest
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
            'object_key'      => ['required', 'string'],
            'sha256_hash'     => ['required', 'string', 'size:64'],
            'file_mime'       => ['required', 'string', 'in:image/jpeg,image/png,image/webp'],
            'file_size_bytes' => ['required', 'integer', 'min:1', 'max:20971520'],
            'device_id'       => ['nullable', 'integer', 'exists:devices,id'],
            'width_px'        => ['nullable', 'integer', 'min:1'],
            'height_px'       => ['nullable', 'integer', 'min:1'],
            'captured_at'     => ['nullable', 'date'],
        ];
    }
}
