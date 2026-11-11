<?php

declare(strict_types=1);

namespace Shabdiz\Http\Controllers\Admin;

use Shabdiz\Core\Auth;
use Shabdiz\Core\Flash;
use Shabdiz\Core\Request;
use Shabdiz\Core\Response;
use Shabdiz\Core\View;

final class AuthController
{
    public static function showLogin(): void
    {
        if (Auth::admin() !== null) {
            Response::redirect(url('admin'));
        }
        View::render('admin/login', ['title' => 'ورود مدیر']);
    }

    public static function login(): void
    {
        Auth::assertCsrf();
        $email = strtolower(trim((string) ($_POST['email'] ?? '')));
        $password = (string) ($_POST['password'] ?? '');

        if (!Auth::attempt($email, $password)) {
            Flash::set('error', 'ایمیل یا رمز عبور اشتباه است.');
            Response::redirect(url('admin/login'));
        }

        Response::redirect(url('admin'));
    }

    public static function logout(): void
    {
        Auth::assertCsrf();
        Auth::logout();
        Flash::set('success', 'از پنل خارج شدید.');
        Response::redirect(url('admin/login'));
    }
}
