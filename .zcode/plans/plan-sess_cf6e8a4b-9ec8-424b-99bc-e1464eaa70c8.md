## Context

ShabDiz is infrastructure-complete but needs five capabilities before wider use:

1. **OTP delivery via Resend with host fallback** — `backend/app/Support/Mailer.php` today only supports `log` mode and PHP `mail()`. The user chose the full chain: **Resend API → host SMTP (authenticated) → PHP mail()**, with the code never logged outside `log` mode.
2. **Optional login (guest mode)** — splash currently forces `/auth`. Guests must browse and watch; the backend `join`/`timeline`/`heartbeat` endpoints are bearer-required, so guests need server-issued guest identities (also required for tracking). Guest history migrates to the real account when the guest later signs in.
3. **Watch tracking + admin visibility** — `playback_sessions` has no progress. Admin must see which user watched which movie, how much, and whether completed.
4. **Android TV support** — no leanback entries, white splash, no D-pad handling. Decision: **one universal APK** (no separate TV build); UI adapts.
5. **Landing page** — copy mentions desktops but has no per-OS download grid; the embedded workflow snippet is outdated.

All release binaries stay GitHub Actions `--release` builds; this Mac is only a test target (`flutter run -d macos`).

---

## 1. Backend — mail delivery (Resend → SMTP → mail())

**New `backend/app/Support/Smtp.php`** — minimal SMTP client (no Composer): `stream_socket_client`, EHLO, STARTTLS (or implicit SSL), AUTH LOGIN, MAIL FROM/RCPT TO/DATA, UTF-8 base64 subject. Config: `SMTP_HOST`, `SMTP_PORT` (default 587), `SMTP_USER`, `SMTP_PASS`, `SMTP_ENCRYPTION` (`tls`|`ssl`|`none`).

**Rewrite `backend/app/Support/Mailer.php`** — keep Persian subject/body; driver semantics:
- `MAIL_DRIVER=resend` (new production default): Resend API (`POST https://api.resend.com/emails`, bearer `RESEND_API_KEY`) → on failure host SMTP (only if `SMTP_HOST` set) → on failure PHP `mail()`.
- `MAIL_DRIVER=smtp`: SMTP → `mail()`. `MAIL_DRIVER=mail`: `mail()` only (unchanged). `MAIL_DRIVER=log`: unchanged staging log (the only mode that ever writes the code).
- Each attempt appends `[date] channel=resend to=… ok=0/1` to `storage/logs/mail.log` — never the code (security invariant 5).
- HTTP transport helper (cURL with `file_get_contents` stream-context fallback) inside Mailer.

**Config plumbing**: `backend/.env.example`, root `config.env.example`, and `deploy.sh` `cmd_env` (deploy.sh:143-161) gain `RESEND_API_KEY` + `SMTP_*` keys (optional, empty defaults). No new required validations.

## 2. Backend — guest mode

- **Migration `backend/migrations/003_guest_users.sql`** (additive): `ALTER TABLE users MODIFY email VARCHAR(190) NULL, ADD is_guest TINYINT(1) NOT NULL DEFAULT 0, ADD guest_ip VARCHAR(45) NOT NULL DEFAULT ''`.
- `UserRepository`: `createGuest($ip)` with a per-IP hourly throttle (reuse `otp_codes` rate-limit pattern → `429 rate_limited`); `publicPayload()` adds `is_guest`.
- `AuthController::guest()` (new, public): creates guest + `Auth::issueToken()` → `{token, user}` (same shape as `verify-otp`).
- `AuthController::verifyOtp()`: if the request carries a valid **guest** token, merge before issuing the real token — reassign that guest's `watch_progress` + `playback_sessions` rows to the real user (max-position dedup on the unique key), delete guest tokens, delete guest row (FK cascade). Merge SQL lives in `WatchProgressRepository::reassign()`.
- Route `POST /api/guest` in `backend/public/index.php`.

No changes needed to `join`/`timeline`/`heartbeat` auth: guests hold tokens, so existing `Auth::requireApiUser()` passes.

## 3. Backend — watch progress + admin view

- **Migration `backend/migrations/004_watch_progress.sql`**: `watch_progress(id, user_id, screening_id, movie_id, position_seconds, duration_seconds, completed, last_watched_at, created_at, updated_at)` — UNIQUE `(user_id, screening_id)`, FKs CASCADE, index on `last_watched_at`.
- **New `backend/app/Repositories/WatchProgressRepository.php`**: `record()` (clamps position to `[0, duration]`, completed when ≥95% of duration, `GREATEST()` upsert so progress never regresses), `reassign()`, `historyForUser()`, `adminList()`.
- `ScreeningController::join()` (ScreeningController.php:37): after `PlaybackRepository::join`, seed the progress row (server position on join). Extend `ScreeningRepository::find()` select to include `movie_id` + `duration_seconds` if missing.
- `ScreeningController::heartbeat()` (:72): accepts optional JSON `{position_seconds}` → `WatchProgressRepository::record()`. Heartbeats stay advisory for sync (never move server playback position — AGENTS.md rule preserved).
- New `GET /api/me/history` (`AuthController::history()`): user's watch rows + movie info + percent + completed + Jalali label; powers the in-app panel.
- **Admin page `/admin/watching`** ("تماشاها"): route + `Admin\WatchController::index` + `backend/app/Views/admin/watching/index.php` following the users-list pattern (`View::render`, `e()`, `fa_num()`); table columns: کاربر (name/email + مهمان badge), فیلم, سانس (Jalali), پیشرفت (time + percent), وضعیت (کامل تماشا / در حال تماشا / ناتمام), آخرین تماشا. Nav entry in `layout.php` `$navItems`.
- Dashboard (`DashboardController`): add a "در حال تماشا" stat = viewers with heartbeat in the last 90 s on a live screening (`PlaybackRepository::liveViewers()`).

## 4. Flutter app — guest mode + user panel

- `lib/data/models/user.dart`: `isGuest`; new `lib/data/models/watch_history_item.dart`.
- `lib/core/storage/token_store.dart`: persist user JSON alongside the token (guest flag survives restarts).
- `lib/data/repositories/auth_repository.dart`: `signInAsGuest()`, `history()`; `lib/data/repositories/playback_repository.dart`: `heartbeat(id, positionSeconds)`.
- `lib/core/network/api_client.dart`: `onError` → clear token on 401 (stale-token fix; no navigation).
- `lib/core/router/app_router.dart`: add `/account`. `lib/features/splash/splash_page.dart`: always go `/timeline` (login never forced).
- `lib/features/auth/auth_page.dart`: "ورود به عنوان مهمان" secondary button.
- `lib/features/timeline/timeline_page.dart`: header shows "ورود" for guests / account icon for users (replaces unconditional logout icon).
- **New `lib/features/account/account_page.dart`** — the user-panel scaffold: identity card (guest badge), "تماشاهای اخیر" list (poster, title, percent bar, completed badge) via new `meHistoryProvider`, actions: guests → "ورود با ایمیل"; users → "خروج".
- `lib/features/player/player_page.dart`: send `{position_seconds}` with every heartbeat + one best-effort final heartbeat on dispose.

## 5. Flutter app — Android TV + responsive design

- New `lib/core/utils/breakpoints.dart`; timeline becomes a centered `GridView` on wide screens (>900px, TV/desktop) and stays a list on phones; movie detail content capped at ~720px.
- Player keys (`_handleKey`): DPAD center/Enter/space = play/pause, DPAD up/down = toggle controls, Escape/Back = close controls then pop. **No seeking** — server owns the clock. Chrome buttons stay focusable with visible focus.
- `app/android/app/src/main/AndroidManifest.xml`: add `LEANBACK_LAUNCHER` category, `<uses-feature android.software.leanback required=false>`, `android.hardware.touchscreen required=false`, `android:banner` drawable (dark vector, no binary asset).
- Dark launch screen: `drawable/launch_background.xml` + `values-night` → `#08080C` (fixes white flash, matches brand).

## 6. Landing page (`site/index.html`)

- New `#download` section + nav link: per-OS cards — Android (direct `releases/latest/download/app-release.apk`, "همین APK روی تلویزیون اندرویدی" note), Windows, macOS (Silicon/Intel), Linux; desktop cards link to `releases/latest` (versioned asset names prevent direct links).
- Features grid: add Android TV + guest-watching mentions; fix outdated workflow snippet (`shabdiz-apk` → `shabdiz-universal-apk`).

## 7. CI + docs

- `build-apk.yml`: add `--dart-define=API_BASE_URL=https://apps.webiro.ir/shabdiz/api` to both APK builds (desktop already does; keeps release APKs production-wired). No new secrets anywhere.
- `docs/API.md`: guest endpoint, `/me/history`, heartbeat payload. `AGENTS.md`: status table + repo map + heartbeat/progress rule note. `README.md`: platform line + new config keys.

## Verification

1. `find backend -name '*.php' -print0 | xargs -0 -n1 php -l`; `bash -n deploy.sh`.
2. Backend smoke (local MySQL if available): `php scripts/setup.php` → serve → curl `POST /api/guest`, join/heartbeat with guest token, `/api/me/history`, admin watching page; OTP with `MAIL_DRIVER=log` (no code in other channels' logs).
3. `flutter analyze` (zero issues) + `flutter test` (extend `models_test.dart` for `isGuest` + history parsing).
4. `flutter run -d macos` on this machine: guest timeline → movie → account page → guest sign-in upgrade (the only locally testable target).
5. Landing: `python3 -m http.server 4173 -d site` visual check.
6. Android/Windows/Linux outputs verified only via GitHub Actions `--release` builds after push (per requirement, no local desktop builds).

Implementation order: migrations → Smtp/Mailer → guest + progress APIs → admin page → app guest/account → TV/responsive → manifest → landing → CI/docs.