<div class="page-head">
    <div>
        <h1>فیلم‌ها</h1>
        <p>کتابخانه فیلم‌های شب‌دیز</p>
    </div>
    <a class="btn" href="<?= e(url('admin/movies/new')) ?>">+ افزودن فیلم</a>
</div>

<?php if ($movies === []): ?>
    <div class="card empty">هنوز فیلمی ثبت نشده است.</div>
<?php else: ?>
    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>فیلم</th>
                    <th>سال</th>
                    <th>امتیازها</th>
                    <th>سانس</th>
                    <th>وضعیت</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($movies as $movie): ?>
                <tr>
                    <td>
                        <div class="row-title">
                            <img class="cover" src="<?= e($movie['cover_url']) ?>" alt="">
                            <div>
                                <?= e($movie['title_fa']) ?>
                                <span class="sub" dir="ltr"><?= e($movie['title_en']) ?></span>
                            </div>
                        </div>
                    </td>
                    <td><?= fa_num($movie['year']) ?></td>
                    <td>
                        <span class="sub">IMDb: <?= $movie['imdb_rating'] === null ? '—' : e((string) $movie['imdb_rating']) ?></span>
                        <span class="sub">Rotten: <?= $movie['rt_rating'] === null ? '—' : fa_num($movie['rt_rating']) . '٪' ?></span>
                    </td>
                    <td><?= fa_num($movie['screening_count'] ?? 0) ?></td>
                    <td><span class="badge"><?= $movie['status'] === 'draft' ? 'پیش‌نویس' : 'منتشرشده' ?></span></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
<?php endif; ?>
