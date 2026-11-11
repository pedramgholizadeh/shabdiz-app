<div class="page-head">
    <div>
        <h1>سانس‌های پخش</h1>
        <p>زمان‌بندی نمایش فیلم‌ها به وقت تهران</p>
    </div>
    <a class="btn" href="<?= e(url('admin/screenings/new')) ?>">+ ثبت سانس</a>
</div>

<?php if ($screenings === []): ?>
    <div class="card empty">هنوز سانسی ثبت نشده است.</div>
<?php else: ?>
    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>فیلم</th>
                    <th>زمان پخش</th>
                    <th>سالن</th>
                    <th>وضعیت</th>
                    <th>لینک پخش</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($screenings as $screening): ?>
                <tr>
                    <td>
                        <div class="row-title">
                            <img class="cover" src="<?= e($screening['cover_url']) ?>" alt="">
                            <div>
                                <?= e($screening['title_fa']) ?>
                                <span class="sub" dir="ltr"><?= e($screening['title_en']) ?></span>
                            </div>
                        </div>
                    </td>
                    <td><?= e($screening['starts_at_label']) ?></td>
                    <td><?= e($screening['room']) ?></td>
                    <td>
                        <?php
                        $status = $screening['status'];
                        $label = match ($status) {
                            'live' => 'در حال پخش',
                            'upcoming' => 'آینده',
                            default => 'پایان‌یافته',
                        };
                        ?>
                        <span class="badge <?= e($status) ?>"><?= e($label) ?></span>
                    </td>
                    <td>
                        <span class="sub" dir="ltr" style="max-width:220px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
                            <?= e($screening['source_url']) ?>
                        </span>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
<?php endif; ?>
