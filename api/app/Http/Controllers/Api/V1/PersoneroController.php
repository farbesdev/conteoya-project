<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class PersoneroController extends Controller
{
    /**
     * Obtener mesas asignadas al personero autenticado.
     */
    public function pollingStations(Request $request)
    {
        $user = $request->user();
        $personero = $user->personero;

        if (!$personero) {
            return response()->json(['message' => 'El usuario no tiene un perfil de personero asignado.'], 403);
        }

        $stations = $personero->pollingStations()->with('electoralLocation.district')->get();

        return response()->json([
            'personero_id' => $personero->id,
            'document_number' => $personero->document_number,
            'polling_stations' => $stations
        ]);
    }
}
