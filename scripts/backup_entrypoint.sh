#!/bin/sh
# Docker backup 컨테이너 entrypoint
# cron 데몬을 foreground로 실행하며, 매일 새벽 3시에 backup_postgres.sh를 실행합니다.

set -e

# crontab 등록
echo "0 3 * * * /scripts/backup_postgres.sh >> /var/log/backup.log 2>&1" | crontab -

echo "[entrypoint] Backup cron registered: daily at 03:00"
echo "[entrypoint] Starting crond..."

# foreground로 cron 실행 (컨테이너가 종료되지 않도록)
exec crond -f -l 2
