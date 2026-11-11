<?php

declare(strict_types=1);

namespace Shabdiz\Repositories;

use DateTimeImmutable;
use DateTimeZone;
use Shabdiz\Core\Database;
use Shabdiz\Support\Jalali;

final class MovieRepository
{
    private const GENRES_SUBQUERY = '(SELECT GROUP_CONCAT(c.name_fa ORDER BY c.name_fa SEPARATOR ",")
        FROM movie_categories mc JOIN categories c ON c.id = mc.category_id
        WHERE mc.movie_id = m.id) AS genres';

    /** @return array<int, array<string, mixed>> */
    public static function timeline(int $limit = 60): array
    {
        $rows = Database::select(
            'SELECT s.id AS screening_id, s.room, s.starts_at_utc, s.ends_at_utc, s.subtitle_url,
                    m.*, ' . self::GENRES_SUBQUERY . '
             FROM screenings s
             JOIN movies m ON m.id = s.movie_id
             WHERE s.is_active = 1 AND m.status = \'published\'
               AND s.ends_at_utc >= DATE_SUB(UTC_TIMESTAMP(), INTERVAL 1 DAY)
             ORDER BY s.starts_at_utc DESC
             LIMIT ' . max(1, min(200, $limit)),
        );

        return array_map(
            static fn (array $row): array => ScreeningRepository::present($row),
            $rows,
        );
    }

    public static function findBySlug(string $slug): ?array
    {
        $row = Database::first(
            'SELECT m.*, ' . self::GENRES_SUBQUERY . ' FROM movies m WHERE m.slug = ? LIMIT 1',
            [$slug],
        );
        return $row === null ? null : self::present($row);
    }

    /** @return array<int, array<string, mixed>> */
    public static function listAdmin(int $limit = 100): array
    {
        $rows = Database::select(
            'SELECT m.*, (SELECT COUNT(*) FROM screenings s WHERE s.movie_id = m.id) AS screening_count
             FROM movies m ORDER BY m.created_at DESC LIMIT ' . max(1, min(300, $limit)),
        );
        return array_map(static fn (array $row): array => self::present($row), $rows);
    }

    public static function count(): int
    {
        $row = Database::first('SELECT COUNT(*) AS total FROM movies');
        return (int) ($row['total'] ?? 0);
    }

    /** @return array<int, array<string, mixed>> */
    public static function categories(): array
    {
        return Database::select('SELECT * FROM categories ORDER BY name_fa');
    }

    /** @param array<string, mixed> $data */
    public static function create(array $data, array $genres): int
    {
        $id = Database::insert(
            'INSERT INTO movies
                (slug, title_fa, title_en, synopsis_fa, director, year, duration_seconds,
                 imdb_rating, rt_rating, cover_url, backdrop_url, trailer_url, status, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, UTC_TIMESTAMP(), UTC_TIMESTAMP())',
            [
                $data['slug'],
                $data['title_fa'],
                $data['title_en'],
                $data['synopsis_fa'],
                $data['director'],
                $data['year'],
                $data['duration_seconds'],
                $data['imdb_rating'],
                $data['rt_rating'],
                $data['cover_url'],
                $data['backdrop_url'],
                $data['trailer_url'],
                $data['status'],
            ],
        );
        self::attachGenres($id, $genres);
        return $id;
    }

    public static function slugAvailable(string $slug): bool
    {
        return Database::first('SELECT id FROM movies WHERE slug = ?', [$slug]) === null;
    }

    public static function slugify(string $value): string
    {
        $slug = strtolower(trim($value));
        $slug = preg_replace('/[^a-z0-9]+/', '-', $slug) ?? '';
        $slug = trim($slug, '-');
        return $slug === '' ? 'movie-' . substr(bin2hex(random_bytes(4)), 0, 8) : $slug;
    }

    /** @param array<int, string> $genres */
    private static function attachGenres(int $movieId, array $genres): void
    {
        foreach ($genres as $name) {
            $name = trim($name);
            if ($name === '') {
                continue;
            }
            $slug = self::slugify($name);
            $category = Database::first('SELECT id FROM categories WHERE name_fa = ? OR slug = ? LIMIT 1', [$name, $slug]);
            if ($category === null) {
                $categoryId = Database::insert(
                    'INSERT INTO categories (slug, name_fa, name_en) VALUES (?, ?, \'\')',
                    [$slug, $name],
                );
            } else {
                $categoryId = (int) $category['id'];
            }
            Database::execute(
                'INSERT IGNORE INTO movie_categories (movie_id, category_id) VALUES (?, ?)',
                [$movieId, $categoryId],
            );
        }
    }

    public static function present(array $row): array
    {
        $genres = array_values(array_filter(
            array_map('trim', explode(',', (string) ($row['genres'] ?? ''))),
        ));

        return [
            'id' => (int) $row['id'],
            'slug' => (string) $row['slug'],
            'title_fa' => (string) $row['title_fa'],
            'title_en' => (string) $row['title_en'],
            'synopsis_fa' => (string) ($row['synopsis_fa'] ?? ''),
            'director' => (string) ($row['director'] ?? ''),
            'year' => (int) ($row['year'] ?? 0),
            'duration_seconds' => (int) ($row['duration_seconds'] ?? 0),
            'imdb_rating' => $row['imdb_rating'] === null ? null : (float) $row['imdb_rating'],
            'rt_rating' => $row['rt_rating'] === null ? null : (int) $row['rt_rating'],
            'cover_url' => (string) ($row['cover_url'] ?? ''),
            'backdrop_url' => (string) ($row['backdrop_url'] ?? ''),
            'trailer_url' => (string) ($row['trailer_url'] ?? ''),
            'status' => (string) ($row['status'] ?? 'published'),
            'genres' => $genres,
            'screening_count' => isset($row['screening_count']) ? (int) $row['screening_count'] : null,
        ];
    }

    public static function utc(string $value): DateTimeImmutable
    {
        return new DateTimeImmutable($value, new DateTimeZone('UTC'));
    }

    public static function jalaliLabel(string $utc): string
    {
        return Jalali::format(self::utc($utc));
    }
}
