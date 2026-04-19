#!/bin/bash
# Let's Encrypt 인증서 초기 발급 스크립트
# 실행 전 app.conf 의 YOUR_DOMAIN.com 을 실제 도메인으로 교체하세요.

set -e

DOMAIN="YOUR_DOMAIN.com"
EMAIL="YOUR_EMAIL@example.com"   # Let's Encrypt 만료 알림 수신 주소
STAGING=0                         # 테스트 시 1, 실제 발급 시 0

DATA_PATH="./nginx/certbot"

# ------------------------------------------------------------------
# 1. Certbot 권장 TLS 파라미터 다운로드
# ------------------------------------------------------------------
if [ ! -e "$DATA_PATH/conf/options-ssl-nginx.conf" ]; then
  echo "### Downloading recommended TLS parameters..."
  mkdir -p "$DATA_PATH/conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf \
    -o "$DATA_PATH/conf/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem \
    -o "$DATA_PATH/conf/ssl-dhparams.pem"
fi

# ------------------------------------------------------------------
# 2. 임시 자체 서명 인증서 생성 (Nginx 최초 기동용)
# ------------------------------------------------------------------
echo "### Creating temporary self-signed certificate for $DOMAIN..."
mkdir -p "$DATA_PATH/conf/live/$DOMAIN"
docker compose run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:4096 -days 1 \
    -keyout /etc/letsencrypt/live/$DOMAIN/privkey.pem \
    -out    /etc/letsencrypt/live/$DOMAIN/fullchain.pem \
    -subj '/CN=localhost'" certbot

# ------------------------------------------------------------------
# 3. Nginx 기동
# ------------------------------------------------------------------
echo "### Starting Nginx..."
docker compose up --force-recreate -d nginx

# ------------------------------------------------------------------
# 4. 임시 인증서 삭제 후 실제 Let's Encrypt 인증서 발급
# ------------------------------------------------------------------
echo "### Deleting temporary certificate..."
docker compose run --rm --entrypoint "\
  rm -rf /etc/letsencrypt/live/$DOMAIN && \
  rm -rf /etc/letsencrypt/archive/$DOMAIN && \
  rm -rf /etc/letsencrypt/renewal/$DOMAIN.conf" certbot

STAGING_FLAG=""
if [ $STAGING -eq 1 ]; then
  STAGING_FLAG="--staging"
fi

echo "### Requesting Let's Encrypt certificate for $DOMAIN..."
docker compose run --rm --entrypoint "\
  certbot certonly --webroot \
    -w /var/www/certbot \
    $STAGING_FLAG \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    -d $DOMAIN \
    -d www.$DOMAIN" certbot

# ------------------------------------------------------------------
# 5. Nginx 재기동 (실제 인증서 적용)
# ------------------------------------------------------------------
echo "### Reloading Nginx..."
docker compose exec nginx nginx -s reload

echo "### Done! HTTPS is now active for $DOMAIN"
