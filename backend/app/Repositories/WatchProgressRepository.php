<?php

declare(strict_types=1);

namespace Shabdiz\Repositories;

use Shabdiz\Core\Database;
use Shabdiz\Support\Jalali;

/**
 * Personal watch progress. The synchronized playback position stays wall-clock
 * derived (the server is the clock); this only records how far each viewer got.
 */
final class WatchProgressRepository
{
    public static function record(
        int $userId,
        int $screeningId,
        int $movieId,
        int $positionSeconds,
        int $durationSeconds,
    ): void {
        $duration = max(0, $durationSeconds);
        $position = $duration > 0 ? max(0, min($positionSeconds, $duration)) : max(0, $positionSeconds);
        $completed = $duration > 0 && $position >= (int) floor($duration * 0.95) ? 1 : 0;

        Database::execute(
            'INSERT INTO watch_progress
                (user_id, screening_id, movie_id, position_seconds, duration_seconds, completed,
                 last_watched_at, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, UTC_TIMESTAMP(), UTC_TIMESTAMP(), UTC_TIMESTAMP())
             ON DUPLICATE KEY UPDATE
                position_seconds = GREATEST(position_seconds, VALUES(position_seconds)),
                duration_seconds = VALUES(duration_seconds),
                completed = IF(completed = 1 OR VALUES(completed) = 1, 1, 0),
                last_watched_at = UTC_TIMESTAMP(),
                updated_at = UTC_TIMESTAMP()',
            [$userId, $screeningId, $movieId, $position, $duration, $completed],
        );
    }

    /** Merge a guest's rows into the real account, keeping the furthest position. */
    public static function reassign(int $guestId, int $userId): void
    {
        Database::execute(
            'UPDATE watch_progress target
             JOIN watch_progress guest ON guest.user_id = ? AND guest.screening_id = target.screening_id
             SET target.position_seconds = GREATEST(target.position_seconds, guest.position_seconds),
                 target.duration_seconds = GREATEST(target.duration_seconds, guest.duration_seconds),
                 target.completed = GREATEST(target.completed, guest.completed),
                 target.last_watched_at = GREATEST(target.last_watched_at, guest.last_watched_at)
             WHERE target.user_id = ?',
            [$guestId, $userId],
        );
        Database::execute(
            'UPDATE watch_progress wp
             LEFT JOIN watch_progress keep ON keep.user_id = ? AND keep.screening_id = wp.screening_id
             SET wp.user_id = ?
             WHERE wp.user_id = ? AND keep.id IS NULL',
            [$userId, $userId, $guestId],
        );
    }

    /** @return array<int, array<string, mixed>> */
    public static function historyForUser(int $userId, int $limit = 50): array
    {
        $rows = Database::select(
            'SELECT wp.screening_id, wp.position_seconds, wp.duration_seconds, wp.completed, wp.last_watched_at,
                    m.slug AS movie_slug, m.title_fa, m.cover_url, m.duration_seconds AS movie_duration,
                    s.starts_at_utc
             FROM watch_progress wp
             JOIN screenings s ON s.id = wp.screening_id
             JOIN movies m ON m.id = wp.movie_id
             WHERE wp.user_id = ?
             ORDER BY wp.last_watched_at DESC LIMIT ' . max(1, min(100, $limit)),
            [$userId],
        );
        return array_map(static fn (array $row): array => self::presentRow($row), $rows);
    }

    /** @return array<int, array<string, mixed>> */
    public static function adminList(int $limit = 300): array
    {
        $rows = Database::select(
            'SELECT wp.user_id, wp.screening_id, wp.position_seconds, wp.duration_seconds, wp.completed,
                    wp.last_watched_at, u.name AS user_name, u.email AS user_email, u.is_guest AS user_is_guest,
                    m.title_fa, m.slug AS movie_slug, m.duration_seconds AS movie_duration,
                    s.starts_at_utc,
                    (SELECT MAX(ps.last_heartbeat_at) FROM playback_sessions ps
                     WHERE ps.user_id = wp.user_id AND ps.screening_id = wp.screening_id) AS last_heartbeat
             FROM watch_progress wp
             JOIN users u ON u.id = wp.user_id
             JOIN movies m ON m.id = wp.movie_id
             JOIN screenings s ON s.id = wp.screening_id
             ORDER BY wp.last_watched_at DESC LIMIT ' . max(1, min(300, $limit)),
        );
        return array_map(static fn (array $row): array => self::presentRow($row), $rows);
    }

    /** @param array<string, mixed> $row */
    private static function presentRow(array $row): array
    {
        $duration = max(1, (int) (($row['duration_seconds'] ?: $row['movie_duration'] ?? 0)));
        $position = max(0, min((int) $row['position_seconds'], $duration));
        $starts = MovieRepository::utc((string) $row['starts_at_utc']);

        return $row + [
            'screening_id' => (int) $row['screening_id'],
            'movie_slug' => (string) $row['movie_slug'],
            'movie_title_fa' => (string) $row['title_fa'],
            'cover_url' => (string) ($row['cover_url'] ?? ''),
            'position_seconds' => $position,
            'duration_seconds' => $duration,
            'percent' => min(100, (int) floor($position / $duration * 100)),
            'completed' => (int) $row['completed'] === 1,
            'starts_at_label' => Jalali::format($starts),
            'last_watched_at' => (string) $row['last_watched_at'],
        ];
    }
}
