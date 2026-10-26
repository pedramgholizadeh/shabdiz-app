<?php
/**
 * Shabdiz — Backend Configuration
 * Copy this file to config.php and fill in real values.
 * config.php is git-ignored.
 */

return [
    // Secret string used to sign auth tokens (generate: php -r "echo bin2hex(random_bytes(32));")
    'app_secret' => getenv('SHABDIZ_APP_SECRET') ?: 'CHANGE-ME-IN-PRODUCTION',

    // Where the API is deployed (used in emails)
    'app_url' => 'https://apps.webirox.ir/shabdiz',

    // SQLite database file path (must be writable by PHP)
    'db_path' => __DIR__ . '/data/shabdiz.sqlite',

    // Upstream content API — the key NEVER leaves the server
    'upstream' => [
        'base_url' => 'https://server-hi-speed-iran.info/api',
        'api_key'  => getenv('SHABDIZ_UPSTREAM_KEY') ?: '4F5A9C3D9A86FA54EACEDDD635185',
        'helper_servers' => [
            'https://hostinnegar.com',
            'https://windowsdiba.info',
        ],
        'timeout' => 15,
    ],

    // Resend (https://resend.com) — email delivery of OTP codes
    'resend' => [
        'api_key' => getenv('RESEND_API_KEY') ?: '',
        'from'    => 'Shabdiz <no-reply@webiro.ir>',
    ],

    // Admin panel — access at /admin. Generate: php -r "echo password_hash('YOUR-PASSWORD', PASSWORD_DEFAULT);"
    'admin_password_hash' => getenv('SHABDIZ_ADMIN_HASH') ?: '',
    'admin_secret'        => getenv('SHABDIZ_ADMIN_SECRET') ?: 'CHANGE-ME-ADMIN-SESSION',

    'otp' => [
        'ttl_seconds'    => 300,      // code valid for 5 minutes
        'length'         => 6,
        'max_attempts'   => 5,        // per code
        'resend_seconds' => 60,       // cooldown between requests
    ],

    'cors_origins' => ['*'], // tighten in production
];
