# ShabDiz

**Synchronized open-source cinema nights — for Android.**

ShabDiz (شب‌دیز) is an open-source Android app for watching a scheduled movie together, at the same
moment. The server owns the clock: join a screening at 21:32 and playback starts at minute 32, in sync
with everyone else in the room. The app is built with Flutter and the playback engine is VLC, so MKV,
MP4, and external subtitles all work.

The project ships three things:

| Component | Stack | Location |
| --- | --- | --- |
| Android app | Flutter 3 / Dart 3, Riverpod, GoRouter, VLC | [`app/`](app) |
| Admin panel + REST API | PHP 8 + MySQL, no framework | [`backend/`](backend) |
| Landing page | Static HTML, Tailwind, AOS, Anime.js, Three.js | [`site/`](site) |

[![Build Android APK](https://github.com/pedramgholizadeh/shabdiz-app/actions/workflows/build-apk.yml/badge.svg)](https://github.com/pedramgholizadeh/shabdiz-app/actions/workflows/build-apk.yml)
[![Deploy landing page](https://github.com/pedramgholizadeh/shabdiz-app/actions/workflows/pages.yml/badge.svg)](https://github.com/pedramgholizadeh/shabdiz-app/actions/workflows/pages.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-e8b86d.svg)](LICENSE)

- Landing page: <https://pedramgholizadeh.github.io/shabdiz-app/>
- Latest APK: <https://github.com/pedramgholizadeh/shabdiz-app/releases/latest>

---

## Features

- **Email OTP sign-in.** Six-digit codes, HMAC-hashed at rest, short TTL, rate-limited.
- **Timeline of screenings.** Persian/Jalali dates, newest first, live/upcoming/ended states.
- **Movie details.** Persian and English titles, synopsis, genres, director, runtime, IMDb and
  Rotten Tomatoes ratings, cover art.
- **Server-synchronized playback.** The API returns `position_seconds`; the app seeks to it on join
  and re-syncs every 15 seconds. Heartbeats keep the room count honest.
- **Real player.** `flutter_vlc_player` with hardware acceleration, network buffering, reconnect, and
  subtitle tracks loaded from URL. Landscape playback with immersive mode.
- **Admin panel.** Create movies and screenings, set Jalali date/time, stream and subtitle URLs, and
  browse registered users.
- **Deploy over FTP.** `deploy.sh` builds the server `.env`, uploads code, runs migrations through a
  one-time tokenized installer, and verifies the deployment with HTTP probes.
- **CI-built APKs.** GitHub Actions analyzes, tests, builds, and publishes release APKs.

## Screens

The app flow is: **splash → OTP sign-in → timeline → movie detail → synchronized player**.

## Architecture

```
┌──────────────────┐        HTTPS / JSON        ┌────────────────────┐
│  Android (VLC)   │  ───────────────────────▶  │  PHP API + Admin   │
│  Flutter app     │  ◀───────────────────────  │  (apps.webiro.ir)  │
└──────────────────┘   timeline · join · sync   └─────────┬──────────┘
                                                           │ PDO
                                                 ┌─────────▼──────────┐
                                                 │      MySQL         │
                                                 │ movies/screenings  │
                                                 └────────────────────┘

GitHub Actions ──▶ release APK       GitHub Pages ──▶ site/
```

**Synchronization model.** Screenings are stored in UTC. On join, the API computes
`now − starts_at_utc` and returns that position with the stream and subtitle URLs. The client seeks
before playing, re-checks the position every 15 seconds, and corrects drift above 2.5 seconds. Late
joiners, paused devices, and reconnects all land on the same timeline.

## Repository layout

```
app/                     Flutter Android app (minSdk 23 / Android 6)
  lib/core/              config, theme, router, network, storage, dates
  lib/data/              API models and repositories
  lib/features/          splash, auth, timeline, movie, player
  test/                  model and date unit tests
backend/                 PHP 8 admin panel and JSON API
  app/Core/              router, request/response, PDO, auth, views
  app/Http/Controllers/  Admin/* and Api/*
  app/Repositories/      SQL access, one class per aggregate
  app/Support/           Jalali dates, mail, installer
  app/Views/             server-rendered admin templates (RTL)
  migrations/            additive SQL migrations
  public/                front controller and hardened .htaccess
site/                    static Persian landing page for GitHub Pages
.github/workflows/       APK build/release and Pages deployment
deploy.sh                FTP deployment (code, env, install, checks)
config.env.example       template for deployment secrets (never commit config.env)
docs/API.md              API contract and sync algorithm
AGENTS.md                contributor and AI-agent handbook
```

## Quick start

### Android app

Requirements: Flutter 3.47+ and an Android SDK with platform tools. JDK 17+.

```bash
cd app
flutter pub get
flutter test
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

`API_BASE_URL` defaults to `https://apps.webiro.ir/shabdiz/api`. For the Android emulator,
`10.0.2.2` reaches the host machine.

Release builds use `app/android/key.properties` when present; otherwise they fall back to debug
signing so local builds keep working:

```properties
storePassword=...
keyPassword=...
keyAlias=shabdiz
storeFile=/absolute/path/to/shabdiz-release.jks
```

### Backend

Requirements: PHP 8.1+ with `pdo_mysql`, MySQL 5.7+/MariaDB 10.3+, and the `mail` transport (or
`log` for development).

```bash
cd backend
cp .env.example .env          # fill DB_* and APP_KEY
php scripts/setup.php         # dirs, .htaccess guards, migrations, admin user
php -S 127.0.0.1:8080 -t public public/index.php
```

For local development set `APP_BASE_PATH=` (empty) in `.env`. Open
<http://127.0.0.1:8080/admin/login> for the panel and
<http://127.0.0.1:8080/api/health> for the API.

Generate an admin password hash with:

```bash
php -r 'echo password_hash($argv[1], PASSWORD_DEFAULT), PHP_EOL;' 'your-password'
```

### Landing page

The page is plain HTML and needs no build step:

```bash
cd site
python3 -m http.server 4173
```

## Deployment

Deployment targets a shared host over FTP. All secrets live in `config.env` (gitignored) and are
never written into the repository or the static site.

```bash
cp config.env.example config.env
# Fill FTP, database, and admin values.
bash deploy.sh all
```

What each command does:

| Command | Action |
| --- | --- |
| `bash deploy.sh code` | Mirrors `backend/app`, `migrations`, and `scripts`; uploads the front controller and `.htaccess`. Never touches `.env` or uploads. |
| `bash deploy.sh env` | Generates `APP_KEY` once, hashes the admin password locally, uploads the server `.env`. |
| `bash deploy.sh setup` | Uploads a one-time tokenized installer that creates directories, guards, runs migrations, creates the admin, then deletes itself. |
| `bash deploy.sh check` | Probes `/` (302), `/admin/login` (200), `/api/health` (200), `/app/bootstrap.php` (403), `/.env` (403). |
| `bash deploy.sh all` | Runs code → env → setup → check. |

`APP_KEY` and `DEPLOY_TOKEN` are generated on first run and persisted into `config.env`; keep that
file safe and stable across deploys.

### GitHub Actions

- `.github/workflows/build-apk.yml` runs `flutter analyze`, `flutter test`, and builds a universal
  APK plus per-ABI APKs. Pushing a `v*` tag publishes them to a GitHub Release.
- `.github/workflows/pages.yml` publishes `site/` to GitHub Pages.

Optional repository secrets for signed release builds:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64 of the `.jks` keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | Key alias |

Without them, CI produces a debug-signed APK — installable, but not suitable for store distribution.

Enable Pages under **Settings → Pages → Source: GitHub Actions**. The workflow also requests
automatic enablement, but if the first run fails at *Configure Pages*, enable it once in the
repository settings and re-run the workflow.

## Security model

- No FTP, database, mail, or admin credentials are committed. `config.env` and `.env` are ignored;
  `.env.example` contains placeholders only.
- The server `.env` sits outside the front controller and is denied by `.htaccess`.
- `app/`, `migrations/`, and `scripts/` are denied both by the root rewrite rule and by per-directory
  `.htaccess` files.
- Upload directories deny script execution.
- OTP codes are stored as HMAC-SHA256 digests; API tokens are stored as SHA-256 hashes.
- Admin sessions use HttpOnly cookies, CSRF tokens, and password hashing via `password_hash`.
- The app refuses cleartext HTTP (`usesCleartextTraffic=false`).

Found a security issue? Please open a private advisory instead of a public issue.

## API

The JSON contract, error envelope, and synchronization details are documented in
[`docs/API.md`](docs/API.md). All successful responses use:

```json
{ "ok": true, "data": { } }
```

All errors use:

```json
{ "ok": false, "error": { "code": "invalid_code", "message": "..." } }
```

Authenticated endpoints expect `Authorization: Bearer <token>`.

## Contributing

Contributions are welcome. Read [`AGENTS.md`](AGENTS.md) for the architecture, conventions, and
verification commands before opening a pull request.

```bash
cd app && flutter analyze && flutter test
find backend -name '*.php' -print0 | xargs -0 -n1 php -l
bash -n deploy.sh
```

Please keep changes focused, keep secrets out of the repository, and include tests for behavior that
can regress.

## License

[MIT](LICENSE) © 2026 Pedram Gholizadeh
