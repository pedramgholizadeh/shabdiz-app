<?php

declare(strict_types=1);

namespace Shabdiz\Http\Controllers\Admin;

use Shabdiz\Core\Auth;
use Shabdiz\Core\Flash;
use Shabdiz\Core\Response;
use Shabdiz\Core\View;
use Shabdiz\Repositories\MovieRepository;

final class MovieController
{
    public static function index(): void
    {
        Auth::requireAdmin();
        View::render('admin/movies/index', [
            'title' => 'فیلم‌ها',
            'movies' => MovieRepository::listAdmin(),
        ]);
    }

    public static function create(): void
    {
        Auth::requireAdmin();
        View::render('admin/movies/new', [
            'title' => 'افزودن فیلم',
            'categories' => MovieRepository::categories(),
        ]);
    }

    public static function store(): void
    {
        Auth::requireAdmin();
        Auth::assertCsrf();

        $titleFa = trim((string) ($_POST['title_fa'] ?? ''));
        $titleEn = trim((string) ($_POST['title_en'] ?? ''));
        if ($titleFa === '') {
            Flash::set('error', 'نام فارسی فیلم الزامی است.');
            Response::redirect(url('admin/movies/new'));
        }

        $baseSlug = MovieRepository::slugify($titleEn !== '' ? $titleEn : $titleFa);
        $slug = $baseSlug;
        $suffix = 2;
        while (!MovieRepository::slugAvailable($slug)) {
            $slug = $baseSlug . '-' . $suffix++;
        }

        $durationMinutes = max(0, (int) ($_POST['duration_minutes'] ?? 0));
        $imdb = trim((string) ($_POST['imdb_rating'] ?? ''));
        $rt = trim((string) ($_POST['rt_rating'] ?? ''));
        $genres = preg_split('/[,،]+/', (string) ($_POST['genres'] ?? '')) ?: [];

        MovieRepository::create([
            'slug' => $slug,
            'title_fa' => $titleFa,
            'title_en' => $titleEn,
            'synopsis_fa' => trim((string) ($_POST['synopsis_fa'] ?? '')),
            'director' => trim((string) ($_POST['director'] ?? '')),
            'year' => max(0, (int) ($_POST['year'] ?? 0)),
            'duration_seconds' => $durationMinutes * 60,
            'imdb_rating' => $imdb === '' ? null : max(0, min(10, (float) $imdb)),
            'rt_rating' => $rt === '' ? null : max(0, min(100, (int) $rt)),
            'cover_url' => trim((string) ($_POST['cover_url'] ?? '')),
            'backdrop_url' => trim((string) ($_POST['backdrop_url'] ?? '')),
            'trailer_url' => trim((string) ($_POST['trailer_url'] ?? '')),
            'status' => ($_POST['status'] ?? 'published') === 'draft' ? 'draft' : 'published',
        ], $genres);

        Flash::set('success', 'فیلم با موفقیت ثبت شد.');
        Response::redirect(url('admin/movies'));
    }
}
