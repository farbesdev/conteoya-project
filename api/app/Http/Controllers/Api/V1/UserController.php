<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Role;
use App\Models\Personero;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    /**
     * Listar todos los usuarios (solo ADMIN y DIRECTOR).
     */
    public function index(Request $request)
    {
        $currentUser = $request->user();
        if (!$currentUser->isAdmin() && !$currentUser->isDirector()) {
            return response()->json(['message' => 'No autorizado para gestionar usuarios.'], 403);
        }

        $query = User::with(['roleModel', 'personero.pollingStations']);

        if ($request->has('role') && !empty($request->role)) {
            $query->where('role', strtoupper($request->role));
        }

        if ($request->has('search') && !empty($request->search)) {
            $search = trim($request->search);
            $query->where(function ($q) use ($search) {
                $q->whereAnyInsensitive(['name', 'email'], $search)
                  ->orWhereHas('personero', function ($p) use ($search) {
                      $p->where('document_number', 'LIKE', "%{$search}%")
                        ->orWhereAnyInsensitive(['full_name', 'first_name', 'email'], $search);
                  });
            });
        }

        $users = $query->orderBy('id', 'desc')->paginate(20);

        return response()->json($users);
    }

    /**
     * Crear nuevo usuario (solo ADMIN y DIRECTOR).
     */
    public function store(Request $request)
    {
        $currentUser = $request->user();
        if (!$currentUser->isAdmin() && !$currentUser->isDirector()) {
            return response()->json(['message' => 'No autorizado para crear usuarios.'], 403);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:100',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'role' => 'required|string|in:ADMIN,DIRECTOR,PERSONERO',
            'document_number' => 'nullable|string|max:15',
            'phone_number' => 'nullable|string|max:20',
            'polling_station_id' => 'nullable|exists:polling_stations,id',
        ]);

        $user = DB::transaction(function () use ($validated) {
            $roleModel = Role::where('name', $validated['role'])->first();

            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => Hash::make($validated['password']),
                'role' => $validated['role'],
                'role_id' => $roleModel ? $roleModel->id : 3,
                'is_active' => true,
            ]);

            if ($validated['role'] === 'PERSONERO' || !empty($validated['document_number'])) {
                $personero = Personero::create([
                    'user_id' => $user->id,
                    'document_number' => $validated['document_number'] ?? ('DNI' . str_pad((string)$user->id, 6, '0', STR_PAD_LEFT)),
                    'phone_number' => $validated['phone_number'] ?? null,
                ]);

                if (!empty($validated['polling_station_id'])) {
                    $personero->pollingStations()->sync([$validated['polling_station_id']]);
                }
            }

            return $user;
        });

        return response()->json($user->load(['roleModel', 'personero.pollingStations']), 211);
    }

    /**
     * Ver usuario específico.
     */
    public function show(Request $request, $id)
    {
        $currentUser = $request->user();
        if (!$currentUser->isAdmin() && !$currentUser->isDirector() && $currentUser->id != $id) {
            return response()->json(['message' => 'No autorizado.'], 403);
        }

        $user = User::with(['roleModel', 'personero.pollingStations.electoralLocation'])->findOrFail($id);

        return response()->json($user);
    }

    /**
     * Actualizar usuario.
     */
    public function update(Request $request, $id)
    {
        $currentUser = $request->user();
        if (!$currentUser->isAdmin() && !$currentUser->isDirector()) {
            return response()->json(['message' => 'No autorizado.'], 403);
        }

        $user = User::findOrFail($id);

        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:100',
            'email' => ['sometimes', 'required', 'email', Rule::unique('users', 'email')->ignore($user->id)],
            'password' => 'nullable|string|min:6',
            'role' => 'sometimes|required|string|in:ADMIN,DIRECTOR,PERSONERO',
            'is_active' => 'sometimes|boolean',
            'document_number' => 'nullable|string|max:15',
            'phone_number' => 'nullable|string|max:20',
            'polling_station_id' => 'nullable|exists:polling_stations,id',
        ]);

        DB::transaction(function () use ($user, $validated) {
            if (isset($validated['name'])) $user->name = $validated['name'];
            if (isset($validated['email'])) $user->email = $validated['email'];
            if (!empty($validated['password'])) $user->password = Hash::make($validated['password']);
            if (isset($validated['is_active'])) $user->is_active = $validated['is_active'];

            if (isset($validated['role'])) {
                $user->role = $validated['role'];
                $roleModel = Role::where('name', $validated['role'])->first();
                if ($roleModel) $user->role_id = $roleModel->id;
            }

            $user->save();

            if ($user->role === 'PERSONERO' || isset($validated['document_number'])) {
                $personero = $user->personero ?: new Personero(['user_id' => $user->id]);
                if (isset($validated['document_number'])) {
                    $personero->document_number = $validated['document_number'];
                }
                if (isset($validated['phone_number'])) {
                    $personero->phone_number = $validated['phone_number'];
                }
                $personero->save();

                if (array_key_exists('polling_station_id', $validated)) {
                    if ($validated['polling_station_id']) {
                        $personero->pollingStations()->sync([$validated['polling_station_id']]);
                    } else {
                        $personero->pollingStations()->detach();
                    }
                }
            }
        });

        return response()->json($user->fresh()->load(['roleModel', 'personero.pollingStations']));
    }

    /**
     * Eliminar usuario (solo ADMIN).
     */
    public function destroy(Request $request, $id)
    {
        $currentUser = $request->user();
        if (!$currentUser->isAdmin()) {
            return response()->json(['message' => 'Solo administradores pueden eliminar usuarios.'], 403);
        }

        if ($currentUser->id == $id) {
            return response()->json(['message' => 'No puede eliminarse a sí mismo.'], 422);
        }

        $user = User::findOrFail($id);

        DB::transaction(function () use ($user) {
            if ($user->personero) {
                $user->personero->pollingStations()->detach();
                $user->personero->delete();
            }
            $user->delete();
        });

        return response()->json(['message' => 'Usuario eliminado correctamente.']);
    }

    /**
     * Restablecer la contraseña de un usuario (solo ADMIN y DIRECTOR).
     */
    public function resetPassword(Request $request, $id)
    {
        $currentUser = $request->user();
        if (!$currentUser->isAdmin() && !$currentUser->isDirector()) {
            return response()->json(['message' => 'No autorizado para restablecer contraseñas.'], 403);
        }

        $user = User::findOrFail($id);

        $validated = $request->validate([
            'password' => 'nullable|string|min:6',
        ]);

        $defaultPassword = str_contains($user->email, 'puertoinca') ? 'Puertoinca123!' : 'Personero123!';
        $newPassword = !empty($validated['password']) ? $validated['password'] : $defaultPassword;

        $user->password = Hash::make($newPassword);
        $user->save();

        return response()->json([
            'message' => "Contraseña del usuario {$user->name} restablecida correctamente.",
            'user_id' => $user->id,
            'email' => $user->email,
            'new_password' => $newPassword,
        ]);
    }
}
