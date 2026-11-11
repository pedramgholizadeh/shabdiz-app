<?php

declare(strict_types=1);

namespace Shabdiz\Repositories;

use DateTimeImmutable;
use DateTimeZone;
use Shabdiz\Core\Database;
use Shabdiz\Support\Jalali;

final class ScreeningRepository
{
    public static function present(array $row): array
    {
        $movie = MovieRepository::present($row);
        $starts = MovieRepository::utc((string) $row['starts_at_utc']);
        $ends = MovieRepository::utc((string) $row['ends_at_utc']);
        $now = new DateTimeImmutable('now', new DateTimeZone('UTC'));
        $status = Jalali::status($starts, $ends, $now);

        return [
            'id' => (int) ($row['screening_id'] ?? $row['id'] ?? 0),
            'room' => (string) ($row['room'] ?? 'main'),
            'starts_at' => $starts->format('Y-m-d\TH:i:s\Z'),
            'ends_at' => $ends->format('Y-m-d\TH:i:s\Z'),
            'starts_at_jalali' => Jalali::format($starts, 'date'),
            'starts_at_label' => Jalali::format($starts),
            'status' => $status,
            'movie' => $movie,
        ];
    }

    public static function find(int $id): ?array
    {
        return Database::first(
            'SELECT s.id AS screening_id, s.*, m.*,
                (SELECT GROUP_CONCAT(c.name_fa ORDER BY c.name_fa SEPARATOR ",")
                 FROM movie_categories mc JOIN categories c ON c.id = mc.category_id
                 WHERE mc.movie_id = m.id) AS genres
             FROM screenings s JOIN movies m ON m.id = s.movie_id
             WHERE s.id = ? LIMIT 1',
            [$id],
        );
    }

    public static function forMovie(int $movieId): array
    {
        $rows = Database::select(
            'SELECT s.id AS screening_id, s.*, m.*,
                (SELECT GROUP_CONCAT(c.name_fa ORDER BY c.name_fa SEPARATOR ",")
                 FROM movie_categories mc JOIN categories c ON c.id = mc.category_id
                 WHERE mc.movie_id = m.id) AS genres
             FROM screenings s JOIN movies m ON m.id = s.movie_id
             WHERE s.movie_id = ? AND s.is_active = 1
             ORDER BY s.starts_at_utc ASC',
            [$movieId],
        );
        return array_map(static fn (array $row): array => self::present($row), $rows);
    }

    public static function listAdmin(int $limit = 100): array
    {
        $rows = Database::select(
            'SELECT s.id AS screening_id, s.*, m.title_fa, m.title_en, m.slug, m.cover_url, m.duration_seconds, m.status AS movie_status
             FROM screenings s JOIN movies m ON m.id = s.movie_id
             ORDER BY s.starts_at_utc DESC LIMIT ' . max(1, min(300, $limit)),
        );
        return array_map(static function (array $row): array {
            $starts = MovieRepository::utc((string) $row['starts_at_utc']);
            $ends = MovieRepository::utc((string) $row['ends_at_utc']);
            return $row + [
                'starts_at_label' => Jalali::format($starts),
                'status' => Jalali::status($starts, $ends),
            ];
        }, $rows);
    }

    public static function count(): int
    {
        $row = Database::first('SELECT COUNT(*) AS total FROM screenings');
        return (int) ($row['total'] ?? 0);
    }

    public static function next(): ?array
    {
        return Database::first(
            'SELECT s.id AS screening_id, s.starts_at_utc, s.ends_at_utc, m.title_fa
             FROM screenings s JOIN movies m ON m.id = s.movie_id
             WHERE s.is_active = 1 AND s.ends_at_utc >= UTC_TIMESTAMP()
             ORDER BY s.starts_at_utc ASC LIMIT 1',
        );
    }

    /** @param array<string, mixed> $data */
    public static function create(array $data): int
    {
        return Database::insert(
            'INSERT INTO screenings
                (movie_id, room, starts_at_utc, ends_at_utc, source_url, source_type,
                 subtitle_url, subtitle_label, is_active, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, UTC_TIMESTAMP(), UTC_TIMESTAMP())',
            [
                $data['movie_id'],
                $data['room'],
                $data['starts_at_utc'],
                $data['ends_at_utc'],
                $data['source_url'],
                $data['source_type'],
                $data['subtitle_url'],
                $data['subtitle_label'],
            ],
        );
    }

    /** @return array{status: string, position_seconds: int, starts_at: DateTimeImmutable, ends_at: DateTimeImmutable} */
    public static function playbackState(array $row): array
    {
        $starts = MovieRepository::utc((string) $row['starts_at_utc']);
        $ends = MovieRepository::utc((string) $row['ends_at_utc']);
        $now = new DateTimeImmutable('now', new DateTimeZone('UTC'));
        $status = Jalali::status($starts, $ends, $now);
        $position = $status === 'live' ? max(0, $now->getTimestamp() - $starts->getTimestamp()) : 0;

        return [
            'status' => $status,
            'position_seconds' => $position,
            'starts_at' => $starts,
            'ends_at' => $ends,
        ];
    }
}
