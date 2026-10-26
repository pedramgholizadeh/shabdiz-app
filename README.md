# Shabdiz 🌌

<p align="center">
  <img src="assets/logo.png" alt="Shabdiz" width="140">
</p>

<p align="center">
  <strong>Cinema without borders, one click away.</strong><br>
  A modern Persian streaming app for movies, series and live TV — with a liquid-glass design language.
</p>

<p align="center">
  <a href="https://github.com/pedramgholizadeh/shabdiz-app/releases"><img src="https://img.shields.io/github/v/release/pedramgholizadeh/shabdiz-app?style=flat-square" alt="Release"></a>
  <a href="https://github.com/pedramgholizadeh/shabdiz-app/releases"><img src="https://img.shields.io/github/downloads/pedramgholizadeh/shabdiz-app/total?style=flat-square" alt="Downloads"></a>
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey?style=flat-square" alt="Platforms">
  <img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="License">
</p>

---

## ✨ What is Shabdiz?

Shabdiz is a cross-platform streaming client built with **Flutter** and a **pure-PHP backend**. The app talks only to the Shabdiz backend — the upstream content API key lives exclusively on the server and is never shipped inside the client binary.

Everything you see was designed around three ideas:

1. **Liquid Glass** — frosted, translucent layers floating over a cinematic dark backdrop (think Apple TV meets Netflix).
2. **Privacy & security by architecture** — no API keys in the client, token-based sessions, optional login.
3. **Iran-first, user-friendly** — full RTL Persian UI, geo-gating with a friendly VPN notice, and instant streaming.

## 🎬 Features

- **Movies & Series** — browsable catalogs with genre filtering, sorting (latest / year / IMDb) and infinite scroll.
- **Live TV** — hundreds of live channels grouped by country, playable in-app or via VLC.
- **Search** — fast full-text search across movies and series.
- **Browse by Country** — explore content from any country with flag-based navigation.
- **Optional account** — sign in with just your email; a 6-digit code arrives via [Resend](https://resend.com). No passwords, ever.
- **Cloud favorites** — your watchlist syncs to your account and follows you across devices. Guests get local favorites.
- **Rich profiles** — display name, avatar initial, linked device IDs.
- **Built-in player** — powered by `media_kit`, with external playback via VLC (Windows / macOS / Linux).
- **VPN gate** — the app checks your IP region before loading and politely asks you to disable your VPN if you're outside Iran.
- **Device registry** — every installation registers itself (per platform) so installs can be tracked without forcing login.
- **Web admin panel** — `/admin` on the backend: install reports per platform/day, user management, device management.
- **Theme** — cinematic dark-first design, light mode included, system-follow mode.

## 🔒 Security Model

```
┌────────────┐   Bearer token    ┌─────────────────────┐   API key (server-only)   ┌──────────────┐
│  Flutter   │ ────────────────▶ │   Shabdiz Backend   │ ────────────────────────▶ │ Content API  │
│   client   │                   │   (pure PHP)        │                           │              │
└────────────┘                   └─────────────────────┘                           └──────────────┘
```

- The upstream **API key never reaches the client** — all content requests are proxied and rate-limited by the backend.
- Sessions are random 256-bit tokens (30-day expiry) stored server-side; OTP codes expire in 5 minutes with attempt limits.
- Full backend deployment guide: [`backend/README.md`](backend/README.md).

## 📥 Download

Grab the latest installers from the [**Releases**](https://github.com/pedramgholizadeh/shabdiz-app/releases) page — built automatically by GitHub Actions:

| Platform | File |
|---|---|
| 🤖 Android | `Shabdiz-android.apk` |
| 🪟 Windows | `Shabdiz-windows-setup.zip` |
| 🍎 macOS | `Shabdiz-macos.zip` (Apple Silicon & Intel) |

> **Windows users:** if the app doesn't start, install the [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe) and try again.

## 🛠 Build from Source

```bash
git clone https://github.com/pedramgholizadeh/shabdiz-app.git
cd shabdiz-app
flutter pub get
flutter build apk --release      # Android
flutter build macos --release    # macOS
flutter build windows --release  # Windows
```

Point the client at a backend:

```bash
flutter run --dart-define=SHABDIZ_API=https://apps.webiro.ir/shabdiz
```

## 🧱 Tech Stack

- **Flutter** (Material 3) + `go_router` + `provider`
- **media_kit** for playback, **url_launcher/share_plus** for integrations
- **Pure PHP 8.1+ backend** — no framework, SQLite storage, Resend for email OTP

## 📄 License

[MIT](LICENSE)
