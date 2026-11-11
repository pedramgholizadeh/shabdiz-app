<?php

declare(strict_types=1);

use Shabdiz\Core\Config;
use Shabdiz\Core\Request;
use Shabdiz\Core\Response;
use Shabdiz\Core\Router;
use Shabdiz\Http\Controllers\Admin\AuthController as AdminAuthController;
use Shabdiz\Http\Controllers\Admin\DashboardController;
use Shabdiz\Http\Controllers\Admin\MovieController as AdminMovieController;
use Shabdiz\Http\Controllers\Admin\ScreeningController as AdminScreeningController;
use Shabdiz\Http\Controllers\Admin\UserController as AdminUserController;
use Shabdiz\Http\Controllers\Admin\WatchController as AdminWatchController;
use Shabdiz\Http\Controllers\Api\AuthController as ApiAuthController;
use Shabdiz\Http\Controllers\Api\HealthController;
use Shabdiz\Http\Controllers\Api\MovieController as ApiMovieController;
use Shabdiz\Http\Controllers\Api\ScreeningController as ApiScreeningController;

require dirname(__DIR__) . '/app/bootstrap.php';

$router = new Router();

$router->get('/', static fn () => Response::redirect(url('admin')));

$router->get('/admin/login', [AdminAuthController::class, 'showLogin']);
$router->post('/admin/login', [AdminAuthController::class, 'login']);
$router->post('/admin/logout', [AdminAuthController::class, 'logout']);

$router->get('/admin', [DashboardController::class, 'index']);
$router->get('/admin/movies', [AdminMovieController::class, 'index']);
$router->get('/admin/movies/new', [AdminMovieController::class, 'create']);
$router->post('/admin/movies', [AdminMovieController::class, 'store']);
$router->get('/admin/screenings', [AdminScreeningController::class, 'index']);
$router->get('/admin/screenings/new', [AdminScreeningController::class, 'create']);
$router->post('/admin/screenings', [AdminScreeningController::class, 'store']);
$router->get('/admin/users', [AdminUserController::class, 'index']);
$router->get('/admin/watching', [AdminWatchController::class, 'index']);

$router->get('/api/health', [HealthController::class, 'index']);
$router->post('/api/auth/request-otp', [ApiAuthController::class, 'requestOtp']);
$router->post('/api/auth/verify-otp', [ApiAuthController::class, 'verifyOtp']);
$router->post('/api/guest', [ApiAuthController::class, 'guest']);
$router->get('/api/me', [ApiAuthController::class, 'me']);
$router->get('/api/me/history', [ApiAuthController::class, 'history']);
$router->get('/api/timeline', [ApiMovieController::class, 'timeline']);
$router->get('/api/movies/{slug}', [ApiMovieController::class, 'show']);
$router->post('/api/screenings/{id}/join', [ApiScreeningController::class, 'join']);
$router->get('/api/screenings/{id}/timeline', [ApiScreeningController::class, 'timeline']);
$router->post('/api/screenings/{id}/heartbeat', [ApiScreeningController::class, 'heartbeat']);

$router->dispatch(Request::method(), Request::path(Config::basePath()));
