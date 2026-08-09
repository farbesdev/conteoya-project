<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Device;

class AuthController extends Controller
{
    /**
     * Autenticación de Usuario / Personero y generación de Sanctum Token.
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
            'device_uuid' => 'nullable|string',
            'device_model' => 'nullable|string',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Las credenciales proporcionadas son incorrectas.'
            ], 401);
        }

        if (!$user->is_active) {
            return response()->json([
                'message' => 'El usuario se encuentra inactivo.'
            ], 403);
        }

        // Registrar o actualizar dispositivo si es personero
        if ($user->personero && $request->filled('device_uuid')) {
            Device::updateOrCreate(
                ['device_uuid' => $request->device_uuid],
                [
                    'personero_id' => $user->personero->id,
                    'device_model' => $request->device_model,
                    'os_version' => $request->header('User-Agent'),
                    'last_active_at' => now()
                ]
            );
        }

        $tokenName = $request->input('device_model', 'MobileApp');
        $token = $user->createToken($tokenName)->plainTextToken;

        return response()->json([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'personero_id' => $user->personero?->id,
            ]
        ]);
    }

    /**
     * Obtener perfil del usuario autenticado.
     */
    public function me(Request $request)
    {
        $user = $request->user()->load('personero');

        return response()->json([
            'user' => $user
        ]);
    }

    /**
     * Cierre de sesión y revocación de tokens.
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Sesión cerrada exitosamente.'
        ]);
    }
}
