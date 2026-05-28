#!/usr/bin/env bash

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${APP_DIR}"

export COMPOSER_ALLOW_SUPERUSER="${COMPOSER_ALLOW_SUPERUSER:-1}"
export APP_ENV="${APP_ENV:-production}"
export APP_DEBUG="${APP_DEBUG:-false}"
export OCTANE_SERVER="${OCTANE_SERVER:-frankenphp}"
export LOG_CHANNEL="${LOG_CHANNEL:-stderr}"
export LOG_STACK="${LOG_STACK:-stderr}"
export LOG_DEPRECATIONS_CHANNEL="${LOG_DEPRECATIONS_CHANNEL:-stderr}"

echo "Preparing Laravel application in ${APP_DIR}"

if [[ ! -f ".env" && -f ".env.example" ]]; then
  cp ".env.example" ".env"
fi

mkdir -p bootstrap/cache storage/app storage/framework/cache storage/framework/sessions storage/framework/views storage/logs database

if [[ -f ".env" ]] && grep -qE '^DB_CONNECTION=sqlite' ".env"; then
  DB_FILE="$(grep -E '^DB_DATABASE=' ".env" | tail -n 1 | cut -d '=' -f 2- | tr -d '\"')"
  if [[ -z "${DB_FILE}" || "${DB_FILE}" == "database/database.sqlite" ]]; then
    DB_FILE="database/database.sqlite"
  fi
  mkdir -p "$(dirname "${DB_FILE}")"
  touch "${DB_FILE}"
fi

composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

if [[ -f ".env" ]] && ! grep -qE '^APP_KEY=base64:.+' ".env"; then
  php artisan key:generate --force
fi

php artisan octane:install --server=frankenphp --force --no-interaction

if [[ -f "package-lock.json" ]]; then
  npm ci
elif [[ -f "pnpm-lock.yaml" ]] && command -v pnpm >/dev/null 2>&1; then
  pnpm install --frozen-lockfile
elif [[ -f "package.json" ]]; then
  npm install
fi

if [[ -f "package.json" ]]; then
  npm run build
fi

if [[ "${DPANEL_RUN_MIGRATIONS:-true}" == "true" ]]; then
  php artisan migrate --force
fi

php artisan storage:link --force || true
php artisan optimize:clear
php artisan optimize

echo "Laravel Octane FrankenPHP build completed."
