<?php
/**
 * Shabdiz — Backend API (single front controller)
 *
 * Deploy under: https://apps.webiro.ir/shabdiz/
 * All requests are rewritten to this file by .htaccess / nginx config.
 */

declare(strict_types=1);

ini_set('display_errors', '0');
error_reporting(E_ALL);

$configPath = __DIR__ . '/../config.php';
if (!file_exists($configPath)) {
    http_response_code(500);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['error' => 'config_missing']);
    exit;
}
$config = require $configPath;

// ---- Bootstrap -------------------------------------------------------------
require __DIR__ . '/../src/Response.php';
require __DIR__ . '/../src/Database.php';
require __DIR__ . '/../src/Http.php';
require __DIR__ . '/../src/Mail.php';
require __DIR__ . '/../src/Auth.php';
require __DIR__ . '/../src/Proxy.php';
require __DIR__ . '/../src/Device.php';
require __DIR__ . '/../src/Admin.php';

Database::init($config['db_path']);

// ---- CORS ------------------------------------------------------------------
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if (in_array('*', $config['cors_origins'], true)) {
    header('Access-Control-Allow-Origin: *');
} elseif ($origin && in_array($origin, $config['cors_origins'], true)) {
    header("Access-Control-Allow-Origin: $origin");
    header('Vary: Origin');
}
header('Access-Control-Allow-Methods: GET, POST, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

// ---- Routing ---------------------------------------------------------------
// Preferred: clean URLs via rewrite. Fallback: /index.php?_route=/health
// for hosts that don't apply .htaccess rewrites.
$uri = ($_GET['_route'] ?? '')
    ?: (parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/');

// Strip the deployment subdirectory (e.g. /shabdiz) and any /index.php prefix
$scriptDir = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? '')), '/');
if ($scriptDir && $scriptDir !== '/' && str_starts_with($uri, $scriptDir)) {
    $uri = substr($uri, strlen($scriptDir));
}
$uri = '/' . trim(preg_replace('#^/index\.php#', '', $uri), '/');
$uri = preg_replace('#/+#', '/', $uri);

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$body   = Http::jsonBody();
$GLOBALS['__shabdiz_config'] = $config;
$auth   = new Auth($config);

try {
    route($method, $uri, $body, $config, $auth);
} catch (Throwable $e) {
    error_log('[shabdiz] ' . $e->getMessage());
    Response::json(['error' => 'internal_error'], 500);
}

function route(string $method, string $uri, array $body, array $config, Auth $auth): void
{
    $segments = array_values(array_filter(explode('/', trim($uri, '/')), fn ($s) => $s !== ''));
    if (($segments[0] ?? '') === 'api') {
        array_shift($segments);
    }
    $p0 = $segments[0] ?? null;
    $p1 = $segments[1] ?? null;
    $p2 = $segments[2] ?? null;

    // ---------- Health ----------
    if ($p0 === 'health') {
        Response::json(['ok' => true, 'service' => 'shabdiz', 'time' => gmdate('c')]);
    }

    // ---------- Root ----------
    if ($p0 === null) {
        Response::json([
            'service' => 'shabdiz',
            'version' => '2.0',
            'health'  => 'health',
            'api'     => 'api/{endpoint}',
        ]);
    }

    // ---------- Geo / VPN gate (public) ----------
    if ($p0 === 'geo') {
        Response::json(Geo::check());
    }

    // ---------- Device registration (public, optional token) ----------
    if ($p0 === 'device' && $p1 === 'register' && $method === 'POST') {
        $GLOBALS['__shabdiz_auth_user'] = $auth->userFromRequest();
        Response::json(Device::register($body));
    }

    // ---------- Admin panel ----------
    if ($p0 === 'admin') {
        Admin::handle(array_slice($segments, 1), $method, $body, $config);
    }

    // ---------- Auth ----------
    if ($p0 === 'auth' && $p1 === 'request' && $method === 'POST') {
        $email = Auth::normalizeEmail($body['email'] ?? '');
        if ($email === null) {
            Response::json(['error' => 'invalid_email'], 422);
        }
        Auth::requestOtp($config, $email);
        Response::json(['ok' => true, 'message' => 'کد تایید به ایمیل شما ارسال شد']);
    }

    if ($p0 === 'auth' && $p1 === 'verify' && $method === 'POST') {
        $email = Auth::normalizeEmail($body['email'] ?? '');
        $code  = preg_replace('/\D/', '', (string) ($body['code'] ?? ''));
        if ($email === null || strlen($code) !== (int) $config['otp']['length']) {
            Response::json(['error' => 'invalid_input'], 422);
        }
        $result = Auth::verifyOtp($config, $email, $code);
        Device::linkToDevice($result['user'], isset($body['device_id']) ? (string) $body['device_id'] : null);
        Response::json($result);
    }

    // ---------- Everything below requires a token ----------
    $user = $auth->userFromRequest();
    if ($user === null) {
        Response::json(['error' => 'unauthorized'], 401);
    }

    if ($p0 === 'me' && $method === 'GET') {
        Response::json(['user' => $user]);
    }
    if ($p0 === 'me' && $method === 'PATCH') {
        Response::json(['user' => Auth::updateProfile($user, $body)]);
    }
    if ($p0 === 'me' && $method === 'DELETE') {
        Auth::deleteAccount($user);
        Response::json(['ok' => true]);
    }

    // ---------- Favorites (synced, server-side) ----------
    if ($p0 === 'favorites') {
        if ($method === 'GET') {
            Response::json(['favorites' => Auth::getFavorites($user)]);
        }
        if ($method === 'PUT') {
            Response::json(['favorites' => Auth::setFavorites($user, $body['favorites'] ?? [])]);
        }
        if ($method === 'POST') {
            Response::json(['favorites' => Auth::upsertFavorite($user, $body)]);
        }
        if ($method === 'DELETE' && is_numeric($p1)) {
            Response::json(['favorites' => Auth::removeFavorite($user, (int) $p1, (string) ($body['type'] ?? $p2 ?? ''))]);
        }
    }

    // ---------- Content proxy (upstream API key stays server-side) ----------
    if ($p0 !== null) {
        $proxy = new Proxy($config['upstream']);
        Response::json($proxy->handle($method, $segments, $_GET));
    }

    Response::json(['error' => 'not_found'], 404);
}
