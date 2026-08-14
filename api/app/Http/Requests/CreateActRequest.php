<?php

namespace App\Http\Requests;

use App\Models\PollingStation;
use App\Models\Role;
use Illuminate\Foundation\Http\FormRequest;

class CreateActRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        $user = $this->user();
        if (!$user) {
            return false;
        }

        if ($user->role === Role::ADMIN || $user->role === Role::DIRECTOR) {
            return true;
        }

        if ($user->role === Role::PERSONERO) {
            $stationCode = $this->input('polling_station_code');
            $stationId = $this->input('polling_station_id');
            return $user->personero?->pollingStations()
                ->where(function ($q) use ($stationCode, $stationId) {
                    if ($stationId) {
                        $q->where('polling_stations.id', $stationId);
                    }
                    if ($stationCode) {
                        $q->orWhere('polling_stations.code', $stationCode);
                    }
                })
                ->exists() ?? false;
        }

        return false;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'client_operation_id'                 => ['nullable', 'uuid'],
            'polling_station_id'                  => ['required_without:polling_station_code', 'nullable', 'integer', 'exists:polling_stations,id'],
            'polling_station_code'                => ['required_without:polling_station_id', 'nullable', 'string', 'exists:polling_stations,code'],
            'election_id'                         => ['required', 'integer', 'exists:elections,id'],
            'electoral_level_id'                  => ['required', 'integer', 'exists:electoral_levels,id'],
            'act_code'                            => ['nullable', 'string', 'max:20'],
            'status'                              => ['nullable', 'string', 'in:DRAFT,CONFIRMED,SYNCED'],
            'totals'                              => ['required', 'array'],
            'totals.registered_voters'            => ['required', 'integer', 'min:0'],
            'totals.voters_who_voted'             => ['required', 'integer', 'min:0'],
            'totals.total_votes'                  => ['required', 'integer', 'min:0'],
            'totals.blank_votes'                  => ['nullable', 'integer', 'min:0'],
            'totals.null_votes'                   => ['nullable', 'integer', 'min:0'],
            'totals.challenged_votes'             => ['nullable', 'integer', 'min:0'],
            'results'                             => ['required', 'array'],
            'results.*.political_organization_id' => ['nullable', 'integer', 'exists:political_organizations,id'],
            'results.*.electoral_list_id'         => ['nullable', 'integer', 'exists:electoral_lists,id'],
            'results.*.candidate_id'              => ['nullable', 'integer', 'exists:candidates,id'],
            'results.*.votes'                     => ['required', 'integer', 'min:0'],
            'results.*.source'                    => ['nullable', 'string', 'in:MANUAL,OCR,AI'],
            'results.*.confidence'                => ['nullable', 'numeric', 'min:0', 'max:1'],
        ];
    }

    public function messages(): array
    {
        return [
            'polling_station_code.exists' => 'La mesa de votación especificada no existe.',
            'election_id.exists'          => 'El proceso electoral no existe.',
            'electoral_level_id.exists'   => 'El nivel electoral no existe.',
        ];
    }
}
