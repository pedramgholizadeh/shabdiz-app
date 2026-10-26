<?php

final class Device
{
    /**
     * Public endpoint — no login required. Registers/refreshes a device.
     * Anonymous installs become "device users"; the row is linked to a real
     * user as soon as they log in.
     */
    public static function register(array $body): array
    {
        $deviceId = trim((string) ($body['device_id'] ?? ''));
        if ($deviceId === '' || strlen($deviceId) > 64) {
            Response::json(['error' => 'invalid_input'], 422);
        }
        $platform = self::platformName((string) ($body['platform'] ?? ''));
        $version  = mb_substr(trim((string) ($body['app_version'] ?? '')), 0, 20);
        $ip       = self::clientIp();
        $country  = Geo::countryCode($ip);
        $now      = time();

        $pdo = Database::pdo();
        $pdo->prepare(
            'INSERT INTO devices (device_id, platform, app_version, ip, country, user_id, first_seen, last_seen)
             VALUES (?, ?, ?, ?, ?, NULL, ?, ?)
             ON CONFLICT(device_id) DO UPDATE SET
                platform = excluded.platform,
                app_version = excluded.app_version,
                ip = excluded.ip,
                country = excluded.country,
                last_seen = excluded.last_seen'
        )->execute([$deviceId, $platform, $version, $ip, $country, $now, $now]);

        // Attach the logged-in user (if any) to this device.
        $user = $GLOBALS['__shabdiz_auth_user'] ?? null;
        if ($user) {
            $pdo->prepare('UPDATE devices SET user_id = ? WHERE device_id = ?')
                ->execute([$user['id'], $deviceId]);
        }

        return ['ok' => true];
    }

    /** Called right after a successful login so the device links to the user. */
    public static function linkToDevice(array $user, ?string $deviceId): void
    {
        if ($deviceId === null || $deviceId === '' || strlen($deviceId) > 64) {
            return;
        }
        $ip  = self::clientIp();
        $now = time();
        Database::pdo()->prepare(
            'INSERT INTO devices (device_id, platform, ip, country, user_id, first_seen, last_seen)
             VALUES (?, ?, ?, ?, ?, ?, ?)
             ON CONFLICT(device_id) DO UPDATE SET user_id = excluded.user_id, last_seen = excluded.last_seen'
        )->execute([$deviceId, 'unknown', $ip, Geo::countryCode($ip), $user['id'], $now, $now]);
    }

    public static function clientIp(): string
    {
        foreach (['HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR'] as $key) {
            $value = $_SERVER[$key] ?? '';
            if ($value !== '') {
                $first = trim(explode(',', $value)[0]);
                if (filter_var($first, FILTER_VALIDATE_IP)) {
                    return $first;
                }
            }
        }
        return '';
    }

    private static function platformName(string $raw): string
    {
        return match (strtolower(trim($raw))) {
            'android' => 'android',
            'windows' => 'windows',
            'macos'   => 'macos',
            'linux'   => 'linux',
            'ios'     => 'ios',
            'web'     => 'web',
            default   => 'unknown',
        };
    }
}

final class Geo
{
    private static array $cache = [];

    public static function countryCode(string $ip): string
    {
        if ($ip === '') {
            return '';
        }
        if (isset(self::$cache[$ip])) {
            return self::$cache[$ip];
        }
        $code = '';
        $json = self::fetch("https://ipwho.is/$ip?fields=country_code");
        if (is_array($json) && isset($json['country_code'])) {
            $code = (string) $json['country_code'];
        } else {
            // Fallback
            $json = self::fetch("http://ip-api.com/json/$ip?fields=countryCode");
            if (is_array($json) && isset($json['countryCode'])) {
                $code = (string) $json['countryCode'];
            }
        }
        self::$cache[$ip] = $code;
        return $code;
    }

    public static function isIran(string $ip): bool
    {
        return strtoupper(self::countryCode($ip)) === 'IR';
    }

    /** Public endpoint used by the app's VPN gate. */
    public static function check(): array
    {
        $ip      = Device::clientIp();
        $country = self::countryCode($ip);
        return [
            'ip'      => $ip,
            'country' => $country,
            'iran'    => strtoupper($country) === 'IR',
        ];
    }

    private static function fetch(string $url): mixed
    {
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT        => 5,
            CURLOPT_CONNECTTIMEOUT => 4,
        ]);
        $body = curl_exec($ch);
        curl_close($ch);
        if (!is_string($body) || $body === '') {
            return null;
        }
        return json_decode($body, true);
    }
}
