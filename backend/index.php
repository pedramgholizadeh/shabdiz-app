<?php
/**
 * Shabdiz — shared-hosting entry point.
 *
 * When the backend folder is uploaded as a subdirectory (e.g.
 * apps.webirox.ir/shabdiz), this file sits next to public/ and the local
 * .htaccess routes every request here. It simply forwards to the real
 * front controller in public/index.php.
 */

declare(strict_types=1);

require __DIR__ . '/public/index.php';
