# AGENTS.md — ShabDiz contributor & agent handbook

This file is the operating manual for anyone — human or automated — changing this repository.
Read it before writing code, and keep it current when architecture or invariants change.

---

## 1. Mission

ShabDiz (شب‌دیز) is an open-source Android app for **scheduled, synchronized movie nights**.

- Users sign in with **email + one-time code**.
- Screenings have a fixed, published start time (stored in UTC, displayed in Jalali/Tehran).
- A user who joins late starts at the server-owned position, not at 00:00.
- An admin panel manages movies, screenings, stream URLs, subtitles, and users.
- Anyone can download the APK; the APK is produced by GitHub Actions.

Optimize for a calm, cinematic experience and for a small, auditable server surface. This project
is infrastructure-complete, not feature-complete: keep the architecture intact when extending it.

---

## 2. Current status

| Area | State |
| --- | --- |
| Flutter app | Splash, OTP auth, timeline, movie details, synchronized VLC player |
| Admin panel | Login, dashboard, movie create/list, screening create/list, users list |
| API | Health, OTP, me, timeline, movie detail, join, playback timeline, heartbeat |
| Database | Migrations applied by the installer; seed categories |
| Landing page | Persian, RTL, static, deployed to GitHub Pages |
| Deployment | FTP via `deploy.sh` with tokenized self-deleting installer |
| CI | APK build/release workflow; Pages workflow |
| Not built yet | Watch history, notifications, room chat, profile editing, password reset |

Treat the table as a map, not a promise. Update it when a row changes.

---

## 3. Repository map

```
app/                        Flutter application
  lib/main.dart             entry point
  lib/app.dart              MaterialApp.router, fa_IR, RTL
  lib/core/config/          API base URL and timing constants
  lib/core/network/         Dio client, bearer-token interceptor, errors
  lib/core/router/          GoRouter route table and redirects
  lib/core/storage/         flutter_secure_storage token store
  lib/core/theme/           colors, typography, component themes
  lib/core/utils/           Jalali/Tehran dates, duration formatting
  lib/data/models/          immutable API models with fromJson
  lib/data/repositories/    API calls + Riverpod providers
  lib/features/splash/      brand animation and session restore
  lib/features/auth/        email + OTP flow
  lib/features/timeline/    screening cards, newest first
  lib/features/movie/       detail page
  lib/features/player/      VLC player, seek/resync/heartbeat
  lib/widgets/              shared visual components
  test/                     pure-Dart unit tests

backend/                    PHP 8 admin panel + JSON API
  app/bootstrap.php         root constant, autoloader, helpers, .env, session, headers
  app/Core/                 Env, Config, Database, Request, Response, Router, View, Auth, Flash
  app/Http/Controllers/     Admin/* and Api/* controllers (static methods)
  app/Repositories/         SQL access; one class per aggregate
  app/Support/              Jalali, Mailer, Installer
  app/Views/                server-rendered admin templates (RTL, no build step)
  migrations/               additive, ordered SQL migrations
  public/index.php          front controller and route table
  public/.htaccess          rewrite, auth-header preservation, private-path denial
  scripts/setup.php         CLI installer wrapper
  storage/                  logs, cache; denied over HTTP
  public/uploads/           upload area; denies script execution

site/                       static GitHub Pages landing page
.github/workflows/          build-apk.yml, pages.yml
deploy.sh                   FTP deploy: code, env, setup, check, all
config.env.example          deployment template (real config.env is ignored)
docs/API.md                 endpoint contract and sync algorithm
```

---

## 4. Commands

### App

```bash
cd app
flutter pub get
flutter analyze                 # must report no issues
flutter test                    # must pass
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
flutter build apk --release
```

### Backend

```bash
cd backend
php scripts/setup.php           # dirs, guards, migrations, admin
php -S 127.0.0.1:8080 -t public public/index.php
find . -name '*.php' -print0 | xargs -0 -n1 php -l
```

Set `APP_BASE_PATH=` (empty) for local serving. Production uses `/shabdiz`.

### Deployment & docs

```bash
bash -n deploy.sh
bash deploy.sh all              # requires a filled config.env
python3 -m http.server 4173 -d site
```

### Verification bar for a change

1. `flutter analyze` — no issues.
2. `flutter test` — all pass; add tests for new pure logic.
3. `php -l` on every changed PHP file.
4. `bash -n deploy.sh` when deployment changes.
5. For UI changes, actually run the app (or at minimum the landing page) and exercise both the happy
   path and the edge case you touched.

---

## 5. Architecture rules

### Server is the clock

- Every timestamp is stored and transmitted in **UTC**.
- `screenings.starts_at_utc` / `ends_at_utc` are authoritative.
- Status is derived from UTC now (`upcoming`, `live`, `ended`); never trust a client clock.
- `position_seconds = max(0, now − starts_at)` while live.
- The client seeks on join, re-syncs every 15 seconds, and corrects drift above 2.5 seconds.
- Heartbeats are advisory presence signals; they must not affect playback position.

### Jalali dates

- Conversion and formatting live in `backend/app/Support/Jalali.php` and
  `app/lib/core/utils/dates.dart`. Do not scatter conversion logic.
- Admin forms submit Jalali `date` + `time`; the backend converts to UTC once, on write.
- Read-side payloads include both ISO UTC and a Jalali label.

### API

- Every endpoint returns the envelope `{ok, data}` or `{ok, error:{code,message}}`.
- Errors use stable machine codes (`validation_error`, `rate_limited`, `invalid_code`,
  `not_found`, `not_started`, `ended`, `source_missing`, …).
- API auth is a bearer token; tokens are stored only as SHA-256 hashes.
- Do not leak source/subtitle URLs from list endpoints. They are released only by `join`.
- Scope every user-owned query by `user_id`.

### Admin

- Server-rendered PHP with a shared layout. No JS build step.
- Every state-changing form includes a CSRF token; every admin route requires a session.
- Input validation belongs in controllers; SQL belongs in repositories.
- Escape all output with `e()`.

### Data

- Migrations are additive and ordered (`NNN_name.sql`). Never rewrite an applied migration.
- The installer records applied versions in `schema_migrations`.
- Use prepared statements everywhere. Prefer single-quoted SQL literals (ANSI_QUOTES safety).

### App

- Riverpod providers live next to their repository; widgets read providers, not Dio directly.
- Models are immutable and parse defensively (`json_utils.dart`).
- Route guards redirect unauthenticated users to `/auth` and authenticated users away from it.
- The player owns orientation and immersive mode; restore both on dispose.
- UI text is Persian; code identifiers and comments are English.

---

## 6. Security invariants (non-negotiable)

1. **Never commit secrets.** `config.env`, `.env`, keystores, `key.properties`, and service tokens
   stay out of git. Only placeholders belong in `*.example` files.
2. **Never add credentials to the landing page.** `site/` is public static output.
3. **Never weaken `.htaccess` denials.** `app/`, `migrations/`, `scripts/`, `storage/`, and `.env`
   must remain unreachable. Per-directory guards exist as defense in depth.
4. **Never trust client input.** Validate email/code/IDs/URLs; encode output; prepare SQL.
5. **Never log secrets or OTP codes.** Mail in `log` mode goes to `storage/logs`, which is private.
6. **Never widen CORS or cookies casually.** Sessions are HttpOnly; API is bearer-only.
7. **Do not disable TLS.** `usesCleartextTraffic=false` is intentional.
8. **Keep one-time installers self-deleting and token-guarded.** If a deploy fails mid-way, remove
   the temporary file manually.

If a change requires a new secret, add it to `config.env.example` as an empty placeholder, to
`deploy.sh`'s `.env` generation, and to the README's secret table — never to tracked real values.

---

## 7. Deployment contract

- `deploy.sh` sources `config.env` from the repository root.
- `FTP_REMOTE_ROOT` is the docroot of the app (e.g. the `shabdiz` folder). `public/index.php` is
  uploaded as `<root>/index.php`; `public/.htaccess` as `<root>/.htaccess`.
- `APP_BASE_PATH` must match the URL prefix (`/shabdiz` in production).
- `cmd_code` mirrors only code directories. It must never mirror `.env`, uploads, or storage.
- `cmd_env` validates required values, hashes the admin password locally, and uploads `.env`.
- `cmd_setup` uploads a random-named PHP file guarded by `DEPLOY_TOKEN`, calls `Installer::run()`,
  then deletes the file. Keep both the random name and the token check.
- `cmd_check` must keep the 403 probes for `app/bootstrap.php` and `.env`.
- `APP_KEY` must remain stable across deploys; changing it invalidates OTP digests and sessions.

---

## 8. CI

`build-apk.yml`:

- Triggers: pushes to `master`, tags `v*`, pull requests, manual dispatch.
- Java 17, Flutter `3.47.7`, `flutter pub get`, analyze, test.
- Optional keystore from `ANDROID_KEYSTORE_*` secrets; otherwise debug signing.
- Artifacts: universal APK and per-ABI APKs.
- Tags publish a GitHub Release.

`pages.yml`:

- Publishes `site/` with `actions/deploy-pages`.
- Requires Pages to be enabled with **Source: GitHub Actions**.

Do not add secrets to workflow files. Reference `secrets.*` only.

---

## 9. Conventions

- **Language:** English in code, comments, commit messages, docs, and variable names. Persian in
  user-facing copy and admin UI.
- **Style:** PHP 8.1+, `declare(strict_types=1)`, typed properties, `final` classes, static
  controller methods. Dart 3, `const` where possible, no dynamic unless parsing JSON.
- **Naming:** DB tables plural snake_case; columns snake_case; UTC columns end in `_utc`; Dart
  models use `fromJson` factories; PHP repositories are `XRepository` with static methods.
- **Comments:** explain *why*, not *what*. Do not narrate obvious code.
- **Commits:** imperative, scoped, e.g. `player: resync on app resume`.
- **No dead code, no speculative abstractions, no backwards-compatibility shims.** Delete unused
  code instead of commenting it out.

---

## 10. Known gaps and next steps

Good next changes, in rough order:

1. Media upload handling (covers/subtitles) with MIME and size validation.
2. Screening edit/cancel and movie edit flows.
3. Push/local notifications before a screening starts.
4. Watch history and “continue watching”.
5. Optional room chat or reactions, gated by auth and rate limits.
6. Integration test against a disposable MySQL instance.
7. Accessibility pass: focus order, contrast, screen-reader labels, reduced motion.
8. Localization scaffolding if a second language is added (keep Persian as default).

When you add a feature, update this file's status table and, if the API changes,
[`docs/API.md`](docs/API.md).
