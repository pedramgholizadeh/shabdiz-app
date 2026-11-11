<div class="page-head">
    <div>
        <h1>افزودن فیلم</h1>
        <p>اطلاعات اصلی فیلم را وارد کنید؛ پس از ثبت می‌توانید سانس پخش بسازید.</p>
    </div>
    <a class="btn ghost" href="<?= e(url('admin/movies')) ?>">بازگشت</a>
</div>

<form class="card" method="post" action="<?= e(url('admin/movies')) ?>">
    <?= csrf_field() ?>
    <div class="form-grid">
        <div class="field">
            <label for="title_fa">نام فارسی *</label>
            <input id="title_fa" name="title_fa" required placeholder="اودیسه">
        </div>
        <div class="field">
            <label for="title_en">نام انگلیسی</label>
            <input id="title_en" name="title_en" dir="ltr" placeholder="The Odyssey">
        </div>
        <div class="field">
            <label for="director">کارگردان</label>
            <input id="director" name="director" placeholder="Christopher Nolan">
        </div>
        <div class="field">
            <label for="year">سال ساخت</label>
            <input id="year" name="year" type="number" min="0" max="2100" placeholder="2026">
        </div>
        <div class="field">
            <label for="duration_minutes">مدت (دقیقه)</label>
            <input id="duration_minutes" name="duration_minutes" type="number" min="1" placeholder="150">
        </div>
        <div class="field">
            <label for="genres">ژانرها</label>
            <input id="genres" name="genres" placeholder="درام، ماجراجویی">
            <span class="hint">با ویرگول جدا کنید.</span>
        </div>
        <div class="field">
            <label for="imdb_rating">امتیاز IMDb</label>
            <input id="imdb_rating" name="imdb_rating" type="number" step="0.1" min="0" max="10" dir="ltr" placeholder="8.4">
        </div>
        <div class="field">
            <label for="rt_rating">امتیاز Rotten Tomatoes (٪)</label>
            <input id="rt_rating" name="rt_rating" type="number" min="0" max="100" dir="ltr" placeholder="93">
        </div>
        <div class="field">
            <label for="cover_url">آدرس کاور</label>
            <input id="cover_url" name="cover_url" dir="ltr" placeholder="https://…/cover.jpg">
        </div>
        <div class="field">
            <label for="backdrop_url">آدرس تصویر پس‌زمینه</label>
            <input id="backdrop_url" name="backdrop_url" dir="ltr" placeholder="https://…/backdrop.jpg">
        </div>
        <div class="field">
            <label for="trailer_url">آدرس تریلر</label>
            <input id="trailer_url" name="trailer_url" dir="ltr" placeholder="https://…">
        </div>
        <div class="field">
            <label for="status">وضعیت</label>
            <select id="status" name="status">
                <option value="published">منتشرشده</option>
                <option value="draft">پیش‌نویس</option>
            </select>
        </div>
        <div class="field full">
            <label for="synopsis_fa">خلاصه داستان</label>
            <textarea id="synopsis_fa" name="synopsis_fa" placeholder="خلاصه کوتاه داستان..."></textarea>
        </div>
    </div>
    <div class="form-actions">
        <button class="btn" type="submit">ثبت فیلم</button>
        <a class="btn ghost" href="<?= e(url('admin/movies')) ?>">انصراف</a>
    </div>
</form>
