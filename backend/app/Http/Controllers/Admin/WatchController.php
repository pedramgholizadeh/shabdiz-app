<?php

declare(strict_types=1);

namespace Shabdiz\Http\Controllers\Admin;

use Shabdiz\Core\Auth;
use Shabdiz\Core\View;
use Shabdiz\Repositories\WatchProgressRepository;

final class WatchController
{
    public static function index(): void
    {
        Auth::requireAdmin();
        View::render('admin/watching/index', [
            'title' => 'تماشاها',
            'rows' => WatchProgressRepository::adminList(),
        ]);
    }
}
