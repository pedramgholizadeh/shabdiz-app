<?php

use Shabdiz\Core\Auth;
use Shabdiz\Core\Config;
use Shabdiz\Core\Flash;
use Shabdiz\Core\Request;

$admin = Auth::admin();
$currentPath = Request::path(Config::basePath());
$flash = Flash::pull();
$navItems = [
    ['path' => 'admin', 'label' => 'داشبورد', 'icon' => '◈'],
    ['path' => 'admin/movies', 'label' => 'فیلم‌ها', 'icon' => '▤'],
    ['path' => 'admin/screenings', 'label' => 'سانس‌های پخش', 'icon' => '◷'],
    ['path' => 'admin/users', 'label' => 'کاربران', 'icon' => '◎'],
];
?>
<!doctype html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= e($title ?? 'پنل مدیریت') ?> · شب‌دیز</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Vazirmatn:wght@400;500;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg: #08080c;
            --surface: #12121a;
            --surface-2: #1b1b26;
            --border: #2a2a38;
            --gold: #e8b86d;
            --gold-deep: #c9964a;
            --text: #f5f5f7;
            --muted: #9a9aa8;
            --red: #e05b5b;
            --green: #50c878;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            background: radial-gradient(1200px 600px at 100% -10%, #211a10 0, var(--bg) 55%);
            color: var(--text);
            font-family: Vazirmatn, Tahoma, sans-serif;
            font-size: 14px;
            min-height: 100vh;
        }
        a { color: var(--gold); text-decoration: none; }
        .shell { display: flex; min-height: 100vh; }
        .sidebar {
            width: 250px; flex: 0 0 250px; padding: 26px 18px;
            border-left: 1px solid var(--border);
            background: rgba(10, 10, 15, .75); backdrop-filter: blur(12px);
        }
        .brand { display: flex; align-items: center; gap: 10px; margin-bottom: 30px; }
        .brand-mark {
            width: 40px; height: 40px; border-radius: 12px;
            display: grid; place-items: center; font-size: 18px; color: #0a0a0f;
            background: linear-gradient(135deg, var(--gold), var(--gold-deep));
        }
        .brand strong { display: block; font-size: 18px; }
        .brand small { color: var(--muted); font-size: 10px; letter-spacing: .8px; }
        .nav { display: grid; gap: 6px; }
        .nav a {
            display: flex; align-items: center; gap: 10px; padding: 11px 13px;
            color: var(--muted); border-radius: 11px; border: 1px solid transparent;
        }
        .nav a:hover { background: var(--surface); color: var(--text); }
        .nav a.active { background: var(--surface-2); color: var(--gold); border-color: var(--border); }
        .sidebar-footer { margin-top: 26px; padding-top: 18px; border-top: 1px solid var(--border); color: var(--muted); font-size: 11px; }
        .main { flex: 1; padding: 34px 38px 60px; max-width: 1200px; }
        .page-head { display: flex; align-items: center; justify-content: space-between; gap: 20px; margin-bottom: 24px; }
        .page-head h1 { margin: 0; font-size: 22px; }
        .page-head p { margin: 6px 0 0; color: var(--muted); font-size: 12px; }
        .card { background: var(--surface); border: 1px solid var(--border); border-radius: 18px; padding: 22px; }
        .stats { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 14px; margin-bottom: 22px; }
        .stat { background: var(--surface); border: 1px solid var(--border); border-radius: 16px; padding: 20px; }
        .stat span { color: var(--muted); font-size: 11px; }
        .stat strong { display: block; font-size: 30px; margin-top: 8px; color: var(--gold); }
        .btn {
            display: inline-flex; align-items: center; gap: 7px; padding: 10px 16px;
            border: 0; border-radius: 11px; background: var(--gold); color: #0a0a0f;
            font-family: inherit; font-size: 12px; font-weight: 700; cursor: pointer;
        }
        .btn:hover { background: #f0c886; }
        .btn.ghost { background: transparent; color: var(--muted); border: 1px solid var(--border); }
        .table-wrap { overflow-x: auto; border: 1px solid var(--border); border-radius: 16px; }
        table { width: 100%; border-collapse: collapse; min-width: 640px; }
        th, td { padding: 13px 14px; text-align: right; border-bottom: 1px solid var(--border); }
        th { color: var(--muted); font-size: 11px; font-weight: 500; background: rgba(255,255,255,.02); }
        tr:last-child td { border-bottom: 0; }
        td .sub { display: block; color: var(--muted); font-size: 10px; margin-top: 3px; }
        .cover { width: 40px; height: 58px; border-radius: 8px; object-fit: cover; background: var(--surface-2); }
        .row-title { display: flex; align-items: center; gap: 11px; }
        .badge { display: inline-flex; align-items: center; gap: 5px; padding: 4px 9px; border-radius: 999px; font-size: 10px; border: 1px solid var(--border); color: var(--muted); }
        .badge.live { color: var(--red); border-color: rgba(224,91,91,.4); background: rgba(224,91,91,.1); }
        .badge.upcoming { color: var(--gold); border-color: rgba(232,184,109,.4); background: rgba(232,184,109,.1); }
        .badge.ended { color: var(--muted); }
        .form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
        .field { display: grid; gap: 7px; }
        .field.full { grid-column: 1 / -1; }
        .field label { color: var(--muted); font-size: 11px; }
        .field input, .field select, .field textarea {
            width: 100%; padding: 11px 13px; border-radius: 10px;
            border: 1px solid var(--border); background: var(--surface-2);
            color: var(--text); font-family: inherit; font-size: 13px;
        }
        .field input:focus, .field select:focus, .field textarea:focus { outline: none; border-color: var(--gold); }
        .field textarea { min-height: 110px; resize: vertical; }
        .hint { color: var(--muted); font-size: 10px; line-height: 1.8; }
        .form-actions { display: flex; gap: 10px; margin-top: 22px; }
        .flash { margin-bottom: 18px; padding: 12px 16px; border-radius: 12px; font-size: 12px; border: 1px solid; }
        .flash.success { color: var(--green); border-color: rgba(80,200,120,.35); background: rgba(80,200,120,.08); }
        .flash.error { color: var(--red); border-color: rgba(224,91,91,.35); background: rgba(224,91,91,.08); }
        .empty { color: var(--muted); text-align: center; padding: 38px 0; }
        .auth-shell { min-height: 100vh; display: grid; place-items: center; padding: 20px; }
        .auth-card { width: 100%; max-width: 390px; background: var(--surface); border: 1px solid var(--border); border-radius: 22px; padding: 30px; }
        .auth-card .brand { justify-content: center; margin-bottom: 22px; }
        .auth-card h1 { font-size: 19px; margin: 0 0 8px; }
        .auth-card p { color: var(--muted); font-size: 12px; margin: 0 0 22px; }
        .auth-card .field { margin-bottom: 14px; }
        .auth-card .btn { width: 100%; justify-content: center; }
        .muted { color: var(--muted); }
        .next-box { margin-top: 18px; padding: 18px; border-radius: 14px; background: var(--surface-2); border: 1px solid var(--border); }
        @media (max-width: 820px) {
            .shell { flex-direction: column; }
            .sidebar { width: 100%; flex: none; border-left: 0; border-bottom: 1px solid var(--border); }
            .nav { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .sidebar-footer { display: none; }
            .main { padding: 24px 18px 50px; }
            .stats { grid-template-columns: 1fr; }
            .form-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
<?php if ($admin === null): ?>
    <div class="auth-shell">
        <?= $content ?>
    </div>
<?php else: ?>
    <div class="shell">
        <aside class="sidebar">
            <div class="brand">
                <div class="brand-mark">◐</div>
                <div>
                    <strong>شب‌دیز</strong>
                    <small>SHABDIZ ADMIN</small>
                </div>
            </div>
            <nav class="nav">
                <?php foreach ($navItems as $item): ?>
                    <?php
                    $isActive = $item['path'] === 'admin'
                        ? $currentPath === '/admin'
                        : str_starts_with($currentPath, '/' . $item['path']);
                    ?>
                    <a class="<?= $isActive ? 'active' : '' ?>" href="<?= e(url($item['path'])) ?>">
                        <span><?= $item['icon'] ?></span><?= e($item['label']) ?>
                    </a>
                <?php endforeach; ?>
            </nav>
            <div class="sidebar-footer">
                <div><?= e($admin['email']) ?></div>
                <form method="post" action="<?= e(url('admin/logout')) ?>" style="margin-top:12px">
                    <?= csrf_field() ?>
                    <button class="btn ghost" type="submit">خروج از پنل</button>
                </form>
            </div>
        </aside>
        <main class="main">
            <?php if ($flash !== null): ?>
                <div class="flash <?= e($flash['type'] ?? 'success') ?>"><?= e($flash['message'] ?? '') ?></div>
            <?php endif; ?>
            <?= $content ?>
        </main>
    </div>
<?php endif; ?>
</body>
</html>
