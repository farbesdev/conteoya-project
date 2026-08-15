<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Http\Request;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(\App\Contracts\StorageProviderInterface::class, function () {
            if (app()->environment('testing') || empty(env('AWS_ACCESS_KEY_ID'))) {
                return new \App\Infrastructure\Storage\MockStorageProvider();
            }
            return new \App\Infrastructure\Storage\R2StorageProvider();
        });

        $this->app->singleton(\App\Contracts\ActRecognitionProviderInterface::class, function () {
            if (!empty(env('GEMINI_API_KEY'))) {
                return new \App\Infrastructure\Ocr\GeminiVisionProvider();
            }
            if (!empty(env('OPENAI_API_KEY'))) {
                return new \App\Infrastructure\Ocr\OpenAiVisionProvider();
            }
            return new \App\Infrastructure\Ocr\MockActRecognitionProvider();
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $this->configureRateLimiting();
    }

    /**
     * Configure rate limiters for the application.
     */
    protected function configureRateLimiting(): void
    {
        // Limiter general de la API por IP (Alta Concurrencia: 120 peticiones por minuto por IP)
        RateLimiter::for('api', function (Request $request) {
            return Limit::perMinute(120)->by($request->ip());
        });

        // Limiter estricto para inicio de sesión por IP para prevenir ataques por fuerza bruta (10 intentos por minuto por IP)
        RateLimiter::for('login', function (Request $request) {
            return Limit::perMinute(10)->by($request->ip())->response(function () {
                return response()->json([
                    'message' => 'Demasiados intentos de inicio de sesión. Por favor intente más tarde.'
                ], 429);
            });
        });

        // Limiter de Ingesta / Sincronización: 20 req/min por IP
        // Con caché Redis en /sync/pull (TTL 120s), 20/min es más que suficiente.
        // La caché absorbe los reintentos periódicos del SyncEngine móvil.
        RateLimiter::for('ingestion', function (Request $request) {
            return Limit::perMinute(20)->by($request->ip());
        });

        // Limiter específico para registro de actas y evidencias
        RateLimiter::for('acts', function (Request $request) {
            return Limit::perMinute(120)->by($request->user()?->id ?? $request->ip());
        });
    }
}
