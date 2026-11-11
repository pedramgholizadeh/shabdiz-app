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

    /** Distinct viewers with a fresh heartbeat on a screening that is live right now. */
    public static function liveViewers(): int
    {
        $row = Database::first(
            'SELECT COUNT(DISTINCT ps.user_id) AS total
             FROM playback_sessions ps
             JOIN screenings s ON s.id = ps.screening_id
             WHERE ps.last_heartbeat_at > DATE_SUB(UTC_TIMESTAMP(), INTERVAL 90 SECOND)
               AND s.starts_at_utc <= UTC_TIMESTAMP()
               AND s.ends_at_utc > UTC_TIMESTAMP()',
        );
        return (int) ($row['total'] ?? 0);
    }

    /** Move a guest's sessions onto the real account before the guest row is deleted. */
    public static function reassign(int $guestId, int $userId): void
    {
        Database::execute(
            'DELETE ps FROM playback_sessions ps
             JOIN playback_sessions keep ON keep.user_id = ? AND keep.screening_id = ps.screening_id
             WHERE ps.user_id = ?',
            [$userId, $guestId],
        );
        Database::execute('UPDATE playback_sessions SET user_id = ? WHERE user_id = ?', [$userId, $guestId]);
    }
}
