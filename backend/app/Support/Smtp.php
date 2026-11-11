<?php

declare(strict_types=1);

namespace Shabdiz\Support;

/**
 * Minimal SMTP client for authenticated host relays. The project has no
 * Composer dependencies, so the protocol is implemented directly over
 * stream sockets: EHLO, optional STARTTLS/implicit SSL, AUTH LOGIN, DATA.
 */
final class Smtp
{
    /**
     * @param string $encryption 'tls' (STARTTLS), 'ssl' (implicit) or 'none'
     */
    public static function send(
        string $host,
        int $port,
        string $encryption,
        string $username,
        string $password,
        string $ehloDomain,
        string $from,
        string $to,
        string $subject,
        string $body,
    ): bool {
        $transport = $encryption === 'ssl' ? 'ssl' : 'tcp';
        $socket = @stream_socket_client(
            sprintf('%s://%s:%d', $transport, $host, $port),
            $errno,
            $errstr,
            10,
        );
        if ($socket === false) {
            return false;
        }
        stream_set_timeout($socket, 10);

        try {
            if (!self::expect($socket, '220')) {
                return false;
            }
            if (!self::command($socket, 'EHLO ' . $ehloDomain, '250')) {
                return false;
            }
            if ($encryption === 'tls') {
                if (!self::command($socket, 'STARTTLS', '220')) {
                    return false;
                }
                if (@stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLS_CLIENT) !== true) {
                    return false;
                }
                if (!self::command($socket, 'EHLO ' . $ehloDomain, '250')) {
                    return false;
                }
            }
            if ($username !== '') {
                if (!self::command($socket, 'AUTH LOGIN', '334')
                    || !self::command($socket, base64_encode($username), '334')
                    || !self::command($socket, base64_encode($password), '235')) {
                    return false;
                }
            }
            if (!self::command($socket, 'MAIL FROM:<' . $from . '>', '250')
                || !self::command($socket, 'RCPT TO:<' . $to . '>', ['250', '251'])
                || !self::command($socket, 'DATA', '354')) {
                return false;
            }

            $headers = 'From: =?UTF-8?B?' . base64_encode('ShabDiz') . "?= <{$from}>\r\n"
                . "To: <{$to}>\r\n"
                . 'Subject: =?UTF-8?B?' . base64_encode($subject) . "?=\r\n"
                . 'Date: ' . gmdate('D, d M Y H:i:s') . " +0000\r\n"
                . "MIME-Version: 1.0\r\n"
                . "Content-Type: text/plain; charset=UTF-8\r\n"
                . "Content-Transfer-Encoding: 8bit\r\n";

            fwrite($socket, $headers . "\r\n" . self::dotStuff($body) . "\r\n.\r\n");
            if (!self::expect($socket, '250')) {
                return false;
            }
            fwrite($socket, "QUIT\r\n");
            return true;
        } finally {
            fclose($socket);
        }
    }

    /** @param resource $socket */
    private static function command($socket, string $command, string|array $codes): bool
    {
        fwrite($socket, $command . "\r\n");
        return self::expect($socket, $codes);
    }

    /** @param resource $socket */
    private static function expect($socket, string|array $codes): bool
    {
        $reply = self::readReply($socket);
        foreach ((array) $codes as $code) {
            if (str_starts_with($reply, $code)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Multi-line replies keep arriving while the 4th byte is '-'.
     *
     * @param resource $socket
     */
    private static function readReply($socket): string
    {
        $reply = '';
        do {
            $line = fgets($socket, 1024);
            if ($line === false) {
                return '';
            }
            $reply .= $line;
        } while (isset($line[3]) && $line[3] === '-');
        return trim($reply);
    }

    private static function dotStuff(string $body): string
    {
        $normalized = str_replace("\r\n", "\n", $body);
        $normalized = str_replace("\n", "\r\n", $normalized);
        return (string) preg_replace('/^\./m', '..', $normalized);
    }
}
