#!/bin/bash
# Ежедневный бэкап PostgreSQL «Даром» + копия .env (J-F).
# Cron: 0 3 * * * /opt/darom_app/deploy/scripts/daily_db_backup.sh >> /var/log/darom_backup.log 2>&1

set -euo pipefail

BACKUP_DIR="/opt/darom_backups"
ENV_DIR="${BACKUP_DIR}/env"
RETAIN_DAYS=15
DATE_TAG="$(date +%Y%m%d)"
DB_FILE="${BACKUP_DIR}/darom_${DATE_TAG}.sql"
ENV_FILE="${ENV_DIR}/env_${DATE_TAG}.backup"
ENV_SOURCE="/opt/darom_app/backend/.env"

mkdir -p "$BACKUP_DIR" "$ENV_DIR"
chmod 700 "$BACKUP_DIR" "$ENV_DIR"

if ! docker ps --format '{{.Names}}' | grep -qx 'darom_db'; then
  echo "[$(date -Iseconds)] ERROR: контейнер darom_db не запущен"
  exit 1
fi

docker exec darom_db pg_dump -U darom darom > "$DB_FILE"
chmod 600 "$DB_FILE"

if [[ -f "$ENV_SOURCE" ]]; then
  cp "$ENV_SOURCE" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
else
  echo "[$(date -Iseconds)] WARN: .env не найден: $ENV_SOURCE"
fi

find "$BACKUP_DIR" -maxdepth 1 -name 'darom_*.sql' -type f -mtime +"${RETAIN_DAYS}" -delete
find "$ENV_DIR" -name 'env_*.backup' -type f -mtime +"${RETAIN_DAYS}" -delete

echo "[$(date -Iseconds)] OK db=$(du -h "$DB_FILE" | cut -f1) retained=${RETAIN_DAYS}d"
