<?php

final class Auth
{
    public static function normalizeEmail(string $email): ?string
    {
        $email = strtolower(trim($email));
        return filter_var($email, FILTER_VALIDATE_EMAIL) ? $email : null;
    }

    // ------------------------------------------------------------------ OTP

    public static function requestOtp(array $config, string $email): void
    {
        $pdo  = Database::pdo();
        $now  = time();
        $cool = (int) $config['otp']['resend_seconds'];

        $last = $pdo->prepare('SELECT MAX(created_at) AS t FROM otp_codes WHERE email = ?');
        $last->execute([$email]);
        $lastAt = (int) ($last->fetch()['t'] ?? 0);
        if ($now - $lastAt < $cool) {
            Response::json(['error' => 'rate_limited', 'retry_after' => $cool - ($now - $lastAt)], 429);
        }

        $code      = str_pad((string) random_int(0, (10 ** (int) $config['otp']['length']) - 1), (int) $config['otp']['length'], '0', STR_PAD_LEFT);
        $insertOtp = $pdo->prepare('INSERT INTO otp_codes (email, code, expires_at, created_at) VALUES (?, ?, ?, ?)');
        $insertOtp->execute([$email, $code, $now + (int) $config['otp']['ttl_seconds'], $now]);

        if (!Mail::sendOtpCode($config, $email, $code)) {
            Response::json(['error' => 'email_send_failed'], 502);
        }
    }

    public static function verifyOtp(array $config, string $email, string $code): array
    {
        $pdo = Database::pdo();
        $now = time();

        $row = $pdo->prepare(
            'SELECT * FROM otp_codes WHERE email = ? ORDER BY id DESC LIMIT 1'
        );
        $row->execute([$email]);
        $otp = $row->fetch();
        if (!$otp || (int) $otp['expires_at'] < $now) {
            Response::json(['error' => 'code_expired'], 410);
        }
        if ((int) $otp['attempts'] >= (int) $config['otp']['max_attempts']) {
            Response::json(['error' => 'too_many_attempts'], 429);
        }
        if (!hash_equals($otp['code'], $code)) {
            $pdo->prepare('UPDATE otp_codes SET attempts = attempts + 1 WHERE id = ?')
                ->execute([$otp['id']]);
            Response::json(['error' => 'invalid_code'], 401);
        }

        $pdo->prepare('DELETE FROM otp_codes WHERE email = ?')->execute([$email]);

        // Find or create the user
        $find = $pdo->prepare('SELECT * FROM users WHERE email = ?');
        $find->execute([$email]);
        $user = $find->fetch();
        if (!$user) {
            $pdo->prepare('INSERT INTO users (email) VALUES (?)')->execute([$email]);
            $find->execute([$email]);
            $user = $find->fetch();
        }

        // Issue token (30 days)
        $token  = bin2hex(random_bytes(32));
        $expiry = $now + 60 * 60 * 24 * 30;
        $pdo->prepare('INSERT INTO auth_tokens (token, user_id, expires_at, created_at) VALUES (?, ?, ?, ?)')
            ->execute([$token, $user['id'], $expiry, $now]);

        return ['token' => $token, 'expires_at' => $expiry, 'user' => self::present($user)];
    }

    // ------------------------------------------------------------------ Token

    public static function userFromRequest(array $config = []): ?array
    {
        $config = $config ?: $GLOBALS['__shabdiz_config'];
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        if ($header === '' && function_exists('apache_request_headers')) {
            $header = apache_request_headers()['Authorization'] ?? '';
        }
        if (!preg_match('/^Bearer\s+(\S+)$/i', $header, $m)) {
            return null;
        }
        return self::userFromToken($m[1]);
    }

    public static function userFromToken(string $token): ?array
    {
        $pdo = Database::pdo();
        $row = $pdo->prepare(
            'SELECT u.* FROM auth_tokens t JOIN users u ON u.id = t.user_id
             WHERE t.token = ? AND t.expires_at > ?'
        );
        $row->execute([$token, time()]);
        $user = $row->fetch();
        return $user ? self::present($user) : null;
    }

    // ------------------------------------------------------------------ Profile

    public static function updateProfile(array $user, array $body): array
    {
        $name = trim((string) ($body['name'] ?? $user['name']));
        if (mb_strlen($name) > 60) {
            Response::json(['error' => 'name_too_long'], 422);
        }
        Database::pdo()->prepare('UPDATE users SET name = ? WHERE id = ?')
            ->execute([$name, $user['id']]);
        $user['name'] = $name;
        return self::present($user);
    }

    public static function deleteAccount(array $user): void
    {
        Database::pdo()->prepare('DELETE FROM users WHERE id = ?')->execute([$user['id']]);
    }

    // ------------------------------------------------------------------ Favorites

    public static function getFavorites(array $user): array
    {
        $rows = Database::pdo()->prepare(
            'SELECT media_id, type, payload, created_at FROM favorites WHERE user_id = ? ORDER BY created_at DESC'
        );
        $rows->execute([$user['id']]);
        $out = [];
        foreach ($rows->fetchAll() as $r) {
            $item = json_decode($r['payload'], true) ?: [];
            $item['timestamp'] = (int) $r['created_at'];
            $out[] = $item;
        }
        return $out;
    }

    public static function setFavorites(array $user, array $favorites): array
    {
        $pdo = Database::pdo();
        $pdo->beginTransaction();
        $pdo->prepare('DELETE FROM favorites WHERE user_id = ?')->execute([$user['id']]);
        $ins = $pdo->prepare(
            'INSERT OR IGNORE INTO favorites (user_id, media_id, type, payload, created_at) VALUES (?, ?, ?, ?, ?)'
        );
        $now = time();
        foreach ($favorites as $f) {
            if (!isset($f['id'], $f['type'])) {
                continue;
            }
            $ins->execute([$user['id'], (int) $f['id'], (string) $f['type'], json_encode($f, JSON_UNESCAPED_UNICODE), $now]);
        }
        $pdo->commit();
        return self::getFavorites($user);
    }

    public static function upsertFavorite(array $user, array $item): array
    {
        if (!isset($item['id'], $item['type'])) {
            Response::json(['error' => 'invalid_input'], 422);
        }
        Database::pdo()->prepare(
            'INSERT OR REPLACE INTO favorites (user_id, media_id, type, payload, created_at) VALUES (?, ?, ?, ?, ?)'
        )->execute([$user['id'], (int) $item['id'], (string) $item['type'], json_encode($item, JSON_UNESCAPED_UNICODE), time()]);
        return self::getFavorites($user);
    }

    public static function removeFavorite(array $user, int $mediaId, string $type): array
    {
        Database::pdo()->prepare('DELETE FROM favorites WHERE user_id = ? AND media_id = ? AND type = ?')
            ->execute([$user['id'], $mediaId, $type]);
        return self::getFavorites($user);
    }

    // ------------------------------------------------------------------ Output

    private static function present(array $user): array
    {
        return [
            'id'         => (int) $user['id'],
            'email'      => $user['email'],
            'name'       => $user['name'],
            'avatar'     => $user['avatar'],
            'created_at' => $user['created_at'],
        ];
    }
}
