<?php

declare(strict_types=1);

namespace Shabdiz\Core;

final class Config
{
    public static function get(string $key, ?string $default = null): ?string
    {
        $value = Env::get($key, $default);
        return $value === '' ? $default : $value;
    }

    public static function bool(string $key, bool $default = false): bool
    {
        $value = self::get($key);
        if ($value === null) {
            return $default;
        }
        return in_array(strtolower($value), ['1', 'true', 'yes', 'on'], true);
    }

    public static function int(string $key, int $default = 0): int
    {
        $value = self::get($key);
        return $value === null ? $default : (int) $value;
    }

    public static function basePath(): string
    {
        $path = trim(self::get('APP_BASE_PATH', ''), '/');
        return $path === '' ? '' : '/' . $path;
    }

    public static function baseUrl(): string
    {
        return rtrim(self::get('APP_URL', ''), '/');
    }

    public static function url(string $path = ''): string
    {
        return self::basePath() . ($path === '' ? '/' : '/' . ltrim($path, '/'));
    }

    public static function timezone(): string
    {
        return self::get('APP_TIMEZONE', 'Asia/Tehran');
    }
}
