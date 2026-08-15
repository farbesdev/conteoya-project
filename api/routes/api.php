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

        // Personero, Users & Mesas
        Route::get('/personero/polling-stations', [PersoneroController::class, 'pollingStations']);
        Route::post('/users/{id}/reset-password', [\App\Http\Controllers\Api\V1\UserController::class, 'resetPassword']);
        Route::apiResource('users', \App\Http\Controllers\Api\V1\UserController::class);

        // Catálogos Electorales y Ubigeos (Alto Rendimiento & Caching)
        Route::get('/departments', [CatalogController::class, 'departments']);
        Route::get('/provinces', [CatalogController::class, 'provinces']);
        Route::get('/districts', [CatalogController::class, 'districts']);
        Route::get('/elections', [CatalogController::class, 'elections']);
        Route::get('/political-organizations', [CatalogController::class, 'politicalOrganizations']);
        Route::get('/electoral-lists', [CatalogController::class, 'electoralLists']);
        Route::get('/polling-stations', [CatalogController::class, 'pollingStations']);

        // Fase 1: Ingesta de Actas Electorales
        Route::middleware(['throttle:acts', 'idempotent'])->group(function () {
            Route::post('/acts', [\App\Http\Controllers\Api\V1\ActController::class, 'store']);
            Route::post('/acts/{act}/confirm', [\App\Http\Controllers\Api\V1\ActController::class, 'confirm']);
            Route::post('/acts/{act}/evidence/upload-url', [\App\Http\Controllers\Api\V1\EvidenceController::class, 'requestUploadUrl']);
            Route::post('/acts/{act}/evidence/confirm', [\App\Http\Controllers\Api\V1\EvidenceController::class, 'confirm']);
        });

        Route::get('/acts/{act}', [\App\Http\Controllers\Api\V1\ActController::class, 'show']);
        Route::get('/acts/{act}/evidence/{evidence}/download', [\App\Http\Controllers\Api\V1\EvidenceController::class, 'download']);

        // Reconocimiento Asistido OCR / IA (Human-in-the-Loop)
        Route::post('/acts/recognize', [\App\Http\Controllers\Api\V1\RecognitionController::class, 'recognize']);
        Route::post('/acts/{act}/recognize', [\App\Http\Controllers\Api\V1\RecognitionController::class, 'recognize']);

        // Motor de Sincronización Offline-First (Sync Engine)
        Route::middleware('throttle:ingestion')->group(function () {
            Route::post('/sync', [\App\Http\Controllers\Api\V1\SyncController::class, 'sync'])->middleware('idempotent');
            Route::get('/sync/pull', [\App\Http\Controllers\Api\V1\SyncController::class, 'pull']);
            Route::get('/sync/status', [\App\Http\Controllers\Api\V1\SyncController::class, 'status']);
        });
    });
});
