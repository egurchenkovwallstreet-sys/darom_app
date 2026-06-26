#!/bin/bash
# Обновление backend на сервере Timeweb (вызывается из POST /api/deploy-backend).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo ">>> git fetch origin main"
git fetch origin main

echo ">>> git reset --hard origin/main"
git reset --hard origin/main

echo ">>> npm install"
cd backend
npm install --omit=dev

echo ">>> pm2 restart darom-api --update-env"
pm2 restart darom-api --update-env

echo ">>> done"
node -e "console.log(require('./src/security_version.js'))"
