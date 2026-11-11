<?php

declare(strict_types=1);

namespace Shabdiz\Core;

use Throwable;

final class Router
{
    /** @var array<int, array{method: string, pattern: string, handler: callable}> */
    private array $routes = [];

    public function get(string $pattern, callable $handler): void
    {
        $this->add('GET', $pattern, $handler);
    }

    public function post(string $pattern, callable $handler): void
    {
        $this->add('POST', $pattern, $handler);
    }

    private function add(string $method, string $pattern, callable $handler): void
    {
        $regex = preg_replace('/\{([a-zA-Z_][a-zA-Z0-9_]*)\}/', '(?P<$1>[^/]+)', $pattern);
        $this->routes[] = [
            'method' => $method,
            'pattern' => '#^' . $regex . '$#',
            'handler' => $handler,
        ];
    }

    public function dispatch(string $method, string $path): void
    {
        foreach ($this->routes as $route) {
            if ($route['method'] !== $method) {
                continue;
            }
            if (preg_match($route['pattern'], $path, $matches) !== 1) {
                continue;
            }
            $params = array_filter(
                $matches,
                static fn ($key): bool => is_string($key),
                ARRAY_FILTER_USE_KEY,
            );
            try {
                ($route['handler'])($params);
            } catch (Throwable $exception) {
                if (Config::bool('APP_DEBUG', false)) {
                    Response::error($exception->getMessage(), 500, 'server_error');
                }
                error_log('[shabdiz] ' . $exception->getMessage());
                Response::error('خطای داخلی سرور رخ داد.', 500, 'server_error');
            }
            return;
        }

        if (str_starts_with($path, '/api/')) {
            Response::error('مسیر مورد نظر پیدا نشد.', 404, 'not_found');
        }
        Response::html('<!doctype html><html lang="fa" dir="rtl"><meta charset="utf-8"><title>۴۰۴</title><body style="background:#08080c;color:#f5f5f7;font-family:Tahoma;display:grid;place-items:center;height:100vh"><p>صفحه پیدا نشد. <a style="color:#e8b86d" href="' . Config::url('admin') . '">پنل ادمین</a></p></body></html>', 404);
    }
}
