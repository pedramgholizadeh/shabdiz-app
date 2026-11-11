#!/usr/bin/env php
<?php

declare(strict_types=1);

use Shabdiz\Support\Installer;

require dirname(__DIR__) . '/app/bootstrap.php';

if (PHP_SAPI !== 'cli' && ($_GET['token'] ?? '') !== '') {
    http_response_code(403);
    exit('CLI only.');
}

header('Content-Type: text/plain; charset=utf-8');
$result = Installer::run();
echo ($result['ok'] ? "OK\n" : "FAIL\n") . implode("\n", $result['out']) . "\n";
