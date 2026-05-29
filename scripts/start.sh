#!/usr/bin/env bash

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${APP_DIR}"

HOST="${APP_HOST:-0.0.0.0}"
PORT="${PORT:-${APP_PORT:-8000}}"
WORKERS="${OCTANE_WORKERS:-auto}"
MAX_REQUESTS="${OCTANE_MAX_REQUESTS:-500}"

export OCTANE_SERVER="${OCTANE_SERVER:-frankenphp}"
export LOG_CHANNEL="${LOG_CHANNEL:-stderr}"
export LOG_STACK="${LOG_STACK:-stderr}"
export LOG_DEPRECATIONS_CHANNEL="${LOG_DEPRECATIONS_CHANNEL:-stderr}"

if [[ ! -f ".env" && -f ".env.example" ]]; then
  cp ".env.example" ".env"
fi

if [[ ! -d "vendor" ]]; then
  echo "Missing vendor directory. Run ./scripts/build.sh before starting the service." >&2
  exit 1
fi

mkdir -p bootstrap/cache storage/logs

php_args=(-d display_errors=stderr -d log_errors=1 -d error_log=/dev/stderr)
command=(php "${php_args[@]}" artisan octane:frankenphp --host="${HOST}" --port="${PORT}" --workers="${WORKERS}" --max-requests="${MAX_REQUESTS}")

if [[ -n "${OCTANE_CADDYFILE:-}" ]]; then
  command+=(--caddyfile="${OCTANE_CADDYFILE}")
fi

if [[ -n "${OCTANE_LOG_LEVEL:-}" ]]; then
  command+=(--log-level="${OCTANE_LOG_LEVEL}")
fi

echo "Starting Laravel Octane with FrankenPHP on ${HOST}:${PORT}"
exec "${command[@]}"
