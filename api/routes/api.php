<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CatalogController;
use App\Http\Controllers\Api\V1\PersoneroController;

/*
|--------------------------------------------------------------------------
| ConteoYA API V1 Routes (Alto Rendimiento & Rate Limiting por IP)
|--------------------------------------------------------------------------
*/

Route::prefix('v1')->middleware('throttle:api')->group(function () {

    // Autenticación pública con RateLimit estricto por IP (Login)
    Route::middleware('throttle:login')->group(function () {
        Route::post('/login', [AuthController::class, 'login']);
    });

    // Rutas protegidas Sanctum con RateLimit por IP
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);

        // Personero & Mesas
        Route::get('/personero/polling-stations', [PersoneroController::class, 'pollingStations']);

        // Catálogos Electorales y Ubigeos (Alto Rendimiento & Caching)
        Route::get('/departments', [CatalogController::class, 'departments']);
        Route::get('/provinces', [CatalogController::class, 'provinces']);
        Route::get('/districts', [CatalogController::class, 'districts']);
        Route::get('/elections', [CatalogController::class, 'elections']);
        Route::get('/political-organizations', [CatalogController::class, 'politicalOrganizations']);
        Route::get('/electoral-lists', [CatalogController::class, 'electoralLists']);
    });
});
