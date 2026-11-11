#!/usr/bin/env bash
# ============================================================
# ShabDiz — deploy the PHP admin panel + API over FTP.
#
# Usage:
#   bash deploy.sh all     # code + .env + install/migrate + HTTP checks
#   bash deploy.sh code    # sync app / migrations / scripts / public
#   bash deploy.sh env     # build and upload the server .env
#   bash deploy.sh setup   # one-time installer (dirs, migrations, admin)
#   bash deploy.sh check   # HTTP probes
#
# Fill config.env first (copy from config.env.example).
# Target in production: https://apps.webiro.ir/shabdiz
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if [[ ! -f "$ROOT/config.env" ]]; then
  echo "❌ config.env not found — copy config.env.example and fill it."
  exit 1
fi

# shellcheck disable=SC1091
set -a
source "$ROOT/config.env"
set +a

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "❌ missing command: $1"; exit 1; }
}

sed_file() {
  local expr="$1"
  shift
  if [[ "$(uname)" == "Darwin" ]]; then
    sed -i '' "$expr" "$@"
  else
    sed -i "$expr" "$@"
  fi
}

persist_auto() {
  local key="$1" val="$2"
  if grep -q "^${key}=" "$ROOT/config.env"; then
    sed_file "s|^${key}=.*|${key}=${val}|" "$ROOT/config.env"
  else
    printf '%s=%s\n' "$key" "$val" >> "$ROOT/config.env"
  fi
  echo "🔑 $key generated and saved to config.env"
}

ensure_tokens() {
  if [[ -z "${APP_KEY:-}" ]]; then
    need openssl
    APP_KEY="$(openssl rand -hex 32)"
    persist_auto APP_KEY "$APP_KEY"
  fi
  if [[ -z "${DEPLOY_TOKEN:-}" ]]; then
    need openssl
    DEPLOY_TOKEN="$(openssl rand -hex 16)"
    persist_auto DEPLOY_TOKEN "$DEPLOY_TOKEN"
  fi
}

SITE_URL="${SITE_URL%/}"
APP_BASE_PATH="${APP_BASE_PATH:-/shabdiz}"
CURL_FLAGS=(--connect-timeout 30)
if [[ "${CURL_INSECURE:-false}" == "true" ]]; then
  CURL_FLAGS+=(-k)
fi
if [[ -n "${SITE_RESOLVE_IP:-}" ]]; then
  SITE_HOST="${SITE_URL#https://}"
  SITE_HOST="${SITE_HOST#http://}"
  CURL_FLAGS+=(--resolve "${SITE_HOST}:443:${SITE_RESOLVE_IP}" --resolve "${SITE_HOST}:80:${SITE_RESOLVE_IP}")
fi

http_get() {
  local url="$1" out rc
  need curl
  out="$(curl -sS "${CURL_FLAGS[@]}" --max-time 120 -w $'\n%{http_code}' "$url")" && rc=0 || rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "❌ connection failed (curl exit $rc): $url"
    return 1
  fi
  HTTP_CODE="${out##*$'\n'}"
  HTTP_BODY="${out%$'\n'*}"
  return 0
}

lftp_session() {
  need lftp
  local ssl="${FTP_SSL:-false}"
  local ssl_line=""
  if [[ "$ssl" == "true" ]]; then
    ssl="yes"
    ssl_line="set ftp:ssl-force true
set ftp:ssl-protect-data true
set ssl:check-hostname false"
  else
    ssl="no"
  fi
  lftp -u "$FTP_USER","$FTP_PASS" -p "${FTP_PORT:-21}" "$FTP_HOST" <<EOF
set ftp:ssl-allow $ssl
set ftp:passive-mode ${FTP_PASSIVE:-true}
set net:max-retries 2
set net:timeout 60
set xfer:clobber on
${ssl_line}
$1
bye
EOF
}

MIRROR_X='--exclude "^\.DS_Store$" --exclude "(^|/)\.git($|/)"'

cmd_code() {
  echo "=== Deploy code → ${FTP_REMOTE_ROOT} ==="
  lftp_session "
mkdir -p -f ${FTP_REMOTE_ROOT}
mirror -R --delete --parallel=3 $MIRROR_X backend/app        ${FTP_REMOTE_ROOT}/app
mirror -R --delete --parallel=3 $MIRROR_X backend/migrations ${FTP_REMOTE_ROOT}/migrations
mirror -R --delete --parallel=3 $MIRROR_X backend/scripts    ${FTP_REMOTE_ROOT}/scripts
put backend/public/index.php  -o ${FTP_REMOTE_ROOT}/index.php
put backend/public/.htaccess  -o ${FTP_REMOTE_ROOT}/.htaccess
" || { echo "❌ code sync failed"; exit 1; }
  echo "✅ code synced (uploads and .env are never touched)"
}

cmd_env() {
  echo "=== Deploy server .env ==="
  ensure_tokens
  need php
  need lftp
  for v in DB_NAME DB_USER DB_PASS ADMIN_EMAIL ADMIN_PASSWORD; do
    if [[ -z "${!v:-}" ]]; then echo "❌ ${v} is empty in config.env"; exit 1; fi
  done

  local hash tmp
  hash="$(php -r 'echo password_hash($argv[1], PASSWORD_DEFAULT);' "$ADMIN_PASSWORD")"
  tmp="$(mktemp)"
  {
    printf 'APP_ENV=production\n'
    printf 'APP_DEBUG=0\n'
    printf 'APP_URL=%s\n' "$SITE_URL"
    printf 'APP_BASE_PATH=%s\n' "$APP_BASE_PATH"
    printf 'APP_KEY=%s\n' "$APP_KEY"
    printf 'APP_TIMEZONE=Asia/Tehran\n'
    printf 'DB_HOST=%s\n' "${DB_HOST:-localhost}"
    printf 'DB_PORT=%s\n' "${DB_PORT:-3306}"
    printf 'DB_NAME=%s\n' "$DB_NAME"
    printf 'DB_USER=%s\n' "$DB_USER"
    printf 'DB_PASS=%s\n' "$DB_PASS"
    printf 'MAIL_DRIVER=%s\n' "${MAIL_DRIVER:-resend}"
    printf 'MAIL_FROM=%s\n' "${MAIL_FROM:-no-reply@webiro.ir}"
    printf 'RESEND_API_KEY=%s\n' "${RESEND_API_KEY:-}"
    printf 'SMTP_HOST=%s\n' "${SMTP_HOST:-}"
    printf 'SMTP_PORT=%s\n' "${SMTP_PORT:-587}"
    printf 'SMTP_USER=%s\n' "${SMTP_USER:-}"
    printf 'SMTP_PASS=%s\n' "${SMTP_PASS:-}"
    printf 'SMTP_ENCRYPTION=%s\n' "${SMTP_ENCRYPTION:-tls}"
    printf 'OTP_TTL_SECONDS=%s\n' "${OTP_TTL_SECONDS:-300}"
    printf 'ADMIN_EMAIL=%s\n' "$ADMIN_EMAIL"
    printf 'ADMIN_NAME=%s\n' "${ADMIN_NAME:-مدیر شب‌دیز}"
    printf 'ADMIN_PASSWORD_HASH=%s\n' "$hash"
  } > "$tmp"
  lftp_session "put \"$tmp\" -o \"${FTP_REMOTE_ROOT}/.env\""
  rm -f "$tmp"
  echo "✅ server .env uploaded (DB: ${DB_NAME}, admin: ${ADMIN_EMAIL})"
  echo "   If SSH is available: chmod 600 <root>/.env"
}

cmd_setup() {
  echo "=== Server bootstrap + migrations ==="
  ensure_tokens
  need lftp
  local rand phpfile out code
  rand="$(openssl rand -hex 6)"
  phpfile="$ROOT/dist/shabdiz-setup-${rand}.php"
  mkdir -p "$ROOT/dist"
  cat > "$phpfile" <<'PHPEOF'
<?php
// ShabDiz one-time installer — self-deletes after a successful run.
$__token = '__TOKEN__';
if (!isset($_GET['t']) || !hash_equals($__token, (string) $_GET['t'])) {
    http_response_code(403);
    exit('forbidden');
}
ignore_user_abort(true);
require __DIR__ . '/app/bootstrap.php';
header('Content-Type: application/json; charset=utf-8');
try {
    echo json_encode(\Shabdiz\Support\Installer::run(), JSON_UNESCAPED_UNICODE);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['ok' => false, 'error' => $e->getMessage()], JSON_UNESCAPED_UNICODE);
}
@unlink(__FILE__);
PHPEOF
  sed_file "s/__TOKEN__/${DEPLOY_TOKEN}/" "$phpfile"
  lftp_session "put \"$phpfile\" -o \"${FTP_REMOTE_ROOT}/shabdiz-setup-${rand}.php\""
  rm -f "$phpfile"

  http_get "${SITE_URL}/shabdiz-setup-${rand}.php?t=${DEPLOY_TOKEN}" || {
    echo "   Temporary installer may remain on the server. Delete it via FTP: shabdiz-setup-${rand}.php"
    exit 1
  }
  code="$HTTP_CODE"
  lftp_session "rm -f ${FTP_REMOTE_ROOT}/shabdiz-setup-${rand}.php" >/dev/null 2>&1 || true
  if [[ "$code" != 2* ]]; then
    echo "❌ installer failed (HTTP $code):"
    echo "$HTTP_BODY" | head -c 1200
    echo
    exit 1
  fi
  if command -v php >/dev/null 2>&1; then
    echo "$HTTP_BODY" | php -r '$j=json_decode(stream_get_contents(STDIN),true); echo implode("\n  · ", $j["out"] ?? [$j["error"] ?? "unreadable response"]), "\n";'
  else
    echo "$HTTP_BODY"
  fi
  echo "✅ server installed"
}

cmd_check() {
  echo "=== HTTP check ${SITE_URL} ==="
  local failures=0
  while IFS='|' read -r path expect label; do
    [[ -z "$path" ]] && continue
    http_get "${SITE_URL}${path}" >/dev/null 2>&1 || true
    if [[ "${HTTP_CODE:-000}" == "$expect" ]]; then
      echo "  ✅ ${path} → ${HTTP_CODE} (${label})"
    else
      echo "  ❌ ${path} → ${HTTP_CODE:-000} (expected ${expect}: ${label})"
      failures=$((failures + 1))
    fi
  done <<'CHECKS'
/|302|root → admin
/admin/login|200|admin login
/api/health|200|API health
/app/bootstrap.php|403|private app directory blocked
/.env|403|environment file blocked
CHECKS

  if [[ $failures -ne 0 ]]; then
    echo "❌ some checks failed"
    exit 1
  fi
  echo "✅ all checks passed"
}

cmd_all() {
  echo "════ ShabDiz deploy → ${SITE_URL} ════"
  cmd_code
  cmd_env
  cmd_setup
  cmd_check
  echo ""
  echo "🎉 done — ${SITE_URL}/admin/login"
}

case "${1:-}" in
  all)   cmd_all ;;
  code)  cmd_code ;;
  env)   cmd_env ;;
  setup) cmd_setup ;;
  check) cmd_check ;;
  *)
    echo "Usage: bash deploy.sh {all|code|env|setup|check}"
    exit 1
    ;;
esac
