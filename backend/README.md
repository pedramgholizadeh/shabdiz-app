# شبدیز — بک‌اند (Shabdiz Backend)

بک‌اند PHP خالص (بدون وابستگی) برای اپلیکیشن شبدیز. کلید API سرویس محتوا فقط روی سرور نگه‌داری می‌شود و هرگز به کلاینت ارسال نمی‌شود.

## قابلیت‌ها

- **ورود با کد یکبار‌مصرف**: `POST /auth/request` → ارسال کد ۶ رقمی با سرویس Resend؛ `POST /auth/verify` → صدور توکن ۳۰ روزه.
- **پروفایل**: `GET/PATCH/DELETE /me`
- **علاقه‌مندی‌های ابری (Sync)**: `GET/POST/PUT/DELETE /favorites`
- **پروکسی محتوا** (نیازمند توکن):
  - `GET /movies?genre=0&filter=1&page=0`
  - `GET /series?genre=0&filter=1&page=0`
  - `GET /search?q=متن`
  - `GET /genres/movie` · `GET /genres/serial`
  - `GET /countries`
  - `GET /posters?country=1&filter=1&page=0`
  - `GET /seasons/{seriesId}`
- محدودسازی نرخ ارسال کد (۶۰ ثانیه)، انقضای کد (۵ دقیقه)، سقف تلاش (۵ بار)، fallback خودکار به سرورهای کمکی.

## استقرار روی `apps.webiro.ir/shabdiz`

1. محتویات پوشه‌ی `backend/` را در `apps.webiro.ir/shabdiz` قرار دهید (پوشه‌ی `public` باید document root همان زیرپوشه باشد یا محتویات `public` را در ریشه‌ی `shabdiz` بگذارید).
2. `config.example.php` را به `config.php` کپی کنید و مقادیر را تنظیم کنید:
   ```bash
   php -r "echo bin2hex(random_bytes(32));"   # برای app_secret
   ```
   - `RESEND_API_KEY` را از resend.com بگیرید و در `resend.api_key` بگذارید.
   - اگر خالی بماند، کد OTP فقط در لاگ سرور چاپ می‌شود (حالت توسعه).
3. اطمینان حاصل کنید PHP ≥ 8.1 با اکستنشن‌های `pdo_sqlite` و `curl` فعال است.
4. پوشه‌ی `data/` باید writable باشد (فایل `.htaccess` جلوی دسترسی مستقیم را می‌گیرد).
5. تست سلامت: `curl https://apps.webiro.ir/shabdiz/health` → `{"ok":true,...}`

### nginx

```nginx
location /shabdiz/ {
    alias /var/www/shabdiz/public/;
    try_files $uri $uri/ /shabdiz/index.php?$query_string;
    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $request_filename;
        include fastcgi_params;
    }
}
location ^~ /shabdiz/data { deny all; }
```

## API خلاصه

```
POST /auth/request   {"email": "user@example.com"}
POST /auth/verify    {"email": "...", "code": "123456"}   → {"token": "...", "user": {...}}
GET  /me             Authorization: Bearer <token>
PATCH /me            {"name": "نام"}
GET  /favorites
POST /favorites      {"id": 123, "type": "movie", ...}
DELETE /favorites/123?type=movie
GET  /movies?genre=0&filter=1&page=0    Authorization: Bearer <token>
```
