<?php

declare(strict_types=1);

namespace Shabdiz\Repositories;

use Shabdiz\Core\Database;

final class UserRepository
{
    public static function findByEmail(string $email): ?array
    {
        return Database::first('SELECT * FROM users WHERE email = ? LIMIT 1', [$email]);
    }

    public static function findOrCreate(string $email): array
    {
        $user = self::findByEmail($email);
        if ($user !== null) {
            Database::execute('UPDATE users SET last_seen_at = UTC_TIMESTAMP() WHERE id = ?', [$user['id']]);
            return $user;
        }
        $name = ucfirst(explode('@', $email)[0]);
        $id = Database::insert(
            'INSERT INTO users (email, name, created_at) VALUES (?, ?, UTC_TIMESTAMP())',
            [$email, $name],
        );
        return Database::first('SELECT * FROM users WHERE id = ?', [$id]) ?? [];
    }

    /** @return array<int, array<string, mixed>> */
    public static function paginate(int $limit = 200): array
    {
        return Database::select(
            'SELECT id, email, name, is_active, is_guest, created_at, last_seen_at
             FROM users ORDER BY created_at DESC LIMIT ' . max(1, min(500, $limit)),
        );
    }

    public static function count(): int
    {
        $row = Database::first('SELECT COUNT(*) AS total FROM users');
        return (int) ($row['total'] ?? 0);
    }

    /**
     * Guests get a token-bearing identity so they can watch without signing in.
     * A light per-IP hourly cap keeps the table from being flooded.
     * Returns null when the IP is throttled.
     */
    public static function createGuest(string $ip): ?array
    {
        $recent = Database::first(
            'SELECT COUNT(*) AS total FROM users
             WHERE is_guest = 1 AND guest_ip = ? AND created_at > DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 HOUR)',
            [$ip],
        );
        if ((int) ($recent['total'] ?? 0) >= 12) {
            return null;
        }
        $id = Database::insert(
            "INSERT INTO users (email, name, is_guest, guest_ip, created_at)
             VALUES (NULL, 'مهمان', 1, ?, UTC_TIMESTAMP())",
            [$ip],
        );
        return Database::first('SELECT * FROM users WHERE id = ?', [$id]) ?? [];
    }

    public static function deleteGuest(int $guestId): void
    {
        Database::execute('DELETE FROM auth_tokens WHERE user_id = ?', [$guestId]);
        Database::execute('DELETE FROM users WHERE id = ? AND is_guest = 1', [$guestId]);
    }

    public static function publicPayload(array $user): array
    {
        return [
            'id' => (int) $user['id'],
            'email' => (string) ($user['email'] ?? ''),
            'name' => (string) $user['name'],
            'is_guest' => (int) ($user['is_guest'] ?? 0) === 1,
            'created_at' => (string) ($user['created_at'] ?? ''),
        ];
    }
}
