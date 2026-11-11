<?php

declare(strict_types=1);

namespace Shabdiz\Core;

final class Response
{
    /** @param array<string, mixed> $data */
    public static function json(array $data, int $status = 200): never
    {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }

    /** @param array<string, mixed> $data */
    public static function ok(array $data = [], int $status = 200): never
    {
        self::json(['ok' => true, 'data' => $data], $status);
    }

    public static function error(
        string $message,
        int $status = 400,
        string $code = 'bad_request',
    ): never {
        self::json([
            'ok' => false,
            'error' => ['code' => $code, 'message' => $message],
        ], $status);
    }

    public static function redirect(string $location, int $status = 302): never
    {
        header('Location: ' . $location, true, $status);
        exit;
    }

    public static function html(string $body, int $status = 200): never
    {
        http_response_code($status);
        header('Content-Type: text/html; charset=utf-8');
        echo $body;
        exit;
    }
}
