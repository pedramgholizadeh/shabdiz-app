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
            'SELECT id, email, name, is_active, created_at, last_seen_at
             FROM users ORDER BY created_at DESC LIMIT ' . max(1, min(500, $limit)),
        );
    }

    public static function count(): int
    {
        $row = Database::first('SELECT COUNT(*) AS total FROM users');
        return (int) ($row['total'] ?? 0);
    }

    public static function publicPayload(array $user): array
    {
        return [
            'id' => (int) $user['id'],
            'email' => (string) $user['email'],
            'name' => (string) $user['name'],
            'created_at' => (string) ($user['created_at'] ?? ''),
        ];
    }
}
