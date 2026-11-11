<?php

declare(strict_types=1);

namespace Shabdiz\Http\Controllers\Api;

use Shabdiz\Core\Response;
use Shabdiz\Repositories\MovieRepository;
use Shabdiz\Repositories\ScreeningRepository;

final class MovieController
{
    public static function timeline(): void
    {
        Response::ok(['items' => MovieRepository::timeline()]);
    }

    /** @param array<string, string> $params */
    public static function show(array $params): void
    {
        $slug = rawurldecode($params['slug'] ?? '');
        $movie = MovieRepository::findBySlug($slug);
        if ($movie === null) {
            Response::error('فیلم پیدا نشد.', 404, 'not_found');
        }

        Response::ok([
            'movie' => $movie,
            'screenings' => ScreeningRepository::forMovie((int) $movie['id']),
        ]);
    }
}
