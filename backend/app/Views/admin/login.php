<form method="post" action="<?= e(url('admin/login')) ?>" class="auth-card">
    <?= csrf_field() ?>
    <div class="brand">
        <div class="brand-mark">◐</div>
        <div>
            <strong>شب‌دیز</strong>
            <small>SHABDIZ ADMIN</small>
        </div>
    </div>
    <h1>ورود به پنل مدیریت</h1>
    <p>برای مدیریت فیلم‌ها و سانس‌های پخش وارد شوید.</p>

    <div class="field">
        <label for="email">ایمیل</label>
        <input id="email" name="email" type="email" dir="ltr" required autofocus value="admin@example.com">
    </div>
    <div class="field">
        <label for="password">رمز عبور</label>
        <input id="password" name="password" type="password" dir="ltr" required>
    </div>
    <button class="btn" type="submit">ورود</button>
</form>
