<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

class IdempotencyMiddleware
{
    /**
     * Handle an incoming request with idempotency protection.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        // Solo aplicar a peticiones de escritura o con clave explícita
        $idempotencyKey = $request->header('Idempotency-Key')
            ?? $request->input('client_operation_id')
            ?? $request->header('X-Client-Operation-Id');

        if (!$idempotencyKey) {
            return $next($request);
        }

        $cacheKey = "idempotency:{$idempotencyKey}";

        // Verificar si la respuesta ya fue procesada y cacheada
        $cached = Cache::get($cacheKey);
        if ($cached) {
            return response()->json($cached['body'], $cached['status'])
                ->header('X-Idempotent-Replayed', 'true')
                ->header('X-Idempotency-Key', $idempotencyKey);
        }

        $response = $next($request);

        // Cachear solo respuestas exitosas (2xx / 3xx) por 24 horas
        if ($response->getStatusCode() < 400) {
            $content = json_decode($response->getContent(), true);
            Cache::put(
                $cacheKey,
                [
                    'body'   => $content ?? $response->getContent(),
                    'status' => $response->getStatusCode(),
                ],
                now()->addHours(24)
            );
        }

        return $response;
    }
}
