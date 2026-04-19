#!/bin/bash
# PostgreSQL 자동 백업 스크립트
# 보관: 최근 7개 일간 백업 + 최근 4개 주간 백업(일요일)
#
# 환경변수 (docker-compose에서 주입, 또는 .env 파일 사용):
#   POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, POSTGRES_HOST, POSTGRES_PORT
#   BACKUP_DIR  — 백업 파일 저장 디렉토리 (default: /backups)

set -euo pipefail

: "${POSTGRES_HOST:=db}"
: "${POSTGRES_PORT:=5432}"
: "${POSTGRES_USER:=smart_user}"
: "${POSTGRES_PASSWORD:=smart_password}"
: "${POSTGRES_DB:=smart_inspection_db}"
: "${BACKUP_DIR:=/backups}"

export PGPASSWORD="$POSTGRES_PASSWORD"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DOW=$(date +"%u")   # 1=Mon … 7=Sun

mkdir -p "$BACKUP_DIR/daily" "$BACKUP_DIR/weekly"

# ------------------------------------------------------------------
# 1. 일간 백업
# ------------------------------------------------------------------
DAILY_FILE="$BACKUP_DIR/daily/${POSTGRES_DB}_${TIMESTAMP}.sql.gz"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting daily backup → $DAILY_FILE"

pg_dump \
  -h "$POSTGRES_HOST" \
  -p "$POSTGRES_PORT" \
  -U "$POSTGRES_USER" \
  -d "$POSTGRES_DB" \
  --no-password \
  | gzip -9 > "$DAILY_FILE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Daily backup done ($(du -sh "$DAILY_FILE" | cut -f1))"

# ------------------------------------------------------------------
# 2. 주간 백업 (일요일에만)
# ------------------------------------------------------------------
if [ "$DOW" -eq 7 ]; then
  WEEKLY_FILE="$BACKUP_DIR/weekly/${POSTGRES_DB}_weekly_${TIMESTAMP}.sql.gz"
  cp "$DAILY_FILE" "$WEEKLY_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Weekly backup saved → $WEEKLY_FILE"

  # 주간 백업 4개 초과분 삭제
  ls -1t "$BACKUP_DIR/weekly/"*.sql.gz 2>/dev/null | tail -n +5 | xargs -r rm --
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Old weekly backups pruned (kept 4)"
fi

# ------------------------------------------------------------------
# 3. 일간 백업 7개 초과분 삭제
# ------------------------------------------------------------------
ls -1t "$BACKUP_DIR/daily/"*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm --
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Old daily backups pruned (kept 7)"
