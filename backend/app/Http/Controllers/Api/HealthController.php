<?php

declare(strict_types=1);

namespace Shabdiz\Http\Controllers\Api;

use Shabdiz\Core\Database;
use Shabdiz\Core\Response;
use Throwable;

final class HealthController
{
    public static function index(): void
    {
        $db = false;
        try {
            Database::connection()->query('SELECT 1');
            $db = true;
        } catch (Throwable) {
            $db = false;
        }

        Response::ok([
            'service' => 'shabdiz-api',
            'version' => '0.1.0',
            'database' => $db,
            'time' => gmdate('c'),
        ]);
    }
}
