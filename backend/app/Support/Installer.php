<?php

declare(strict_types=1);

namespace Shabdiz\Support;

use PDO;
use Shabdiz\Core\Config;
use Shabdiz\Core\Database;
use Throwable;

final class Installer
{
    /** @return array{ok: bool, out: array<int, string>} */
    public static function run(): array
    {
        $out = [];

        foreach (['storage', 'storage/logs', 'storage/cache', 'public/uploads'] as $dir) {
            $path = SHABDIZ_ROOT . '/' . $dir;
            if (!is_dir($path) && !@mkdir($path, 0755, true) && !is_dir($path)) {
                $out[] = 'FAIL mkdir ' . $dir;
            } else {
                $out[] = 'ok ' . $dir;
            }
        }

        $uploadGuard = "<FilesMatch \"\\.(php|phtml|phar|cgi|pl|py|sh)$\">\n    Require all denied\n</FilesMatch>\n";
        foreach (['storage/.htaccess', 'public/uploads/.htaccess'] as $file) {
            $path = SHABDIZ_ROOT . '/' . $file;
            if (!is_file($path)) {
                @file_put_contents($path, $uploadGuard);
            }
        }

        $pdo = Database::connection();
        $pdo->exec(
            'CREATE TABLE IF NOT EXISTS schema_migrations (
                version VARCHAR(128) NOT NULL PRIMARY KEY,
                applied_at DATETIME NOT NULL
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4'
        );

        $applied = $pdo->query('SELECT version FROM schema_migrations')->fetchAll(PDO::FETCH_COLUMN);
        foreach (glob(SHABDIZ_ROOT . '/migrations/*.sql') ?: [] as $file) {
            $version = basename($file);
            if (in_array($version, $applied, true)) {
                continue;
            }
            $sql = (string) file_get_contents($file);
            $statements = preg_split('/;\s*(?:\r?\n|$)/', $sql) ?: [];
            foreach ($statements as $statement) {
                $statement = trim(preg_replace('/^\s*(--|#).*$/m', '', $statement) ?? '');
                if ($statement === '') {
                    continue;
                }
                $pdo->exec($statement);
            }
            $pdo->prepare('INSERT INTO schema_migrations (version, applied_at) VALUES (?, UTC_TIMESTAMP())')
                ->execute([$version]);
            $out[] = 'migrated ' . $version;
        }

        $email = Config::get('ADMIN_EMAIL');
        $hash = Config::get('ADMIN_PASSWORD_HASH');
        if ($email !== null && $hash !== null) {
            $exists = Database::first('SELECT id FROM admins WHERE email = ?', [$email]);
            if ($exists === null) {
                Database::insert(
                    'INSERT INTO admins (name, email, password_hash, created_at) VALUES (?, ?, ?, UTC_TIMESTAMP())',
                    [Config::get('ADMIN_NAME', 'مدیر شب‌دیز'), $email, $hash],
                );
                $out[] = 'admin created: ' . $email;
            } else {
                $out[] = 'ok admin exists';
            }
        } else {
            $out[] = 'skip admin (ADMIN_EMAIL / ADMIN_PASSWORD_HASH missing)';
        }

        $out[] = 'php=' . PHP_VERSION;
        $out[] = 'pdo_mysql=' . (in_array('mysql', PDO::getAvailableDrivers(), true) ? 'yes' : 'NO');
        $out[] = 'writable storage=' . (is_writable(SHABDIZ_ROOT . '/storage') ? 'yes' : 'NO');
        $out[] = 'writable uploads=' . (is_writable(SHABDIZ_ROOT . '/public/uploads') ? 'yes' : 'NO');

        try {
            @file_put_contents(SHABDIZ_ROOT . '/storage/install.lock', gmdate('c'));
        } catch (Throwable) {
            // A read-only storage lock is non-fatal.
        }

        return ['ok' => true, 'out' => $out];
    }
}
