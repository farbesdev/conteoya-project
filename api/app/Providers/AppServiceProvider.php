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
        //
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

        // Limiter de Ingesta Masiva / Sincronización para Personeros (60 peticiones por minuto por IP)
        RateLimiter::for('ingestion', function (Request $request) {
            return Limit::perMinute(60)->by($request->ip());
        });
    }
}
