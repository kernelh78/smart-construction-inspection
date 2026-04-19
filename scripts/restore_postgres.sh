#!/bin/bash
# PostgreSQL 백업 복구 스크립트
#
# 사용법:
#   ./restore_postgres.sh <backup_file.sql.gz>
#
# 예시:
#   ./restore_postgres.sh backups/daily/smart_inspection_db_20260419_030000.sql.gz

set -euo pipefail

: "${POSTGRES_HOST:=localhost}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_USER:=smart_user}"
: "${POSTGRES_PASSWORD:=smart_password}"
: "${POSTGRES_DB:=smart_inspection_db}"

BACKUP_FILE="${1:-}"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: $0 <backup_file.sql.gz>"
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: backup file not found: $BACKUP_FILE"
  exit 1
fi

export PGPASSWORD="$POSTGRES_PASSWORD"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restoring $BACKUP_FILE → $POSTGRES_DB on $POSTGRES_HOST:$POSTGRES_PORT"

# 기존 연결 강제 종료 후 DB 재생성
psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d postgres <<SQL
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '$POSTGRES_DB' AND pid <> pg_backend_pid();

DROP DATABASE IF EXISTS "$POSTGRES_DB";
CREATE DATABASE "$POSTGRES_DB" OWNER "$POSTGRES_USER";
SQL

# 백업 복구
gunzip -c "$BACKUP_FILE" | psql \
  -h "$POSTGRES_HOST" \
  -p "$POSTGRES_PORT" \
  -U "$POSTGRES_USER" \
  -d "$POSTGRES_DB" \
  --no-password

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restore completed successfully"
