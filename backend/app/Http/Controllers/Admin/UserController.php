<?php

declare(strict_types=1);

namespace Shabdiz\Http\Controllers\Admin;

use Shabdiz\Core\Auth;
use Shabdiz\Core\View;
use Shabdiz\Repositories\UserRepository;

final class UserController
{
    public static function index(): void
    {
        Auth::requireAdmin();
        View::render('admin/users/index', [
            'title' => 'کاربران',
            'users' => UserRepository::paginate(),
        ]);
    }
}
