<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserIsActive
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && !$user->is_active) {
            // Revocar tokens activos si la cuenta está inhabilitada
            $user->tokens()->delete();

            return response()->json([
                'message' => 'Su cuenta se encuentra inhabilitada. Comuníquese con el Administrador.',
            ], 403);
        }

        return $next($request);
    }
}
