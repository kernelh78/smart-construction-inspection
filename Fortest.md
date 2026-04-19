# 미테스트 항목 (Fortest.md)

> 구현 완료되었으나 실제 환경 테스트가 필요한 항목들을 기술합니다.
> 각 항목별 사전 준비사항과 테스트 방법을 기술합니다.

---

## 1. OCR (광학 문자 인식)

### 사전 준비
```bash
# macOS
brew install tesseract tesseract-lang

# Ubuntu/Debian
sudo apt-get install tesseract-ocr tesseract-ocr-kor

# 설치 확인
tesseract --version
tesseract --list-langs  # kor 항목 확인
```

### 테스트 방법

#### 1-1. 백엔드 OCR 단독 테스트
```python
# smart_inspection/ 디렉토리에서
source venv/bin/activate
python -c "
from app.core.ocr import extract_text
with open('test_image.jpg', 'rb') as f:
    text = extract_text(f.read())
print('OCR 결과:', text)
"
```

#### 1-2. API 엔드포인트 테스트
```bash
curl -X POST http://localhost:8000/api/v1/inspections/{inspection_id}/photos \
  -H "Authorization: Bearer {token}" \
  -F "file=@test_image.jpg"
```

#### 1-3. Flutter 앱 테스트
- `결함 등록` 화면 진입
- **사진 촬영 후 텍스트 인식 (OCR)** 버튼 탭
- 에뮬레이터 가상 카메라로 촬영
- 설명 필드에 OCR 결과 자동 입력 확인

### 확인 포인트
- [ ] Tesseract 설치 및 한국어 언어팩 정상 로드
- [ ] 한글 텍스트 인식 정확도 확인
- [ ] pytesseract 미설치 시 graceful fallback (빈 문자열 반환) 동작 확인
- [ ] OCR 결과가 `ocr_result` DB 필드에 정상 저장되는지 확인

---

## 2. STT (음성 텍스트 변환)

### 사전 준비
- Android 에뮬레이터에서 마이크 권한 허용
- `AndroidManifest.xml`에 `RECORD_AUDIO` 권한 선언됨 (완료)
- 에뮬레이터 설정 → Extended Controls → Microphone 활성화

### 테스트 방법

#### 2-1. 점검 등록 화면 STT 테스트
- `점검 기록 등록` 화면 진입
- **메모 (선택)** 필드 우측 마이크 아이콘 탭
- 권한 요청 팝업 → 허용
- 한국어로 말하기 (예: "콘크리트 벽면 균열 발견")
- 필드에 인식된 텍스트 자동 입력 확인

#### 2-2. 결함 등록 화면 STT 테스트
- `결함 등록` 화면 진입 → 결함 설명 필드 마이크 아이콘 탭
- 음성 인식 후 설명 필드 자동 입력 확인

### 확인 포인트
- [ ] `SpeechToText.initialize()` 반환값이 `true`인지 확인
- [ ] 한국어(`ko_KR`) 로케일 인식 정상 동작 확인
- [ ] 인식 중 마이크 아이콘이 빨간색으로 변경되는지 확인
- [ ] STT 불가 환경(권한 거부)에서 마이크 버튼이 표시되지 않는지 확인

---

## 3. S3 이미지 업로드

### 사전 준비
```bash
cp smart_inspection/.env.example smart_inspection/.env
# .env 파일 편집:
# AWS_ACCESS_KEY_ID=실제_액세스_키
# AWS_SECRET_ACCESS_KEY=실제_시크릿_키
# AWS_REGION=ap-northeast-2
# S3_BUCKET_NAME=실제_버킷_이름
```

### 테스트 방법

#### 3-1. S3 설정 확인
```python
source venv/bin/activate
python -c "
from app.core.storage import is_configured
print('S3 설정됨:', is_configured())
"
```

#### 3-2. S3 업로드 단독 테스트
```python
source venv/bin/activate
python -c "
from app.core.storage import upload_file, get_presigned_url
with open('test_image.jpg', 'rb') as f:
    key = upload_file(f.read(), 'test/test_image.jpg', 'image/jpeg')
    print('업로드 키:', key)
    url = get_presigned_url(key)
    print('pre-signed URL:', url)
"
```

### 확인 포인트
- [ ] `is_configured()` 가 `True` 반환 확인
- [ ] S3 버킷에 `inspections/{id}/` 경로로 파일 생성되는지 확인
- [ ] pre-signed URL이 브라우저에서 열리는지 확인 (1시간 유효)
- [ ] S3 미설정 시 s3_key만 DB 저장, url은 `null` 반환 확인

---

## 4. pytest 백엔드 테스트 (Phase 3 신규)

### 테스트 실행
```bash
cd smart_inspection
source venv/bin/activate
python -m pytest tests/ -v
```

### 기대 결과
```
tests/test_auth.py::test_login_success PASSED
tests/test_auth.py::test_login_wrong_password PASSED
... (28개 전체)
======================== 28 passed in 6.18s ========================
```

### CI 자동 실행 확인
- [ ] GitHub에 push 시 GitHub Actions `backend` job 자동 실행 확인
- [ ] PR 생성 시 pytest 결과가 Check로 표시되는지 확인
- [ ] 실패하는 테스트 추가 후 CI가 실패하는지 확인 (정상 동작 검증)

### 테스트 커버리지 확인
```bash
pip install pytest-cov
python -m pytest tests/ --cov=app --cov-report=term-missing
```

### 확인 포인트
- [ ] 28개 테스트 전체 통과
- [ ] SQLite in-memory로 PostgreSQL 없이 실행 가능 확인
- [ ] 테스트 간 DB 독립성 확인 (autouse fixture)
- [ ] admin/inspector 권한 분리 테스트 정상 동작

---

## 5. Nginx + HTTPS (Phase 3 신규)

### 사전 준비
- 도메인 구입 및 DNS A 레코드 설정 (서버 IP 연결)
- `nginx/conf.d/app.conf`의 `YOUR_DOMAIN.com` → 실제 도메인 교체
- `nginx/init-letsencrypt.sh`의 `DOMAIN`, `EMAIL` 변수 설정

### 테스트 방법

#### 5-1. HTTP → HTTPS 리다이렉트 확인
```bash
curl -I http://YOUR_DOMAIN.com/
# 기대: HTTP/1.1 301 Moved Permanently
# Location: https://YOUR_DOMAIN.com/
```

#### 5-2. HTTPS 접근 확인
```bash
curl -I https://YOUR_DOMAIN.com/
# 기대: HTTP/2 200
```

#### 5-3. API 프록시 확인
```bash
curl https://YOUR_DOMAIN.com/api/v1/auth/me \
  -H "Authorization: Bearer {token}"
```

#### 5-4. WebSocket 프록시 확인
```javascript
// 브라우저 콘솔에서
const ws = new WebSocket("wss://YOUR_DOMAIN.com/ws/sites/{site_id}/live?token={token}");
ws.onopen = () => console.log("WS 연결 성공");
```

#### 5-5. SSL 인증서 등급 확인
- https://www.ssllabs.com/ssltest/ 에서 도메인 입력 → A등급 이상 확인

### 확인 포인트
- [ ] HTTP → HTTPS 301 리다이렉트 동작
- [ ] Let's Encrypt 인증서 발급 성공 (STAGING=0)
- [ ] HSTS 헤더 (`Strict-Transport-Security`) 응답 확인
- [ ] `/api/` 프록시 정상 동작
- [ ] `/ws/` WebSocket 프록시 업그레이드 성공
- [ ] 인증서 자동 갱신 (certbot renew --dry-run) 성공

---

## 6. PostgreSQL 자동 백업 (Phase 3 신규)

### 사전 준비
```bash
# Docker 스택 실행
docker compose up -d db backup
```

### 테스트 방법

#### 6-1. 수동 백업 실행
```bash
docker compose exec backup /scripts/backup_postgres.sh
# 기대 로그:
# [2026-04-19 03:00:00] Starting daily backup → /backups/daily/smart_inspection_db_20260419_030000.sql.gz
# [2026-04-19 03:00:01] Daily backup done (48K)
```

#### 6-2. 백업 파일 확인
```bash
docker compose exec backup ls -lh /backups/daily/
# 기대: .sql.gz 파일 1개 이상 존재
```

#### 6-3. 복구 테스트
```bash
# 백업 파일로 DB 복구
./scripts/restore_postgres.sh backups/daily/smart_inspection_db_20260419_030000.sql.gz
# 복구 후 API 정상 동작 확인
curl http://localhost:8000/api/v1/sites/ -H "Authorization: Bearer {token}"
```

#### 6-4. 보관 정책 확인
```bash
# 일간 백업 8개 이상 생성 후 7개만 남는지 확인
for i in $(seq 1 9); do
  docker compose exec backup /scripts/backup_postgres.sh
done
docker compose exec backup ls /backups/daily/ | wc -l
# 기대: 7
```

### 확인 포인트
- [ ] 수동 백업 실행 시 `.sql.gz` 파일 생성 확인
- [ ] 백업 파일 `gunzip`으로 압축 해제 가능 확인
- [ ] 복구 후 데이터 정합성 확인 (테이블 수, 레코드 수)
- [ ] 일간 7개 보관 정책 동작 확인
- [ ] 주간(일요일) 백업 4개 보관 정책 동작 확인
- [ ] cron 스케줄 등록 확인: `docker compose exec backup crontab -l`

---

## 7. Next.js 웹 대시보드 E2E (Phase 3 신규)

### 사전 준비
```bash
# 백엔드 실행
cd smart_inspection && source venv/bin/activate
python main.py

# 웹 실행
cd web && npm run dev
```

### 테스트 방법

#### 7-1. 로그인 플로우
1. http://localhost:3000 접속
2. → `/login`으로 자동 리다이렉트 확인
3. `admin@smartinspection.com` / `admin123` 입력 후 로그인
4. → `/dashboard`로 이동, 대시보드 카드 표시 확인

#### 7-2. 대시보드 데이터 표시
- 요약 카드 4개 (현장/점검/대기/미결결함) 숫자 표시 확인
- 주간 BarChart 데이터 표시 확인
- 결함 PieChart 표시 확인 (데이터 없으면 "미결 결함 없음" 메시지 표시)
- 최근 점검 기록 테이블 표시 확인

#### 7-3. 현장 목록/상세
1. 사이드바 `현장 관리` 클릭
2. 현장 목록 테이블 표시 확인
3. `보기 →` 링크 클릭 → 현장 상세 페이지 이동
4. 해당 현장의 점검 기록 목록 표시 확인

#### 7-4. 점검 상세 + WebSocket 실시간 알림
1. 점검 상세 페이지 진입
2. 다른 탭/앱에서 해당 점검에 결함 등록 (API 호출)
3. 웹 대시보드 점검 상세 페이지에서 실시간 결함 알림 표시 확인

#### 7-5. 로그아웃
- 사이드바 하단 `로그아웃` 클릭
- `/login`으로 리다이렉트, 쿠키 삭제 확인

#### 7-6. 401 처리
- 만료된 토큰으로 API 요청 시 `/login`으로 자동 리다이렉트 확인

### 확인 포인트
- [ ] 로그인 후 JWT 쿠키 저장 확인 (DevTools → Application → Cookies)
- [ ] 대시보드 요약 카드 데이터 정확성 확인
- [ ] 주간 BarChart에 날짜별 점검 건수 표시 확인
- [ ] 결함 PieChart에 심각도별 분포 표시 확인
- [ ] 현장 목록 Badge (상태별 색상) 정상 표시
- [ ] 점검 기록 Badge (합격/불합격/대기) 정상 표시
- [ ] WebSocket 실시간 결함 알림 빨간색 박스 표시
- [ ] 로그아웃 후 `/login` 리다이렉트
- [ ] 인증 없이 `/dashboard` 접근 시 `/login` 리다이렉트

---

## 8. WebSocket E2E 테스트

### 테스트 방법

```bash
# 1. 로그인으로 토큰 획득
TOKEN=$(curl -s -X POST http://localhost:8000/api/v1/auth/login \
  -d "username=admin@smartinspection.com&password=admin123" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# 2. 현장/점검 ID 확인
SITE_ID=$(curl -s http://localhost:8000/api/v1/sites/ \
  -H "Authorization: Bearer $TOKEN" | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

# 3. WebSocket 연결 (별도 터미널에서)
# wscat 설치: npm install -g wscat
wscat -c "ws://localhost:8000/ws/sites/$SITE_ID/live?token=$TOKEN"

# 4. 결함 등록 (또 다른 터미널에서)
INSPECTION_ID="..."   # 해당 현장의 점검 ID
curl -X POST http://localhost:8000/api/v1/inspections/$INSPECTION_ID/defects \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"severity": "critical", "description": "균열 발견"}'

# 5. WS 연결 터미널에서 브로드캐스트 메시지 수신 확인
# {"type": "defect_created", "site_id": "...", "severity": "critical", ...}
```

### 확인 포인트
- [ ] WebSocket 연결 시 JWT 검증 정상 동작
- [ ] 결함 등록 즉시 WS 메시지 수신 확인
- [ ] 잘못된 토큰으로 연결 시 거부 확인
- [ ] 서버 재시작 후 WS 클라이언트 자동 재연결 확인 (Flutter WsService)

---

## 9. PostgreSQL 프로덕션 연결 검증

### 테스트 방법

```bash
# .env 에 프로덕션 DB URL 설정
DATABASE_URL=postgresql://smart_user:smart_password@192.168.0.35:5432/smart_inspection_db

cd smart_inspection && source venv/bin/activate
alembic current      # 현재 revision 확인
alembic upgrade head # 마이그레이션 실행
python main.py       # 서버 기동
```

### 확인 포인트
- [ ] `alembic current`가 `7fc9390837e0` 반환 확인
- [ ] 서버 기동 시 PostgreSQL 연결 오류 없음
- [ ] 씨드 데이터 삽입 후 API 조회 정상 동작

---

## 10. 릴리즈 APK 실기기 설치

### 테스트 방법

```bash
# ADB로 설치
adb install smart_inspection_app/build/app/outputs/flutter-apk/app-release.apk
```

### 확인 포인트
- [ ] 릴리즈 APK 설치 및 실행 성공
- [ ] ProGuard 난독화 후 API 통신 정상 동작
- [ ] 실기기에서 STT 한국어 인식 정확도 확인
- [ ] 실기기 카메라 OCR 동작 확인
- [ ] `flutter_secure_storage` 토큰 암호화 저장 확인

---

## 11. 알려진 제약사항

| 항목 | 제약 | 비고 |
|------|------|------|
| Tesseract | 시스템 설치 필요 | `brew install tesseract tesseract-lang` |
| OCR 정확도 | 저화질·필기체 인식률 낮음 | 인쇄물·표지판에 최적화 |
| STT | 에뮬레이터 마이크 지원 제한적 | 실기기 테스트 권장 |
| S3 pre-signed URL | 1시간 후 만료 | 자동갱신 미구현 |
| Google Maps | API 키 필요 | `YOUR_MAPS_API_KEY` 교체 |
| Nginx HTTPS | 공인 IP + 도메인 필요 | 로컬 환경에서는 HTTP로 테스트 |
| refresh token | 클라이언트 자동 갱신 미구현 | 만료 시 재로그인 필요 |
