<div class="page-head">
    <div>
        <h1>تماشاها</h1>
        <p>اینکه هر کاربر کدام فیلم را تا کجا تماشا کرده است</p>
    </div>
</div>

<?php if ($rows === []): ?>
    <div class="card empty">هنوز تماشایی ثبت نشده است.</div>
<?php else: ?>
    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>کاربر</th>
                    <th>فیلم</th>
                    <th>سانس</th>
                    <th>پیشرفت</th>
                    <th>وضعیت</th>
                    <th>آخرین تماشا (UTC)</th>
                </tr>
            </thead>
            <tbody>
            <?php foreach ($rows as $row): ?>
                <?php
                    $position = (int) $row['position_seconds'];
                    $duration = max(1, (int) $row['duration_seconds']);
                    $percent = min(100, (int) floor($position / $duration * 100));
                    $heartbeat = (string) ($row['last_heartbeat'] ?? '');
                    $watchingNow = $heartbeat !== '' && $heartbeat > gmdate('Y-m-d H:i:s', time() - 90);
                    $isGuest = (int) $row['user_is_guest'] === 1;
                    if ($watchingNow) {
                        $statusClass = 'live';
                        $statusLabel = 'در حال تماشا';
                    } elseif ((int) $row['completed'] === 1) {
                        $statusClass = 'upcoming';
                        $statusLabel = 'کامل تماشا شده';
                    } else {
                        $statusClass = 'ended';
                        $statusLabel = 'ناتمام';
                    }
                ?>
                <tr>
                    <td>
                        <?= e((string) $row['user_name']) ?>
                        <?php if ($isGuest): ?><span class="badge ended">مهمان</span><?php endif; ?>
                        <div class="muted" dir="ltr" style="text-align:right;font-size:11px"><?= e((string) ($row['user_email'] ?? '—')) ?></div>
                    </td>
                    <td><?= e((string) $row['movie_title_fa']) ?></td>
                    <td><?= e((string) $row['starts_at_label']) ?></td>
                    <td>
                        <div dir="ltr" style="text-align:right;font-size:12px"><?= fa_num(sprintf('%d:%02d / %d:%02d', intdiv($position, 60), $position % 60, intdiv($duration, 60), $duration % 60)) ?></div>
                        <div style="margin-top:5px;height:4px;border-radius:999px;background:var(--surface-2);overflow:hidden">
                            <div style="height:100%;width:<?= fa_num((string) $percent) ?>%;background:var(--gold)"></div>
                        </div>
                    </td>
                    <td><span class="badge <?= $statusClass ?>"><?= $statusLabel ?></span></td>
                    <td dir="ltr" style="text-align:right"><?= e((string) $row['last_watched_at']) ?></td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
<?php endif; ?>
