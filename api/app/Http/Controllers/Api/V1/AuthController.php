<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Device;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

/**
 * @tags Autenticación
 */
class AuthController extends Controller
{
    /**
     * Iniciar sesión
     *
     * Autentica al usuario con email y contraseña mediante Laravel Sanctum.
     * Devuelve un `access_token` Bearer junto con el perfil del usuario y su rol.
     *
     * Si el usuario es **Personero** y envía `device_uuid`, se registra o actualiza
     * el dispositivo móvil en la tabla `devices`.
     *
     * @unauthenticated
     *
     * @bodyParam email    string required Email o DNI del usuario. Example: 44001122 o personero@conteoya.pe
     * @bodyParam password string required Contraseña del usuario. Example: Personero123!
     * @bodyParam device_uuid  string nullable UUID único del dispositivo móvil. Example: a1b2c3d4-e5f6-7890-abcd-ef1234567890
     * @bodyParam device_model string nullable Modelo del dispositivo.            Example: Samsung Galaxy S24
     *
     * @response 200 {
     *   "access_token": "1|XyZ...",
     *   "token_type": "Bearer",
     *   "user": {
     *     "id": 3,
     *     "name": "Juan Pérez Demo",
     *     "email": "personero@conteoya.pe",
     *     "role": "PERSONERO",
     *     "role_id": 3,
     *     "is_active": true,
     *     "rol": {
     *       "id": 3,
     *       "name": "PERSONERO",
     *       "display_name": "Personero"
     *     },
     *     "personero_id": 1
     *   }
     * }
     * @response 401 { "message": "Las credenciales proporcionadas son incorrectas." }
     * @response 403 { "message": "El usuario se encuentra inactivo." }
     * @response 422 scenario="Validación" { "message": "The email field is required.", "errors": {} }
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'email'        => 'required|string',
            'password'     => 'required',
            'device_uuid'  => 'nullable|string|max:100',
            'device_model' => 'nullable|string|max:100',
        ]);

        $identifier = trim($request->input('email', ''));

        /** @var User|null $user */
        $user = User::with(['roleModel', 'personero.pollingStations'])
            ->where(function ($q) use ($identifier) {
                $q->where('email', $identifier)
                  ->orWhereHas('personero', function ($pQ) use ($identifier) {
                      $pQ->where('document_number', $identifier);
                  });
            })
            ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Las credenciales proporcionadas son incorrectas.',
            ], 401);
        }

        if (!$user->is_active) {
            return response()->json([
                'message' => 'El usuario se encuentra inactivo.',
            ], 403);
        }

        // Registrar o actualizar dispositivo si es personero con device_uuid
        if ($user->personero && $request->filled('device_uuid')) {
            Device::updateOrCreate(
                ['device_uuid' => $request->device_uuid],
                [
                    'personero_id' => $user->personero->id,
                    'device_model' => $request->device_model,
                    'os_version'   => $request->header('User-Agent'),
                    'last_active_at' => now(),
                ]
            );
        }

        $tokenName = $request->input('device_model', 'WebApp');
        $token     = $user->createToken($tokenName)->plainTextToken;

        return response()->json([
            'access_token' => $token,
            'token_type'   => 'Bearer',
            'user'         => [
                'id'          => $user->id,
                'name'        => $user->name,
                'email'       => $user->email,
                'role'        => $user->role,
                'role_id'     => $user->role_id,
                'is_active'   => $user->is_active,
                'rol'         => $user->roleModel ? [
                    'id'           => $user->roleModel->id,
                    'name'         => $user->roleModel->name,
                    'display_name' => $user->roleModel->display_name,
                ] : null,
                'personero_id' => $user->personero?->id,
                'polling_station_code' => $user->personero?->pollingStations->first()?->code,
            ],
        ]);
    }

    /**
     * Perfil del usuario autenticado
     *
     * Devuelve el perfil completo del usuario autenticado,
     * incluyendo su rol y (si aplica) su perfil de personero.
     *
     * @response 200 {
     *   "user": {
     *     "id": 3,
     *     "name": "Juan Pérez Demo",
     *     "email": "personero@conteoya.pe",
     *     "role": "PERSONERO",
     *     "role_id": 3,
     *     "is_active": true,
     *     "rol": { "id": 3, "name": "PERSONERO", "display_name": "Personero" },
     *     "personero": { "id": 1, "document_number": "12345678", "phone_number": "+51 987 654 321" }
     *   }
     * }
     */
    public function me(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user()->load(['personero', 'roleModel']);

        return response()->json([
            'user' => array_merge($user->toArray(), [
                'rol' => $user->roleModel ? [
                    'id'           => $user->roleModel->id,
                    'name'         => $user->roleModel->name,
                    'display_name' => $user->roleModel->display_name,
                ] : null,
            ]),
        ]);
    }

    /**
     * Cerrar sesión
     *
     * Revoca el token Bearer actual del usuario autenticado.
     *
     * @response 200 { "message": "Sesión cerrada exitosamente." }
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Sesión cerrada exitosamente.',
        ]);
    }
}
