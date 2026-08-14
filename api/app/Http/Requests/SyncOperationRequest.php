<?php

namespace App\Http\Requests;

use App\Models\Role;
use Illuminate\Foundation\Http\FormRequest;

class SyncOperationRequest extends FormRequest
{
    public function authorize(): bool
    {
        $user = $this->user();
        return $user !== null && (
            $user->role === Role::PERSONERO || $user->role === Role::ADMIN || $user->role === Role::DIRECTOR
        );
    }

    public function rules(): array
    {
        return [
            'operations'                          => ['required', 'array', 'min:1'],
            'operations.*.client_operation_id'    => ['required', 'string'],
            'operations.*.entity_type'            => ['required', 'string', 'in:acts,act_evidence,personeros,users,polling_stations'],
            'operations.*.entity_id'              => ['required'],
            'operations.*.operation'              => ['required', 'string', 'in:CREATE,UPDATE,DELETE,CONFIRM'],
            'operations.*.payload'                => ['required', 'array'],
            'operations.*.checksum'               => ['nullable', 'string'],
            'device_uuid'                         => ['nullable', 'string'],
        ];
    }
}
