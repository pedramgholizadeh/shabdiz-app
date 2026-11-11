<div class="page-head">
    <div>
        <h1>کاربران</h1>
        <p>کاربرانی که با ایمیل و کد یکبار مصرف وارد شده‌اند</p>
    </div>
</div>

<?php if ($users === []): ?>
    <div class="card empty">هنوز کاربری ثبت‌نام نکرده است.</div>
<?php else: ?>
    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>#</th>
                    <th>ایمیل</th>
                    <th>نام</th>
                    <th>تاریخ عضویت (UTC)</th>
                    <th>آخرین فعالیت</th>
                    <th>وضعیت</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($users as $user): ?>
                <tr>
                    <td><?= fa_num($user['id']) ?></td>
                    <td dir="ltr" style="text-align:right"><?= e($user['email']) ?></td>
                    <td><?= e($user['name']) ?></td>
                    <td dir="ltr" style="text-align:right"><?= e((string) $user['created_at']) ?></td>
                    <td dir="ltr" style="text-align:right"><?= e((string) ($user['last_seen_at'] ?? '—')) ?></td>
                    <td>
                        <span class="badge <?= (int) $user['is_active'] === 1 ? 'upcoming' : 'ended' ?>"><?= (int) $user['is_active'] === 1 ? 'فعال' : 'غیرفعال' ?></span>
                        <?php if ((int) ($user['is_guest'] ?? 0) === 1): ?><span class="badge ended">مهمان</span><?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
<?php endif; ?>
