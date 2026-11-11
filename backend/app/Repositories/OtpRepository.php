<?php

declare(strict_types=1);

namespace Shabdiz\Repositories;

use Shabdiz\Core\Database;

final class OtpRepository
{
    public static function recentExists(string $email, int $seconds = 60): bool
    {
        $row = Database::first(
            'SELECT id FROM otp_codes
             WHERE email = ? AND created_at > DATE_SUB(UTC_TIMESTAMP(), INTERVAL ? SECOND)
             ORDER BY id DESC LIMIT 1',
            [$email, $seconds],
        );
        return $row !== null;
    }

    public static function create(string $email, string $codeHash, int $ttlSeconds, string $ip): void
    {
        Database::execute(
            'INSERT INTO otp_codes (email, code_hash, expires_at, ip, created_at)
             VALUES (?, ?, DATE_ADD(UTC_TIMESTAMP(), INTERVAL ? SECOND), ?, UTC_TIMESTAMP())',
            [$email, $codeHash, $ttlSeconds, $ip],
        );
        Database::execute(
            'DELETE FROM otp_codes WHERE created_at < DATE_SUB(UTC_TIMESTAMP(), INTERVAL 2 DAY)',
        );
    }

    public static function latestValid(string $email): ?array
    {
        return Database::first(
            'SELECT * FROM otp_codes
             WHERE email = ? AND consumed_at IS NULL AND attempts < 5 AND expires_at > UTC_TIMESTAMP()
             ORDER BY id DESC LIMIT 1',
            [$email],
        );
    }

    public static function incrementAttempts(int $id): void
    {
        Database::execute('UPDATE otp_codes SET attempts = attempts + 1 WHERE id = ?', [$id]);
    }

    public static function consume(int $id): void
    {
        Database::execute('UPDATE otp_codes SET consumed_at = UTC_TIMESTAMP() WHERE id = ?', [$id]);
    }
}
