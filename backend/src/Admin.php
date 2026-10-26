<?php

/**
 * Shabdiz web admin panel (/admin) — sessions via signed cookie.
 * Pages: login, dashboard (install reports), users, devices, logout.
 */
final class Admin
{
    public static function handle(array $segments, string $method, array $body, array $config): never
    {
        $page = $segments[0] ?? 'dashboard';

        if ($page === 'login') {
            self::login($config, $method, $body);
        }
        if ($page === 'logout') {
            setcookie('shabdiz_admin', '', time() - 3600, '/');
            header('Location: index.php?_route=/admin');
            exit;
        }

        if (!self::isAuthed($config)) {
            if (str_starts_with($_SERVER['HTTP_ACCEPT'] ?? '', 'application/json') || ($_SERVER['HTTP_X_REQUESTED_WITH'] ?? '') === 'fetch') {
                Response::json(['error' => 'unauthorized'], 401);
            }
            header('Location: index.php?_route=/admin/login');
            exit;
        }

        match ($page) {
            'dashboard' => self::dashboard($config),
            'users'     => self::users($config),
            'devices'   => self::devices($config),
            default     => self::dashboard($config),
        };
    }

    // ------------------------------------------------------------- Session

    private static function isAuthed(array $config): bool
    {
        $cookie = $_COOKIE['shabdiz_admin'] ?? '';
        if ($cookie === '') {
            return false;
        }
        $expected = hash_hmac('sha256', 'admin-session', $config['admin_secret']);
        return hash_equals($expected, $cookie);
    }

    private static function login(array $config, string $method, array $body): never
    {
        if ($method === 'POST') {
            $password = (string) ($body['password'] ?? ($_POST['password'] ?? ''));
            if (
                $config['admin_password_hash'] !== '' &&
                password_verify($password, $config['admin_password_hash'])
            ) {
                setcookie('shabdiz_admin', hash_hmac('sha256', 'admin-session', $config['admin_secret']), [
                    'expires'  => time() + 60 * 60 * 8,
                    'path'     => '/',
                    'httponly' => true,
                    'samesite' => 'Lax',
                ]);
                header('Location: index.php?_route=/admin/dashboard');
                exit;
            }
            $error = 'رمز اشتباه است.';
        }
        $errorHtml = isset($error) ? '<p style="color:#ff5a5a;font-size:13px;">' . htmlspecialchars($error) . '</p>' : '';
        $html = self::layout('ورود مدیریت', <<<HTML
<div class="card" style="max-width:420px;margin:80px auto;">
  <h1 style="margin:0 0 4px;">شبدیز</h1>
  <p class="muted">پنل مدیریت</p>
  <form method="post">
    <input type="password" name="password" placeholder="رمز مدیریت" autofocus required style="width:100%;">
    <button style="width:100%;margin-top:14px;">ورود</button>
    $errorHtml
  </form>
</div>
HTML);
        echo $html;
        exit;
    }

    // ------------------------------------------------------------- Pages

    private static function dashboard(array $config): never
    {
        $pdo = Database::pdo();
        $stats = [
            'users'    => (int) $pdo->query('SELECT COUNT(*) c FROM users')->fetch()['c'],
            'devices'  => (int) $pdo->query('SELECT COUNT(*) c FROM devices')->fetch()['c'],
            'android'  => (int) $pdo->query("SELECT COUNT(*) c FROM devices WHERE platform='android'")->fetch()['c'],
            'windows'  => (int) $pdo->query("SELECT COUNT(*) c FROM devices WHERE platform='windows'")->fetch()['c'],
            'macos'    => (int) $pdo->query("SELECT COUNT(*) c FROM devices WHERE platform='macos'")->fetch()['c'],
            'favs'     => (int) $pdo->query('SELECT COUNT(*) c FROM favorites')->fetch()['c'],
        ];
        // Installs per day (last 14 days)
        $rows = $pdo->query(
            "SELECT date(first_seen, 'unixepoch') d, COUNT(*) c FROM devices
             WHERE first_seen > strftime('%s','now','-14 days')
             GROUP BY d ORDER BY d"
        )->fetchAll();
        $max = 1;
        foreach ($rows as $r) {
            $max = max($max, (int) $r['c']);
        }
        $bars = '';
        foreach ($rows as $r) {
            $h = max(6, (int) round(120 * $r['c'] / $max));
            $bars .= "<div class='bar-wrap'><div class='bar' style='height:{$h}px' title='{$r['c']}'></div><span>" . mb_substr($r['d'], 5) . '</span></div>';
        }
        if ($bars === '') {
            $bars = '<p class="muted">هنوز نصبی ثبت نشده است.</p>';
        }

        $cards = '';
        foreach ([
            'کاربران' => $stats['users'],
            'دستگاه‌ها' => $stats['devices'],
            'اندروید' => $stats['android'],
            'ویندوز' => $stats['windows'],
            'مک' => $stats['macos'],
            'علاقه‌مندی‌ها' => $stats['favs'],
        ] as $label => $value) {
            $cards .= "<div class='card stat'><div class='num'>$value</div><div class='muted'>$label</div></div>";
        }

        echo self::layout('داشبورد', <<<HTML
<h1>داشبورد</h1>
<div class="grid">$cards</div>
<div class="card">
  <h2>نصب‌های جدید (۱۴ روز اخیر)</h2>
  <div class="chart">$bars</div>
</div>
HTML);
        exit;
    }

    private static function users(array $config): never
    {
        $rows = Database::pdo()->query(
            "SELECT u.*, COUNT(f.id) favs, COUNT(d.id) devices
             FROM users u
             LEFT JOIN favorites f ON f.user_id = u.id
             LEFT JOIN devices d ON d.user_id = u.id
             GROUP BY u.id ORDER BY u.created_at DESC LIMIT 500"
        )->fetchAll();
        $tr = '';
        foreach ($rows as $r) {
            $tr .= "<tr><td>{$r['id']}</td><td>" . htmlspecialchars($r['email']) . "</td><td>" . htmlspecialchars($r['name'] ?: '—')
                . "</td><td>{$r['favs']}</td><td>{$r['devices']}</td><td class='muted'>{$r['created_at']}</td></tr>";
        }
        echo self::layout('کاربران', <<<HTML
<h1>کاربران</h1>
<div class="card"><table>
<tr><th>#</th><th>ایمیل</th><th>نام</th><th>علاقه‌مندی</th><th>دستگاه‌ها</th><th>تاریخ عضویت</th></tr>
$tr
</table></div>
HTML);
        exit;
    }

    private static function devices(array $config): never
    {
        $rows = Database::pdo()->query(
            "SELECT d.*, u.email FROM devices d LEFT JOIN users u ON u.id = d.user_id
             ORDER BY d.last_seen DESC LIMIT 500"
        )->fetchAll();
        $tr = '';
        foreach ($rows as $r) {
            $email = $r['email'] ? htmlspecialchars($r['email']) : '<span class="muted">مهمان</span>';
            $lastSeen = date('Y-m-d H:i', (int) $r['last_seen']);
            $tr .= "<tr><td class='mono'>" . mb_substr($r['device_id'], 0, 12) . '…</td><td><span class="pill ' . $r['platform'] . '">' . $r['platform'] . '</span></td>'
                . "<td class='mono'>{$r['app_version']}</td><td class='mono'>{$r['ip']}</td><td class='mono'>{$r['country']}</td><td>$email</td><td class='muted'>$lastSeen</td></tr>";
        }
        echo self::layout('دستگاه‌ها', <<<HTML
<h1>دستگاه‌ها</h1>
<div class="card"><table>
<tr><th>شناسه</th><th>پلتفرم</th><th>نسخه</th><th>IP</th><th>کشور</th><th>کاربر</th><th>آخرین بازدید</th></tr>
$tr
</table></div>
HTML);
        exit;
    }

    // ------------------------------------------------------------- Layout

    private static function layout(string $title, string $content): string
    {
        $nav = '<nav><a href="index.php?_route=/admin/dashboard">داشبورد</a><a href="index.php?_route=/admin/users">کاربران</a><a href="index.php?_route=/admin/devices">دستگاه‌ها</a><a href="index.php?_route=/admin/logout" class="danger">خروج</a></nav>';
        return <<<HTML
<!doctype html><html dir="rtl" lang="fa"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$title — شبدیز</title>
<style>
*{box-sizing:border-box} body{margin:0;background:#07070B;color:#F5F5F7;font-family:Tahoma,Vazirmatn,sans-serif;padding:28px}
h1{font-size:24px;margin:18px 0} h2{font-size:16px;margin:0 0 16px}
nav{display:flex;gap:10px;margin-bottom:8px} nav a{color:#8E8EA0;text-decoration:none;background:#101018;padding:9px 18px;border-radius:12px;border:1px solid #23232e;font-size:13px}
nav a.danger{color:#ff5a5a} nav a:hover{color:#fff}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px}
.card{background:#101018;border:1px solid #23232e;border-radius:18px;padding:22px;margin-bottom:16px}
.card.stat{text-align:center;margin:0} .num{font-size:30px;font-weight:800}
.muted{color:#8E8EA0;font-size:12px}
table{width:100%;border-collapse:collapse;font-size:13px} th{text-align:right;color:#8E8EA0;font-weight:600;padding:8px;border-bottom:1px solid #23232e}
td{padding:9px 8px;border-bottom:1px solid #1a1a22}
.pill{padding:3px 10px;border-radius:999px;font-size:11px;background:#1c2733;color:#7cc4ff}
.pill.android{background:#1c3326;color:#6ee7a0} .pill.windows{background:#33271c;color:#ffb86e} .pill.macos{background:#2c2333;color:#c79bff}
.mono{font-family:ui-monospace,monospace;direction:ltr}
.chart{display:flex;align-items:flex-end;gap:8px;height:160px;padding-top:10px}
.bar-wrap{display:flex;flex-direction:column;align-items:center;gap:6px} .bar-wrap span{font-size:10px;color:#8E8EA0}
.bar{width:34px;background:linear-gradient(#E50914,#ff6b5e);border-radius:8px 8px 4px 4px}
input{background:#16161f;border:1px solid #2a2a36;color:#fff;padding:14px 16px;border-radius:14px;font-size:14px}
button{background:linear-gradient(#E50914,#c40812);color:#fff;border:0;padding:14px;border-radius:14px;font-weight:700;cursor:pointer;font-size:14px}
</style></head><body>$nav$content</body></html>
HTML;
    }
}
