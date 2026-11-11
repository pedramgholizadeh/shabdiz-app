<?php

declare(strict_types=1);

namespace Shabdiz\Support;

use Shabdiz\Core\Config;
use Shabdiz\Core\Env;

final class Mailer
{
    /**
     * Delivery chains by MAIL_DRIVER:
     *  - resend (production default): Resend API → host SMTP → PHP mail()
     *  - smtp: host SMTP → PHP mail()
     *  - mail: PHP mail() only
     *  - log / unknown: staging log (the only channel that ever stores the code)
     */
    public static function sendOtp(string $email, string $code): bool
    {
        $from = Config::get('MAIL_FROM', 'no-reply@webiro.ir');
        $subject = 'کد ورود به شب‌دیز';
        $body = "کد ورود شما به شب‌دیز:\n\n{$code}\n\n"
            . "این کد تا " . Env::get('OTP_TTL_SECONDS', '300') . " ثانیه معتبر است.\n"
            . "اگر این درخواست را شما ارسال نکرده‌اید، این ایمیل را نادیده بگیرید.";

        $driver = Config::get('MAIL_DRIVER', 'log');

        if ($driver === 'log') {
            self::logLine(sprintf(
                '[%s] to=%s subject=%s code=%s',
                gmdate('Y-m-d H:i:s'),
                $email,
                $subject,
                $code,
            ));
            return true;
        }
        if ($driver === 'mail') {
            return self::sendViaMail($email, $from, $subject, $body);
        }

        $channels = $driver === 'smtp'
            ? ['smtp', 'mail']
            : ['resend', 'smtp', 'mail'];

        foreach ($channels as $channel) {
            $sent = match ($channel) {
                'resend' => self::sendViaResend($email, $from, $subject, $body),
                'smtp' => self::sendViaSmtp($email, $from, $subject, $body),
                'mail' => self::sendViaMail($email, $from, $subject, $body),
            };
            self::logLine(sprintf('[%s] channel=%s to=%s ok=%d', gmdate('Y-m-d H:i:s'), $channel, $email, $sent ? 1 : 0));
            if ($sent) {
                return true;
            }
        }
        return false;
    }

    private static function sendViaResend(string $email, string $from, string $subject, string $body): bool
    {
        $key = trim((string) Config::get('RESEND_API_KEY', ''));
        if ($key === '') {
            return false;
        }
        $payload = json_encode([
            'from' => 'ShabDiz <' . $from . '>',
            'to' => [$email],
            'subject' => $subject,
            'text' => $body,
        ], JSON_UNESCAPED_UNICODE);
        if ($payload === false) {
            return false;
        }
        [$status] = self::httpPostJson('https://api.resend.com/emails', $key, $payload);
        return $status >= 200 && $status < 300;
    }

    private static function sendViaSmtp(string $email, string $from, string $subject, string $body): bool
    {
        $host = trim((string) Config::get('SMTP_HOST', ''));
        if ($host === '') {
            return false;
        }
        $ehloDomain = parse_url(Config::baseUrl(), PHP_URL_HOST);
        return Smtp::send(
            $host,
            max(1, min(65535, Config::int('SMTP_PORT', 587))),
            Config::get('SMTP_ENCRYPTION', 'tls'),
            (string) Config::get('SMTP_USER', ''),
            (string) Config::get('SMTP_PASS', ''),
            is_string($ehloDomain) && $ehloDomain !== '' ? $ehloDomain : 'localhost',
            $from,
            $email,
            $subject,
            $body,
        );
    }

    private static function sendViaMail(string $email, string $from, string $subject, string $body): bool
    {
        $headers = [
            'From: ShabDiz <' . $from . '>',
            'MIME-Version: 1.0',
            'Content-Type: text/plain; charset=UTF-8',
            'Content-Transfer-Encoding: 8bit',
        ];

        return @mail($email, '=?UTF-8?B?' . base64_encode($subject) . '?=', $body, implode("\r\n", $headers));
    }

    /**
     * @return array{0: int, 1: string} HTTP status and body
     */
    private static function httpPostJson(string $url, string $token, string $payload): array
    {
        if (function_exists('curl_init')) {
            $handle = curl_init($url);
            curl_setopt_array($handle, [
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => $payload,
                CURLOPT_HTTPHEADER => [
                    'Authorization: Bearer ' . $token,
                    'Content-Type: application/json',
                ],
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_CONNECTTIMEOUT => 5,
                CURLOPT_TIMEOUT => 10,
            ]);
            curl_exec($handle);
            $status = (int) curl_getinfo($handle, CURLINFO_HTTP_CODE);
            curl_close($handle);
            return [$status, ''];
        }

        $context = stream_context_create(['http' => [
            'method' => 'POST',
            'header' => "Authorization: Bearer {$token}\r\nContent-Type: application/json\r\n",
            'content' => $payload,
            'ignore_errors' => true,
            'timeout' => 10,
        ]]);
        $body = @file_get_contents($url, false, $context);
        $status = 0;
        foreach ($http_response_header ?? [] as $header) {
            if (preg_match('#^HTTP/\S+\s+(\d{3})#', $header, $matches) === 1) {
                $status = (int) $matches[1];
            }
        }
        return [$status, is_string($body) ? $body : ''];
    }

    private static function logLine(string $line): void
    {
        @file_put_contents(SHABDIZ_ROOT . '/storage/logs/mail.log', $line . "\n", FILE_APPEND);
    }
}
