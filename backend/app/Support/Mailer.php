<?php

declare(strict_types=1);

namespace Shabdiz\Support;

use Shabdiz\Core\Config;
use Shabdiz\Core\Env;

final class Mailer
{
    public static function sendOtp(string $email, string $code): bool
    {
        $driver = Config::get('MAIL_DRIVER', 'log');
        $from = Config::get('MAIL_FROM', 'no-reply@webiro.ir');
        $subject = 'کد ورود به شب‌دیز';
        $body = "کد ورود شما به شب‌دیز:\n\n{$code}\n\n"
            . "این کد تا " . Env::get('OTP_TTL_SECONDS', '300') . " ثانیه معتبر است.\n"
            . "اگر این درخواست را شما ارسال نکرده‌اید، این ایمیل را نادیده بگیرید.";

        if ($driver === 'log') {
            $line = sprintf(
                "[%s] to=%s subject=%s code=%s\n",
                gmdate('Y-m-d H:i:s'),
                $email,
                $subject,
                $code,
            );
            @file_put_contents(SHABDIZ_ROOT . '/storage/logs/mail.log', $line, FILE_APPEND);
            return true;
        }

        $headers = [
            'From: ShabDiz <' . $from . '>',
            'MIME-Version: 1.0',
            'Content-Type: text/plain; charset=UTF-8',
            'Content-Transfer-Encoding: 8bit',
        ];

        return @mail($email, '=?UTF-8?B?' . base64_encode($subject) . '?=', $body, implode("\r\n", $headers));
    }
}
