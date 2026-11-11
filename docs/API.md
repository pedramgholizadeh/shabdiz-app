# ShabDiz API

Base URL (production): `https://apps.webiro.ir/shabdiz/api`
Local example: `http://127.0.0.1:8080/api`

All responses are JSON (`application/json; charset=utf-8`).

## Envelope

Success:

```json
{
  "ok": true,
  "data": { }
}
```

Error:

```json
{
  "ok": false,
  "error": {
    "code": "invalid_code",
    "message": "کد وارد شده درست نیست."
  }
}
```

HTTP status codes are meaningful; clients should rely on both the status and the `error.code`.

| Code | Meaning |
| --- | --- |
| `validation_error` | Malformed or missing input |
| `rate_limited` | Too many requests |
| `invalid_code` | OTP missing, expired, or wrong |
| `mail_failed` | OTP could not be delivered |
| `not_found` | Movie/screening does not exist |
| `not_started` | Screening has not started yet |
| `ended` | Screening has ended |
| `source_missing` | Stream URL is not configured |

## Authentication

Endpoints marked **Auth** require:

```
Authorization: Bearer <token>
```

Tokens are issued by `POST /auth/verify-otp` (email sign-in) or `POST /guest` (guest session),
valid for 30 days, and stored server-side only as a SHA-256 hash. Treat them as opaque strings.
Signing in with OTP while holding a guest token migrates the guest's watch history to the real
account.

---

## `GET /health`

Public. Checks the application and database.

```json
{
  "ok": true,
  "data": {
    "service": "shabdiz-api",
    "version": "0.1.0",
    "database": true,
    "time": "2026-11-11T14:00:00+00:00"
  }
}
```

---

## `POST /auth/request-otp`

Public. Sends a six-digit code to the given email.

Request:

```json
{ "email": "viewer@example.com" }
```

Response `200`:

```json
{ "ok": true, "data": { "sent": true, "expires_in": 300 } }
```

Rules:

- One request per email per 60 seconds → `429 rate_limited`.
- Code TTL is `OTP_TTL_SECONDS` (60–900, default 300).
- Codes are stored as HMAC-SHA256 digests, never plaintext.
- Delivery failure → `503 mail_failed`.
- Delivery order is configured by `MAIL_DRIVER`: `resend` (default) tries the Resend API, then the
  host SMTP account, then PHP `mail()`; `smtp` and `mail` skip earlier channels; `log` writes the
  code to the private mail log (staging only).

---

## `POST /guest`

Public. Creates a throwaway guest identity so users can browse and watch without signing in.
Login is never forced. Throttled per IP (12 guests per hour) → `429 rate_limited`.

Response `200` (same shape as `verify-otp`):

```json
{
  "ok": true,
  "data": {
    "token": "64-hex-characters",
    "user": { "id": 41, "email": "", "name": "مهمان", "is_guest": true, "created_at": "…" }
  }
}
```

When the guest later signs in via `verify-otp` with this token attached, their watch history and
sessions move to the real account and the guest row is deleted.

---

## `POST /auth/verify-otp`

Public. Exchanges a valid code for a bearer token. Creates the user on first sign-in.

Request:

```json
{ "email": "viewer@example.com", "code": "123456" }
```

Response `200`:

```json
{
  "ok": true,
  "data": {
    "token": "64-hex-characters",
    "user": {
      "id": 12,
      "email": "viewer@example.com",
      "name": "",
      "created_at": "2026-11-11 14:02:10"
    }
  }
}
```

Failures: `422 validation_error`, `422 invalid_code`.

---

## `GET /me`

**Auth.** Returns the current user.

```json
{ "ok": true, "data": { "user": { "id": 12, "email": "viewer@example.com", "name": "", "is_guest": false, "created_at": "2026-11-11 14:02:10" } } }
```

---

## `GET /me/history`

**Auth.** The caller's personal watch progress, newest first. Powers the in-app user panel.

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "screening_id": 7,
        "movie_slug": "the-odyssey",
        "movie_title_fa": "ادیسه",
        "cover_url": "https://…/cover.jpg",
        "position_seconds": 5400,
        "duration_seconds": 9720,
        "percent": 55,
        "completed": false,
        "starts_at_label": "شنبه ۳۰ آبان · ۲۱:۰۰",
        "last_watched_at": "2026-11-21 19:44:02"
      }
    ]
  }
}
```

Progress rows are created by `join` and updated by heartbeats that carry `position_seconds`.
`completed` becomes true at ≥ 95 % of the movie duration. Source/subtitle URLs are never included.

---

## `GET /timeline`

Public. Returns active screenings, newest first, each with its movie.

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "id": 7,
        "room": "main",
        "starts_at": "2026-11-21T17:30:00Z",
        "ends_at": "2026-11-21T20:12:00Z",
        "starts_at_jalali": "1405/08/30",
        "starts_at_label": "شنبه ۳۰ آبان · ۲۱:۰۰",
        "status": "upcoming",
        "movie": {
          "id": 3,
          "slug": "the-odyssey",
          "title_fa": "ادیسه",
          "title_en": "The Odyssey",
          "synopsis_fa": "…",
          "director": "Christopher Nolan",
          "year": 2026,
          "duration_seconds": 9720,
          "imdb_rating": 8.4,
          "rt_rating": 92,
          "cover_url": "https://…/cover.jpg",
          "backdrop_url": "…",
          "trailer_url": "…",
          "status": "published",
          "genres": ["درام", "ماجراجویی"],
          "screening_count": 2
        }
      }
    ]
  }
}
```

`starts_at` and `ends_at` are ISO-8601 UTC. `status` is one of `upcoming`, `live`, `ended`.
`source_url` and `subtitle_url` are intentionally absent from list responses.

---

## `GET /movies/{slug}`

Public. Movie detail plus its active screenings.

```json
{
  "ok": true,
  "data": {
    "movie": { "id": 3, "slug": "the-odyssey", "title_fa": "ادیسه" },
    "screenings": [ { "id": 7, "starts_at": "2026-11-21T17:30:00Z", "status": "upcoming" } ]
  }
}
```

`404 not_found` when the slug does not exist.

---

## `POST /screenings/{id}/join`

**Auth.** Starts or resumes a playback session and returns the seek position. This is the only
endpoint that reveals the stream and subtitle URLs.

Successful response `200`:

```json
{
  "ok": true,
  "data": {
    "session_id": "public-session-id",
    "movie_title_fa": "ادیسه",
    "source_url": "https://cdn.example.com/movie.mkv",
    "subtitle_url": "https://cdn.example.com/fa.srt",
    "subtitle_label": "فارسی",
    "position_seconds": 1920,
    "is_live": true,
    "server_time": "2026-11-21T18:02:00+00:00"
  }
}
```

Failures:

| Status | Code | Reason |
| --- | --- | --- |
| `404` | `not_found` | No such active screening |
| `409` | `not_started` | Joining before the start time |
| `410` | `ended` | Screening is over |
| `503` | `source_missing` | Admin has not set a stream URL |

---

## `GET /screenings/{id}/timeline`

**Auth.** Lightweight synchronization probe.

```json
{
  "ok": true,
  "data": {
    "position_seconds": 1935,
    "is_live": true,
    "status": "live",
    "server_time": "2026-11-21T18:02:15+00:00"
  }
}
```

The client calls this every 15 seconds and seeks only when drift exceeds 2.5 seconds.

---

## `POST /screenings/{id}/heartbeat`

**Auth.** Presence signal, called every 30 seconds during playback. May carry the player position,
which is recorded as personal watch progress only — it never moves the server-owned playback
position.

```json
{ "position_seconds": 1920 }
```

```json
{ "ok": true, "data": { "alive": true } }
```

---

## Synchronization algorithm

```
join(id):
  t0 = server_now
  position = t0 - starts_at_utc        // 0 before start, clamped by status
  open stream
  seek(position)
  play()

every 15 s:
  p = GET /screenings/{id}/timeline.position_seconds
  local = player.getTime() / 1000
  expected = p + (now - server_time)
  if abs(local - expected) > 2.5: seek(expected)

every 30 s:
  POST /screenings/{id}/heartbeat {position_seconds: player.position}
```

Because the server derives position from the stored UTC start time, a viewer who joins at 21:32
starts at minute 32 and matches everyone else. Pausing or buffering is corrected by the next
resync.

---

## Admin (server-rendered, not part of the JSON API)

The admin panel lives under `/admin` and uses session cookies plus CSRF tokens:

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/admin/login` | Login form |
| `POST` | `/admin/login` | Authenticate |
| `POST` | `/admin/logout` | End session |
| `GET` | `/admin` | Dashboard |
| `GET` | `/admin/movies` | Movie list |
| `GET` | `/admin/movies/new` | Create form |
| `POST` | `/admin/movies` | Store movie |
| `GET` | `/admin/screenings` | Screening list |
| `GET` | `/admin/screenings/new` | Create form |
| `POST` | `/admin/screenings` | Store screening (Jalali date + time → UTC) |
| `GET` | `/admin/watching` | Per-user watch progress |
| `GET` | `/admin/users` | Registered users |

Admin responses are HTML, not JSON. API clients must not depend on these routes.
