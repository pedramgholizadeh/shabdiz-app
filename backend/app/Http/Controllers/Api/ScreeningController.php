<?php

declare(strict_types=1);

namespace Shabdiz\Http\Controllers\Api;

use Shabdiz\Core\Auth;
use Shabdiz\Core\Request;
use Shabdiz\Core\Response;
use Shabdiz\Repositories\PlaybackRepository;
use Shabdiz\Repositories\ScreeningRepository;
use Shabdiz\Support\Jalali;

final class ScreeningController
{
    /** @param array<string, string> $params */
    public static function join(array $params): void
    {
        $user = Auth::requireApiUser();
        $screening = self::screeningOrFail((int) ($params['id'] ?? 0));
        $state = ScreeningRepository::playbackState($screening);

        if ($state['status'] === 'upcoming') {
            Response::error(
                'این سانس هنوز شروع نشده است. ' . Jalali::format($state['starts_at']),
                409,
                'not_started',
            );
        }
        if ($state['status'] === 'ended') {
            Response::error('این سانس به پایان رسیده است.', 410, 'ended');
        }
        if (trim((string) $screening['source_url']) === '') {
            Response::error('لینک پخش این سانس هنوز تنظیم نشده است.', 503, 'source_missing');
        }

        $session = PlaybackRepository::join(
            (int) $user['id'],
            (int) $screening['screening_id'],
            Request::ip(),
            (string) ($_SERVER['HTTP_USER_AGENT'] ?? ''),
        );

        Response::ok([
            'session_id' => (string) ($session['public_id'] ?? ''),
            'movie_title_fa' => (string) $screening['title_fa'],
            'source_url' => (string) $screening['source_url'],
            'subtitle_url' => (string) $screening['subtitle_url'],
            'subtitle_label' => (string) ($screening['subtitle_label'] ?: 'زیرنویس'),
            'position_seconds' => $state['position_seconds'],
            'is_live' => true,
            'server_time' => gmdate('c'),
        ]);
    }

    /** @param array<string, string> $params */
    public static function timeline(array $params): void
    {
        Auth::requireApiUser();
        $screening = self::screeningOrFail((int) ($params['id'] ?? 0));
        $state = ScreeningRepository::playbackState($screening);

        Response::ok([
            'position_seconds' => $state['position_seconds'],
            'is_live' => $state['status'] === 'live',
            'status' => $state['status'],
            'server_time' => gmdate('c'),
        ]);
    }

    /** @param array<string, string> $params */
    public static function heartbeat(array $params): void
    {
        $user = Auth::requireApiUser();
        $screening = self::screeningOrFail((int) ($params['id'] ?? 0));
        PlaybackRepository::heartbeat((int) $user['id'], (int) $screening['screening_id']);
        Response::ok(['alive' => true]);
    }

    private static function screeningOrFail(int $id): array
    {
        $screening = $id > 0 ? ScreeningRepository::find($id) : null;
        if ($screening === null || (int) $screening['is_active'] !== 1) {
            Response::error('سانس مورد نظر پیدا نشد.', 404, 'not_found');
        }
        return $screening;
    }
}
