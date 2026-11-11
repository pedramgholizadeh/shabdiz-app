<?php

declare(strict_types=1);

namespace Shabdiz\Http\Controllers\Api;

use Shabdiz\Core\Auth;
use Shabdiz\Core\Config;
use Shabdiz\Core\Request;
use Shabdiz\Core\Response;
use Shabdiz\Repositories\OtpRepository;
use Shabdiz\Repositories\UserRepository;
use Shabdiz\Support\Mailer;

final class AuthController
{
    public static function requestOtp(): void
    {
        $email = strtolower(trim((string) Request::input('email', '')));
        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            Response::error('ایمیل وارد شده معتبر نیست.', 422, 'validation_error');
        }
        if (OtpRepository::recentExists($email, 60)) {
            Response::error('کد قبلی هنوز معتبر است؛ کمی بعد دوباره تلاش کنید.', 429, 'rate_limited');
        }

        $ttl = max(60, min(900, Config::int('OTP_TTL_SECONDS', 300)));
        $code = (string) random_int(100000, 999999);
        $secret = (string) Config::get('APP_KEY', '');
        $hash = hash_hmac('sha256', $code, $secret);

        OtpRepository::create($email, $hash, $ttl, Request::ip());
        if (!Mailer::sendOtp($email, $code)) {
            Response::error('ارسال ایمیل ممکن نشد. لطفاً بعداً تلاش کنید.', 503, 'mail_failed');
        }

        Response::ok([
            'sent' => true,
            'expires_in' => $ttl,
        ]);
    }

    public static function verifyOtp(): void
    {
        $email = strtolower(trim((string) Request::input('email', '')));
        $code = trim((string) Request::input('code', ''));

        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false || preg_match('/^\d{6}$/', $code) !== 1) {
            Response::error('ایمیل یا کد وارد شده معتبر نیست.', 422, 'validation_error');
        }

        $record = OtpRepository::latestValid($email);
        if ($record === null) {
            Response::error('کد منقضی شده یا معتبر نیست. کد جدید بگیرید.', 422, 'invalid_code');
        }

        OtpRepository::incrementAttempts((int) $record['id']);
        $secret = (string) Config::get('APP_KEY', '');
        $expected = hash_hmac('sha256', $code, $secret);
        if (!hash_equals((string) $record['code_hash'], $expected)) {
            Response::error('کد وارد شده درست نیست.', 422, 'invalid_code');
        }

        OtpRepository::consume((int) $record['id']);
        $user = UserRepository::findOrCreate($email);
        $token = Auth::issueToken((int) $user['id']);

        Response::ok([
            'token' => $token,
            'user' => UserRepository::publicPayload($user),
        ]);
    }

    public static function me(): void
    {
        $user = Auth::requireApiUser();
        Response::ok(['user' => UserRepository::publicPayload($user)]);
    }
}
