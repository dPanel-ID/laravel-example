#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${APP_DIR}"

HOST="${APP_HOST:-0.0.0.0}"
PORT="${PORT:-${APP_PORT:-8000}}"
WORKERS="${OCTANE_WORKERS:-auto}"
MAX_REQUESTS="${OCTANE_MAX_REQUESTS:-500}"

export OCTANE_SERVER="${OCTANE_SERVER:-frankenphp}"

if [[ ! -f ".env" && -f ".env.example" ]]; then
  cp ".env.example" ".env"
fi

if [[ ! -d "vendor" ]]; then
  echo "Missing vendor directory. Run ./scripts/build.sh before starting the service." >&2
  exit 1
fi

mkdir -p bootstrap/cache storage/logs

command=(php artisan octane:frankenphp --host="${HOST}" --port="${PORT}" --workers="${WORKERS}" --max-requests="${MAX_REQUESTS}")

if [[ -n "${OCTANE_CADDYFILE:-}" ]]; then
  command+=(--caddyfile="${OCTANE_CADDYFILE}")
fi

if [[ -n "${OCTANE_LOG_LEVEL:-}" ]]; then
  command+=(--log-level="${OCTANE_LOG_LEVEL}")
fi

echo "Starting Laravel Octane with FrankenPHP on ${HOST}:${PORT}"
exec "${command[@]}"
