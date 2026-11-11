<div class="page-head">
    <div>
        <h1>ثبت سانس پخش</h1>
        <p>تاریخ شمسی و ساعت تهران را وارد کنید؛ همگام‌سازی پخش بر همین اساس انجام می‌شود.</p>
    </div>
    <a class="btn ghost" href="<?= e(url('admin/screenings')) ?>">بازگشت</a>
</div>

<form class="card" method="post" action="<?= e(url('admin/screenings')) ?>">
    <?= csrf_field() ?>
    <div class="form-grid">
        <div class="field full">
            <label for="movie_id">فیلم *</label>
            <select id="movie_id" name="movie_id" required>
                <option value="">یک فیلم انتخاب کنید…</option>
                <?php foreach ($movies as $movie): ?>
                    <option value="<?= e((string) $movie['id']) ?>">
                        <?= e($movie['title_fa']) ?><?= $movie['title_en'] !== '' ? ' — ' . e($movie['title_en']) : '' ?>
                    </option>
                <?php endforeach; ?>
            </select>
            <?php if ($movies === []): ?>
                <span class="hint">ابتدا از بخش فیلم‌ها یک فیلم اضافه کنید.</span>
            <?php endif; ?>
        </div>
        <div class="field">
            <label for="jalali_date">تاریخ شمسی *</label>
            <input id="jalali_date" name="jalali_date" required placeholder="۱۴۰۵/۰۸/۳۰" dir="ltr">
            <span class="hint">نمونه: 1405/08/30</span>
        </div>
        <div class="field">
            <label for="time">ساعت شروع (تهران) *</label>
            <input id="time" name="time" required placeholder="21:00" dir="ltr">
        </div>
        <div class="field">
            <label for="room">سالن</label>
            <input id="room" name="room" placeholder="main" value="main" dir="ltr">
        </div>
        <div class="field">
            <label for="source_type">نوع منبع</label>
            <select id="source_type" name="source_type">
                <option value="auto">خودکار</option>
                <option value="mkv">MKV</option>
                <option value="mp4">MP4</option>
                <option value="hls">HLS</option>
            </select>
        </div>
        <div class="field full">
            <label for="source_url">لینک پخش *</label>
            <input id="source_url" name="source_url" required dir="ltr" placeholder="https://cdn.example.com/movie.mkv">
            <span class="hint">لینک مستقیم یا HLS سرور ایران. پخش با VLC انجام می‌شود و MKV/MP4/… پشتیبانی می‌شود.</span>
        </div>
        <div class="field">
            <label for="subtitle_url">لینک زیرنویس</label>
            <input id="subtitle_url" name="subtitle_url" dir="ltr" placeholder="https://cdn.example.com/subtitle.srt">
        </div>
        <div class="field">
            <label for="subtitle_label">برچسب زیرنویس</label>
            <input id="subtitle_label" name="subtitle_label" placeholder="فارسی" value="فارسی">
        </div>
    </div>
    <div class="form-actions">
        <button class="btn" type="submit">ثبت سانس</button>
        <a class="btn ghost" href="<?= e(url('admin/screenings')) ?>">انصراف</a>
    </div>
</form>
