<div class="page-head">
    <div>
        <h1>داشبورد</h1>
        <p>خلاصه وضعیت شب‌دیز</p>
    </div>
</div>

<div class="stats">
    <div class="stat"><span>فیلم‌ها</span><strong><?= fa_num($stats['movies']) ?></strong></div>
    <div class="stat"><span>سانس‌های ثبت‌شده</span><strong><?= fa_num($stats['screenings']) ?></strong></div>
    <div class="stat"><span>کاربران</span><strong><?= fa_num($stats['users']) ?></strong></div>
    <div class="stat"><span>در حال تماشا</span><strong class="<?= $stats['watching'] > 0 ? 'live' : '' ?>" style="<?= $stats['watching'] > 0 ? 'color:var(--red)' : '' ?>"><?= fa_num($stats['watching']) ?></strong></div>
</div>

<div class="card">
    <h2 style="margin:0 0 6px;font-size:16px">سانس بعدی</h2>
    <?php if ($nextScreening === null): ?>
        <p class="muted" style="margin:14px 0 0;font-size:12px">سانس آینده‌ای ثبت نشده است.</p>
        <a class="btn" style="margin-top:16px" href="<?= e(url('admin/screenings/new')) ?>">ثبت سانس جدید</a>
    <?php else: ?>
        <div class="next-box">
            <strong><?= e($nextScreening['title_fa']) ?></strong>
            <div class="muted" style="margin-top:6px;font-size:12px"><?= e((string) $nextLabel) ?></div>
        </div>
    <?php endif; ?>
</div>
