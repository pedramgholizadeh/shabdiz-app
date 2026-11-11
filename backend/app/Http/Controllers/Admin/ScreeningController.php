<?php

declare(strict_types=1);

namespace Shabdiz\Http\Controllers\Admin;

use Shabdiz\Core\Auth;
use Shabdiz\Core\Database;
use Shabdiz\Core\Flash;
use Shabdiz\Core\Response;
use Shabdiz\Core\View;
use Shabdiz\Repositories\ScreeningRepository;
use Shabdiz\Support\Jalali;

final class ScreeningController
{
    public static function index(): void
    {
        Auth::requireAdmin();
        View::render('admin/screenings/index', [
            'title' => 'سانس‌های پخش',
            'screenings' => ScreeningRepository::listAdmin(),
        ]);
    }

    public static function create(): void
    {
        Auth::requireAdmin();
        View::render('admin/screenings/new', [
            'title' => 'افزودن سانس',
            'movies' => Database::select('SELECT id, title_fa, title_en, duration_seconds FROM movies ORDER BY title_fa'),
        ]);
    }

    public static function store(): void
    {
        Auth::requireAdmin();
        Auth::assertCsrf();

        $movieId = (int) ($_POST['movie_id'] ?? 0);
        $movie = Database::first('SELECT * FROM movies WHERE id = ?', [$movieId]);
        $date = trim((string) ($_POST['jalali_date'] ?? ''));
        $time = trim((string) ($_POST['time'] ?? ''));
        $sourceUrl = trim((string) ($_POST['source_url'] ?? ''));

        if ($movie === null) {
            Flash::set('error', 'فیلم انتخاب‌شده معتبر نیست.');
            Response::redirect(url('admin/screenings/new'));
        }
        $start = Jalali::toUtc($date, $time);
        if ($start === null) {
            Flash::set('error', 'تاریخ شمسی یا ساعت معتبر نیست. نمونه: ۱۴۰۵/۰۸/۳۰ و ۲۱:۰۰');
            Response::redirect(url('admin/screenings/new'));
        }
        if ($sourceUrl === '' || filter_var($sourceUrl, FILTER_VALIDATE_URL) === false) {
            Flash::set('error', 'لینک پخش (HTTP/HTTPS) الزامی و باید معتبر باشد.');
            Response::redirect(url('admin/screenings/new'));
        }

        $duration = (int) ($movie['duration_seconds'] ?? 0);
        if ($duration <= 0) {
            $duration = 120 * 60;
        }
        $end = $start->modify('+' . $duration . ' seconds');
        $subtitleUrl = trim((string) ($_POST['subtitle_url'] ?? ''));
        if ($subtitleUrl !== '' && filter_var($subtitleUrl, FILTER_VALIDATE_URL) === false) {
            Flash::set('error', 'لینک زیرنویس معتبر نیست.');
            Response::redirect(url('admin/screenings/new'));
        }

        ScreeningRepository::create([
            'movie_id' => $movieId,
            'room' => trim((string) ($_POST['room'] ?? 'main')) ?: 'main',
            'starts_at_utc' => $start->format('Y-m-d H:i:s'),
            'ends_at_utc' => $end->format('Y-m-d H:i:s'),
            'source_url' => $sourceUrl,
            'source_type' => trim((string) ($_POST['source_type'] ?? 'auto')) ?: 'auto',
            'subtitle_url' => $subtitleUrl,
            'subtitle_label' => trim((string) ($_POST['subtitle_label'] ?? 'فارسی')) ?: 'فارسی',
        ]);

        Flash::set('success', 'سانس پخش برای ' . $movie['title_fa'] . ' ثبت شد.');
        Response::redirect(url('admin/screenings'));
    }
}
