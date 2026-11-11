<?php

declare(strict_types=1);

namespace Shabdiz\Repositories;

use Shabdiz\Core\Database;

final class PlaybackRepository
{
    public static function join(int $userId, int $screeningId, string $ip, string $userAgent): array
    {
        $publicId = bin2hex(random_bytes(16));
        Database::execute(
            'INSERT INTO playback_sessions
                (public_id, user_id, screening_id, started_at, last_heartbeat_at, ip, user_agent)
             VALUES (?, ?, ?, UTC_TIMESTAMP(), UTC_TIMESTAMP(), ?, ?)
             ON DUPLICATE KEY UPDATE
                last_heartbeat_at = UTC_TIMESTAMP(),
                ip = VALUES(ip),
                user_agent = VALUES(user_agent)',
            [$publicId, $userId, $screeningId, $ip, mb_substr($userAgent, 0, 255)],
        );

        return Database::first(
            'SELECT * FROM playback_sessions WHERE user_id = ? AND screening_id = ? LIMIT 1',
            [$userId, $screeningId],
        ) ?? [];
    }

    public static function heartbeat(int $userId, int $screeningId): void
    {
        Database::execute(
            'UPDATE playback_sessions SET last_heartbeat_at = UTC_TIMESTAMP()
             WHERE user_id = ? AND screening_id = ?',
            [$userId, $screeningId],
        );
    }
}
