<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Personero;
use Illuminate\Http\Request;

class PersoneroAccessController extends Controller
{
    /**
     * Alternar el estado de acceso de un personero.
     * 
     * Solo los usuarios con rol ADMIN o DIRECTOR deberían poder ejecutar esto.
     * Activa o desactiva la cuenta de usuario asociada al personero.
     * 
     * @response 200 {
     *  "message": "Acceso del personero actualizado.",
     *  "is_active": true
     * }
     */
    public function toggleAccess(Request $request, Personero $personero)
    {
        $user = $personero->user;

        if (!$user) {
            return response()->json(['message' => 'El personero no tiene un usuario asociado.'], 404);
        }

        $user->is_active = !$user->is_active;
        $user->save();

        if (!$user->is_active) {
            $user->tokens()->delete();
        }

        return response()->json([
            'message' => $user->is_active
                ? 'Acceso del personero habilitado.'
                : 'Acceso del personero inhabilitado y sesiones activas revocadas.',
            'is_active' => $user->is_active,
        ]);
    }
}
