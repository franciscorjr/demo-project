<?php

/**
 * Health Check Route for Cloud Run
 *
 * Add this to your routes/web.php or routes/api.php
 */

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    $health = [
        'status' => 'healthy',
        'timestamp' => now()->toIso8601String(),
        'checks' => [],
    ];

    // Check database connection
    try {
        DB::connection()->getPdo();
        $health['checks']['database'] = 'ok';
    } catch (\Exception $e) {
        $health['checks']['database'] = 'failed';
        $health['status'] = 'unhealthy';
    }

    // Check cache connection (optional)
    try {
        Cache::store()->get('health-check');
        $health['checks']['cache'] = 'ok';
    } catch (\Exception $e) {
        $health['checks']['cache'] = 'failed';
        // Cache failure might not be critical
    }

    // Check storage is writable
    $storagePath = storage_path('logs');
    $health['checks']['storage'] = is_writable($storagePath) ? 'ok' : 'failed';

    $statusCode = $health['status'] === 'healthy' ? 200 : 503;

    return response()->json($health, $statusCode);
});

// Simple liveness probe (minimal overhead)
Route::get('/health/live', function () {
    return response('OK', 200);
});

// Readiness probe (checks if app is ready to receive traffic)
Route::get('/health/ready', function () {
    try {
        // Quick database check
        DB::connection()->getPdo();

        return response('OK', 200);
    } catch (\Exception $e) {
        return response('NOT READY', 503);
    }
});
