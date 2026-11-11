# ShabDiz

**Synchronized open-source cinema nights — on Android, Windows, macOS, and Linux.**

ShabDiz (شب‌دیز) is a cross-platform app for watching a scheduled movie together, at the same moment.
The server owns the clock: join a screening at 21:32 and playback starts at minute 32, in sync with
everyone else in the room. The app is built with Flutter and plays through libmpv, so MKV, MP4, and
external subtitles all work on every platform.

The project ships three things:

| Component | Stack | Location |
| --- | --- | --- |
| Cross-platform app | Flutter 3 / Dart 3, Riverpod, GoRouter, media_kit (libmpv) | [`app/`](app) |
| Admin panel + REST API | PHP 8 + MySQL, no framework | [`backend/`](backend) |
| Landing page | Static HTML, Tailwind, AOS, Anime.js, Three.js | [`site/`](site) |

[![Build Android APK](https://github.com/pedramgholizadeh/shabdiz-app/actions/workflows/build-apk.yml/badge.svg)](https://github.com/pedramgholizadeh/shabdiz-app/actions/workflows/build-apk.yml)
[![Build Desktop Apps](https://github.com/pedramgholizadeh/shabdiz-app/actions/workflows/build-desktop.yml/badge.svg)](https://github.com/pedramgholizadeh/shabdiz-app/actions/workflows/build-desktop.yml)
[![Deploy landing page](https://github.com/pedramgholizadeh/shabdiz-app/actions/workflows/pages.yml/badge.svg)](https://github.com/pedramgholizadeh/shabdiz-app/actions/workflows/pages.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-e8b86d.svg)](LICENSE)

- Landing page: <https://pedramgholizadeh.github.io/shabdiz-app/>
- Latest release (APK, Windows, macOS, Linux): <https://github.com/pedramgholizadeh/shabdiz-app/releases/latest>

---

## Features

- **Email OTP sign-in.** Six-digit codes, HMAC-hashed at rest, short TTL, rate-limited.
- **Timeline of screenings.** Persian/Jalali dates, newest first, live/upcoming/ended states.
- **Movie details.** Persian and English titles, synopsis, genres, director, runtime, IMDb and
  Rotten Tomatoes ratings, cover art.
- **Server-synchronized playback.** The API returns `position_seconds`; the app seeks to it on join
  and re-syncs every 15 seconds. Heartbeats keep the room count honest.
- **Real player.** `media_kit` / libmpv with hardware acceleration, network buffering, reconnect, and
  subtitle tracks loaded from URL. Immersive landscape playback on phones; a windowed player with
  keyboard shortcuts (Space, ←/→, Esc) on desktop.
- **Cross-platform.** One codebase builds for Android 6+ (phones and Android TV from the same APK),
  Windows x64, macOS (Apple Silicon and Intel), and Linux x64/arm64. Every build talks to the same
  API at `https://apps.webiro.ir/shabdiz/api`.
- **Optional sign-in.** Watch as a guest without an account, or sign in with email + one-time code;
  guest watch history moves to the real account on sign-in. OTP mail goes out through the Resend
  API with the host SMTP and PHP `mail()` as fallbacks.
- **Admin panel.** Create movies and screenings, set Jalali date/time, stream and subtitle URLs,
  see who is watching which movie and how far they got, and browse registered users.
- **Deploy over FTP.** `deploy.sh` builds the server `.env`, uploads code, runs migrations through a
  one-time tokenized installer, and verifies the deployment with HTTP probes.
- **CI-built binaries.** GitHub Actions analyzes, tests, builds, signs when secrets are present, and
  publishes APKs plus desktop installers for every supported architecture.

## Screens

The app flow is: **splash → timeline (guest or signed-in) → movie detail → synchronized player**,
with an account panel for identity and watch history. Signing in with email + OTP is optional.

## Architecture

```
┌──────────────────────┐      HTTPS / JSON      ┌────────────────────┐
│ Android · Windows    │  ───────────────────▶  │  PHP API + Admin   │
│ macOS · Linux        │  ◀───────────────────  │  (apps.webiro.ir)  │
│ Flutter + libmpv     │  timeline · join · sync│                    │
└──────────────────────┘                        └─────────┬──────────┘
                                                          │ PDO
                                                ┌─────────▼──────────┐
                                                │       MySQL        │
                                                │ movies/screenings  │
                                                └────────────────────┘

GitHub Actions ──▶ APK · .exe · .dmg · .zip · .deb · .tar.gz
GitHub Pages   ──▶ site/
```

Every platform consumes the same API contract; `API_BASE_URL` is the only build-time difference and
defaults to the production endpoint, so shipped binaries work against `apps.webiro.ir/shabdiz`.

**Synchronization model.** Screenings are stored in UTC. On join, the API computes
`now − starts_at_utc` and returns that position with the stream and subtitle URLs. The client seeks
before playing, re-checks the position every 15 seconds, and corrects drift above 2.5 seconds. Late
joiners, paused devices, and reconnects all land on the same timeline.

## Repository layout

```
app/                     Flutter app (Android 6+, Windows x64, macOS, Linux)
  lib/core/              config, theme, router, network, storage, dates
  lib/data/              API models and repositories
  lib/features/          splash, auth, timeline, movie, player
  test/                  model and date unit tests
  android/               Android runner and signing config
  windows/               Win32 runner (CMake)
  macos/                 Xcode runner, entitlements, Info.plist
  linux/                 GTK runner, CMake, desktop entry
backend/                 PHP 8 admin panel and JSON API
  app/Core/              router, request/response, PDO, auth, views
  app/Http/Controllers/  Admin/* and Api/*
  app/Repositories/      SQL access, one class per aggregate
  app/Support/           Jalali dates, mail, installer
  app/Views/             server-rendered admin templates (RTL)
  migrations/            additive SQL migrations
  public/                front controller and hardened .htaccess
site/                    static Persian landing page for GitHub Pages
.github/workflows/       APK, desktop, and Pages workflows
deploy.sh                FTP deployment (code, env, install, checks)
config.env.example       template for deployment secrets (never commit config.env)
docs/API.md              API contract and sync algorithm
AGENTS.md                contributor and AI-agent handbook
```

## Quick start

### App

Requirements: Flutter 3.47+ and a platform toolchain — Android SDK + JDK 17, Visual Studio with
"Desktop development with C++" on Windows, Xcode + CocoaPods on macOS, or `clang`, `cmake`,
`ninja-build`, `pkg-config`, `libgtk-3-dev`, and `libmpv-dev` on Linux.

```bash
cd app
flutter pub get
flutter test
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
flutter run -d macos   # or windows, linux
```

Release builds:

```bash
flutter build apk --release
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

`API_BASE_URL` defaults to `https://apps.webiro.ir/shabdiz/api`, so published binaries need no extra
flags. For the Android emulator, `10.0.2.2` reaches the host machine.

Desktop players use libmpv: media_kit ships it on Windows and macOS, while Linux links the system
`libmpv2` package (`sudo apt install libmpv2`). Windows ARM64 machines run the x64 build through the
built-in emulation layer.

Android release builds use `app/android/key.properties` when present; otherwise they fall back to
debug signing so local builds keep working:

```properties
storePassword=...
keyPassword=...
keyAlias=shabdiz
storeFile=/absolute/path/to/shabdiz-release.jks
```

Create the keystore with the project identity:

```bash
keytool -genkeypair -v -keystore shabdiz-release.jks -keyalg RSA -keysize 4096 \
  -validity 10000 -alias shabdiz \
  -dname "CN=Pedram Gholizadeh, O=WEBIRO, L=Tehran, ST=Tehran, C=IR"
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
# Fill FTP, database, admin values, and the mail keys (RESEND_API_KEY and/or SMTP_*).
bash deploy.sh all
```

OTP delivery is configured by `MAIL_DRIVER` in `config.env`: `resend` (default) sends through the
Resend API and falls back to the host SMTP account (`SMTP_HOST`/`SMTP_PORT`/`SMTP_USER`/
`SMTP_PASS`/`SMTP_ENCRYPTION`), then to PHP `mail()`. Channels without credentials are skipped; use
`MAIL_DRIVER=log` on staging (codes land in `storage/logs/mail.log`).

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
- `.github/workflows/build-desktop.yml` builds every desktop target in a matrix and uploads one
  artifact per platform/architecture:

  | Artifact | Runner | Output |
  | --- | --- | --- |
  | `shabdiz-macos-arm64` | `macos-15` | `.dmg`, `.zip` (Apple Silicon) |
  | `shabdiz-macos-x64` | `macos-15-intel` | `.dmg`, `.zip` (Intel) |
  | `shabdiz-windows-x64` | `windows-latest` | `.zip` with `shabdiz.exe` |
  | `shabdiz-linux-x64` | `ubuntu-24.04` | `.deb`, `.tar.gz` (amd64) |
  | `shabdiz-linux-arm64` | `ubuntu-24.04-arm` | `.deb`, `.tar.gz` (arm64) |

  Tag pushes attach every file to the same release as the APKs.
- `.github/workflows/pages.yml` publishes `site/` to GitHub Pages.

All shipped binaries are attributed to **Pedram Gholizadeh (WEBIRO), Tehran, Iran — webiro.ir**, and
are preconfigured for the production API. Code signing is optional; without certificates the macOS
build is ad-hoc signed (users right-click → Open) and the Windows build is unsigned.

Optional repository secrets:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Base64 of the `.jks` keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `WINDOWS_PFX_BASE64` | Base64 of an Authenticode `.pfx` |
| `WINDOWS_PFX_PASSWORD` | Password for that `.pfx` |
| `MACOS_CERTIFICATE_BASE64` | Base64 Developer ID Application `.p12` |
| `MACOS_CERTIFICATE_PASSWORD` | Password for that `.p12` |
| `APPLE_ID` / `APPLE_APP_SPECIFIC_PASSWORD` | Notarization credentials (`notarytool`) |
| `APPLE_TEAM_ID` | Apple Developer team identifier |

Without Android secrets, CI produces a debug-signed APK — installable, but not suitable for store
distribution.

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

Contributions are welcome — bug reports, copy improvements, translations, and new features on the
app or backend alike. All development happens on GitHub:

1. **Fork and clone** the repository, then create a branch for your change.
2. **Read [`AGENTS.md`](AGENTS.md)** first — it documents the architecture, the server-is-the-clock
   and security invariants, naming conventions, and commit style. Keep those intact.
3. **Set up locally** (see [Quick start](#quick-start)): the Flutter app runs on macOS, Windows, or
   Linux; the backend needs PHP 8.1+ and MySQL, served with `php -S 127.0.0.1:8080 -t public
   public/index.php`.
4. **Run the checks** before opening the pull request:

   ```bash
   cd app && flutter analyze && flutter test
   find backend -name '*.php' -print0 | xargs -0 -n1 php -l
   bash -n deploy.sh
   ```

5. **Open a pull request** against `master`. Write scoped, imperative commits
   (e.g. `player: resync on app resume`), keep changes focused, never commit secrets, and include
   tests for behavior that can regress. CI runs analyze + tests on every pull request.

Good places to start are the open [issues](https://github.com/pedramgholizadeh/shabdiz-app/issues)
and the roadmap in [`AGENTS.md`](AGENTS.md). For UI changes, actually run the app and exercise both
the happy path and the edge case you touched.

## License

[MIT](LICENSE) © 2026 Pedram Gholizadeh (WEBIRO), Tehran, Iran
