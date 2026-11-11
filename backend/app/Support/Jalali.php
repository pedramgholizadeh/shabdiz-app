<?php

declare(strict_types=1);

namespace Shabdiz\Support;

use DateTimeImmutable;
use DateTimeZone;

final class Jalali
{
    private const MONTHS = [
        1 => 'فروردین',
        'اردیبهشت',
        'خرداد',
        'تیر',
        'مرداد',
        'شهریور',
        'مهر',
        'آبان',
        'آذر',
        'دی',
        'بهمن',
        'اسفند',
    ];

    private const WEEKDAYS = [
        0 => 'یکشنبه',
        'دوشنبه',
        'سه‌شنبه',
        'چهارشنبه',
        'پنجشنبه',
        'جمعه',
        'شنبه',
    ];

    /** @return array{0: int, 1: int, 2: int} */
    public static function fromGregorian(int $gy, int $gm, int $gd): array
    {
        $gDaysInMonth = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
        $gy2 = $gm > 2 ? $gy + 1 : $gy;
        $days = 355666 + (365 * $gy) + intdiv($gy2 + 3, 4) - intdiv($gy2 + 99, 100)
            + intdiv($gy2 + 399, 400) + $gd + $gDaysInMonth[$gm - 1];
        $jy = -1595 + (33 * intdiv($days, 12053));
        $days %= 12053;
        $jy += 4 * intdiv($days, 1461);
        $days %= 1461;
        if ($days > 365) {
            $jy += intdiv($days - 1, 365);
            $days = ($days - 1) % 365;
        }
        if ($days < 186) {
            $jm = 1 + intdiv($days, 31);
            $jd = 1 + ($days % 31);
        } else {
            $jm = 7 + intdiv($days - 186, 30);
            $jd = 1 + (($days - 186) % 30);
        }
        return [$jy, $jm, $jd];
    }

    /** @return array{0: int, 1: int, 2: int} */
    public static function toGregorian(int $jy, int $jm, int $jd): array
    {
        $jy += 1595;
        $days = -355668 + (365 * $jy) + (intdiv($jy, 33) * 8) + intdiv(($jy % 33) + 3, 4)
            + $jd + ($jm < 7 ? ($jm - 1) * 31 : (($jm - 7) * 30) + 186);
        $gy = 400 * intdiv($days, 146097);
        $days %= 146097;
        if ($days > 36524) {
            --$days;
            $gy += 100 * intdiv($days, 36524);
            $days %= 36524;
            if ($days >= 365) {
                ++$days;
            }
        }
        $gy += 4 * intdiv($days, 1461);
        $days %= 1461;
        if ($days > 365) {
            $gy += intdiv($days - 1, 365);
            $days = ($days - 1) % 365;
        }
        $gd = $days + 1;
        $leap = ($gy % 4 === 0 && $gy % 100 !== 0) || ($gy % 400 === 0);
        $monthDays = [0, 31, $leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
        $gm = 0;
        while ($gm < 12 && $gd > $monthDays[$gm + 1]) {
            ++$gm;
            $gd -= $monthDays[$gm];
        }
        return [$gy, $gm + 1, $gd];
    }

    public static function parseDate(string $value): ?array
    {
        $normalized = str_replace(['-', '.'], '/', trim($value));
        if (preg_match('#^(\d{4})/(\d{1,2})/(\d{1,2})$#', $normalized, $m) !== 1) {
            return null;
        }
        $month = (int) $m[2];
        $day = (int) $m[3];
        if ($month < 1 || $month > 12 || $day < 1 || $day > 31) {
            return null;
        }
        return [(int) $m[1], $month, $day];
    }

    public static function toUtc(string $jalaliDate, string $time): ?DateTimeImmutable
    {
        $date = self::parseDate($jalaliDate);
        if ($date === null || preg_match('#^([01]?\d|2[0-3]):([0-5]\d)$#', trim($time), $m) !== 1) {
            return null;
        }
        [$gy, $gm, $gd] = self::toGregorian(...$date);
        $tehran = new DateTimeZone('Asia/Tehran');
        $moment = DateTimeImmutable::createFromFormat(
            'Y-n-j G:i',
            sprintf('%d-%d-%d %d:%s', $gy, $gm, $gd, (int) $m[1], $m[2]),
            $tehran,
        );
        if ($moment === false) {
            return null;
        }
        return $moment->setTimezone(new DateTimeZone('UTC'));
    }

    public static function format(DateTimeImmutable $utc, string $format = 'full'): string
    {
        $local = $utc->setTimezone(new DateTimeZone('Asia/Tehran'));
        [$jy, $jm, $jd] = self::fromGregorian(
            (int) $local->format('Y'),
            (int) $local->format('n'),
            (int) $local->format('j'),
        );
        $weekday = self::WEEKDAYS[(int) $local->format('w')] ?? '';
        $time = $local->format('H:i');
        $digits = static fn (string $value): string => fa_num($value);

        if ($format === 'clock') {
            return $digits($time);
        }
        if ($format === 'date') {
            return $digits(sprintf('%04d/%02d/%02d', $jy, $jm, $jd));
        }
        if ($format === 'short') {
            return $weekday . ' ' . $digits((string) $jd) . ' ' . self::MONTHS[$jm];
        }
        return $weekday . ' ' . $digits((string) $jd) . ' ' . self::MONTHS[$jm]
            . ' · ' . $digits($time);
    }

    public static function status(DateTimeImmutable $startsUtc, DateTimeImmutable $endsUtc, ?DateTimeImmutable $now = null): string
    {
        $now ??= new DateTimeImmutable('now', new DateTimeZone('UTC'));
        if ($now < $startsUtc) {
            return 'upcoming';
        }
        if ($now >= $endsUtc) {
            return 'ended';
        }
        return 'live';
    }
}
