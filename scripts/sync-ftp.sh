#!/usr/bin/env bash
# ============================================================
# Shabdiz deploy helper — syncs backend/ to the host over FTP
# Target: https://apps.webiro.ir/shabdiz
#
# Usage:
#   bash scripts/sync-ftp.sh           # dry-run (shows what would change)
#   bash scripts/sync-ftp.sh --apply   # upload for real
#
# Safety rules:
#   • backend/config.php       NEVER uploaded — live credentials stay intact
#   • backend/data/*.sqlite    never uploaded (SQLite database with user data)
#   • .git/                    never uploaded
#   • .DS_Store                never uploaded (macOS metadata)
#   • everything else is mirrored with --delete (removed files get cleaned)
#
# Requires lftp:  brew install lftp   |   apt install lftp
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/scripts/ftp.env" ]]; then
  echo "❌ scripts/ftp.env not found. Copy ftp.env.example → ftp.env and fill values."
  exit 1
fi

# shellcheck disable=SC1091
set -a
source "$ROOT/scripts/ftp.env"
set +a

: "${FTP_HOST:?FTP_HOST is missing in scripts/ftp.env}"
: "${FTP_USER:?FTP_USER is missing in scripts/ftp.env}"
: "${FTP_PASS:?FTP_PASS is missing in scripts/ftp.env}"
FTP_REMOTE_DIR="${FTP_REMOTE_DIR:-/shabdiz}"
FTP_PASSIVE="${FTP_PASSIVE:-true}"

DRY_RUN_FLAG="--dry-run"
if [[ "${1:-}" == "--apply" ]]; then
  DRY_RUN_FLAG=""
  echo "=== Shabdiz deploy (apply) ==="
  echo "Target: $FTP_HOST$FTP_REMOTE_DIR"
else
  echo "=== Shabdiz deploy (dry-run — add --apply to upload) ==="
  echo "Target: $FTP_HOST$FTP_REMOTE_DIR"
fi

lftp -u "$FTP_USER","$FTP_PASS" -p "${FTP_PORT:-21}" "$FTP_HOST" <<EOF
set ftp:ssl-allow no
set ftp:passive-mode ${FTP_PASSIVE}
set net:timeout 15
set net:max-retries 3
mirror -R ${DRY_RUN_FLAG} --delete --verbose \
  --exclude ^config\.php$ \
  --exclude ^data/.*\.sqlite$ \
  --exclude ^data/.*\.db$ \
  --exclude ^\.git/ \
  --exclude-glob .DS_Store \
  --exclude-glob *.md \
  --exclude-glob *.zip \
  "$ROOT/backend" "$FTP_REMOTE_DIR"
bye
EOF

echo "✅ done"