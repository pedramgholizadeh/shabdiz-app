<?php

declare(strict_types=1);

namespace Shabdiz\Core;

final class Auth
{
    private static ?array $admin = null;
    private static bool $adminLoaded = false;

    public static function admin(): ?array
    {
        if (self::$adminLoaded) {
            return self::$admin;
        }
        self::$adminLoaded = true;
        $id = (int) ($_SESSION['admin_id'] ?? 0);
        if ($id <= 0) {
            return self::$admin = null;
        }
        self::$admin = Database::first(
            'SELECT id, name, email, created_at, last_login_at FROM admins WHERE id = ?',
            [$id],
        );
        if (self::$admin === null) {
            unset($_SESSION['admin_id']);
        }
        return self::$admin;
    }

    public static function attempt(string $email, string $password): bool
    {
        $admin = Database::first('SELECT * FROM admins WHERE email = ? LIMIT 1', [$email]);
        if ($admin === null || !password_verify($password, (string) $admin['password_hash'])) {
            return false;
        }
        session_regenerate_id(true);
        $_SESSION['admin_id'] = (int) $admin['id'];
        self::$admin = $admin;
        self::$adminLoaded = true;
        Database::execute('UPDATE admins SET last_login_at = UTC_TIMESTAMP() WHERE id = ?', [$admin['id']]);
        return true;
    }

    public static function logout(): void
    {
        unset($_SESSION['admin_id']);
        self::$admin = null;
        self::$adminLoaded = true;
        session_regenerate_id(true);
    }

    public static function requireAdmin(): array
    {
        $admin = self::admin();
        if ($admin === null) {
            Response::redirect(Config::url('admin/login'));
        }
        return $admin;
    }

    public static function csrfToken(): string
    {
        if (empty($_SESSION['_csrf'])) {
            $_SESSION['_csrf'] = bin2hex(random_bytes(24));
        }
        return (string) $_SESSION['_csrf'];
    }

    public static function assertCsrf(): void
    {
        $token = (string) ($_POST['_csrf'] ?? '');
        if ($token === '' || !hash_equals(self::csrfToken(), $token)) {
            Response::html('درخواست نامعتبر است. صفحه را دوباره باز کنید.', 419);
        }
    }

    public static function apiUser(): ?array
    {
        $token = Request::bearerToken();
        if ($token === null || $token === '') {
            return null;
        }
        $hash = hash('sha256', $token);
        $user = Database::first(
            'SELECT u.id, u.email, u.name, u.is_active, t.id AS token_id
             FROM auth_tokens t
             JOIN users u ON u.id = t.user_id
             WHERE t.token_hash = ? AND t.expires_at > UTC_TIMESTAMP()
             LIMIT 1',
            [$hash],
        );
        if ($user === null || (int) $user['is_active'] !== 1) {
            return null;
        }
        Database::execute(
            'UPDATE auth_tokens SET last_used_at = UTC_TIMESTAMP() WHERE id = ? AND (last_used_at IS NULL OR last_used_at < DATE_SUB(UTC_TIMESTAMP(), INTERVAL 10 MINUTE))',
            [$user['token_id']],
        );
        return $user;
    }

    public static function requireApiUser(): array
    {
        $user = self::apiUser();
        if ($user === null) {
            Response::error('برای دسترسی به این بخش باید وارد شوید.', 401, 'unauthenticated');
        }
        return $user;
    }

    public static function issueToken(int $userId, int $days = 30): string
    {
        $token = bin2hex(random_bytes(32));
        Database::insert(
            'INSERT INTO auth_tokens (user_id, token_hash, expires_at, created_at)
             VALUES (?, ?, DATE_ADD(UTC_TIMESTAMP(), INTERVAL ? DAY), UTC_TIMESTAMP())',
            [$userId, hash('sha256', $token), $days],
        );
        return $token;
    }
}
