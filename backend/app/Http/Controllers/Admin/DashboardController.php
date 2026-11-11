<?php

declare(strict_types=1);

namespace Shabdiz\Http\Controllers\Admin;

use DateTimeImmutable;
use DateTimeZone;
use Shabdiz\Core\Auth;
use Shabdiz\Core\View;
use Shabdiz\Repositories\MovieRepository;
use Shabdiz\Repositories\ScreeningRepository;
use Shabdiz\Repositories\UserRepository;
use Shabdiz\Support\Jalali;

final class DashboardController
{
    public static function index(): void
    {
        $admin = Auth::requireAdmin();
        $next = ScreeningRepository::next();
        $nextLabel = null;
        if ($next !== null) {
            $nextLabel = Jalali::format(new DateTimeImmutable($next['starts_at_utc'], new DateTimeZone('UTC')));
        }

        View::render('admin/dashboard', [
            'title' => 'داشبورد',
            'admin' => $admin,
            'stats' => [
                'movies' => MovieRepository::count(),
                'screenings' => ScreeningRepository::count(),
                'users' => UserRepository::count(),
            ],
            'nextScreening' => $next,
            'nextLabel' => $nextLabel,
        ]);
    }
}
