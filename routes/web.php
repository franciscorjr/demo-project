<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;
use Laravel\Fortify\Features;

Route::get('/', function () {
    return Inertia::render('Welcome', [
        'canRegister' => Features::enabled(Features::registration()),
    ]);
})->name('home');

Route::get('dashboard', function () {
    return Inertia::render('Dashboard');
})->middleware(['auth', 'verified'])->name('dashboard');

Route::get('/_health/octane', function () {
    return response()->json([
        'app_env' => app()->environment(),

        'octane' => [
            'enabled' => app()->bound('octane'),
            'driver'  => config('octane.server'),
        ],

        'frankenphp' => [
            'enabled' => extension_loaded('frankenphp'),
        ],

        'process' => [
            'pid' => getmypid(),
            'worker_id' => $_SERVER['OCTANE_WORKER_ID'] ?? null,
        ],

        'workers' => [
            'configured' => config('octane.workers'),
        ],
    ]);
});

require __DIR__.'/settings.php';
require __DIR__.'/health.php';
