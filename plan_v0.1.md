# 스마트 건설 감리 시스템 - 향후 계획 (plan_v0.1)

**작성일**: 2026-04-18
**업데이트**: 2026-04-19 (Phase 1 · Phase 2 완료 반영)
**기준 버전**: v0.4 (Phase 1 + Phase 2 완료)
**GitHub**: https://github.com/kernelh78/smart-construction-inspection

---

## 1. 전체 진행 현황

| Phase | 내용 | 상태 |
|-------|------|------|
| v0.1 | FastAPI 백엔드 기본 구조 | ✅ 완료 |
| v0.2 | Flutter Android 앱 9개 화면 | ✅ 완료 |
| v0.3 | OCR/STT/S3/PostgreSQL/릴리즈 APK | ✅ 완료 |
| Phase 1 | 보안 강화 + CI/CD + Docker | ✅ 완료 |
| Phase 2 | WebSocket / 오프라인 / 지도 / 차트 | ✅ 완료 |
| Phase 3 | 프로덕션 배포 | 🔲 예정 |

---

## 2. 구현 완료 현황

### 2.1 백엔드 (FastAPI)

| 항목 | 상태 | 버전 |
|------|------|------|
| FastAPI 서버 구동 (Uvicorn) | ✅ | v0.1 |
| JWT 인증 (로그인/로그아웃/me/refresh) | ✅ | v0.1 |
| 현장 CRUD | ✅ | v0.1 |
| 점검 기록 CRUD | ✅ | v0.1 |
| 결함 등록/조회/수정 | ✅ | v0.1 |
| PDF 보고서 (일일/주간, ReportLab) | ✅ | v0.1 |
| 대시보드 API (현황/결함 집계) | ✅ | v0.1 |
| OCR (`ocr.py`, pytesseract) | ✅ | v0.3 |
| S3 이미지 업로드 (`storage.py`, boto3) | ✅ | v0.3 |
| 점검 사진 API (GET/POST /{id}/photos) | ✅ | v0.3 |
| PostgreSQL 전환 + Alembic | ✅ | v0.3 |
| pydantic-settings 환경변수 통합 | ✅ | Phase 1 |
| Redis JWT 블랙리스트 | ✅ | Phase 1 |
| CORS 제한 (env 기반) | ✅ | Phase 1 |
| GitHub Actions CI/CD | ✅ | Phase 1 |
| Docker Compose (FastAPI+PostgreSQL+Redis) | ✅ | Phase 1 |
| WebSocket `/ws/sites/{id}/live` | ✅ | Phase 2 |
| 결함 등록 시 WS 브로드캐스트 | ✅ | Phase 2 |
| 주간 통계 API (`/dashboard/weekly-stats`) | ✅ | Phase 2 |

### 2.2 Flutter Android 앱

| 항목 | 상태 | 버전 |
|------|------|------|
| 앱 기본 구조 (MVVM, Provider) | ✅ | v0.2 |
| 로그인/대시보드/현장/점검/결함 화면 (9개) | ✅ | v0.2 |
| STT 음성 입력 (`speech_to_text`) | ✅ | v0.3 |
| 카메라 OCR 자동 입력 (`image_picker`) | ✅ | v0.3 |
| 점검 상세 첨부 사진 목록 | ✅ | v0.3 |
| 릴리즈 APK (RSA 서명, ProGuard, 49MB) | ✅ | v0.3 |
| WsService + WsProvider (실시간 알림) | ✅ | Phase 2 |
| 결함 발생 SnackBar 토스트 알림 | ✅ | Phase 2 |
| LocalDbService (sqflite 오프라인 저장) | ✅ | Phase 2 |
| ConnectivityService (자동 동기화) | ✅ | Phase 2 |
| SitesMapScreen (Google Maps 마커) | ✅ | Phase 2 |
| WeeklyBarChart (주간 점검 BarChart) | ✅ | Phase 2 |
| DefectPieChart (결함 심각도 PieChart) | ✅ | Phase 2 |

---

## 3. 미테스트 항목 (구현 완료, 실환경 검증 필요)

| 항목 | 선행 조건 | 우선순위 |
|------|-----------|---------|
| OCR 실제 동작 | `brew install tesseract tesseract-lang` | 🔴 높음 |
| STT 실기기 테스트 | 실제 Android 기기 | 🔴 높음 |
| S3 실제 업로드 | AWS 자격증명 (.env 설정) | 🔴 높음 |
| WebSocket E2E (결함 등록 → 실시간 알림) | 에뮬레이터 + 서버 실기동 | 🔴 높음 |
| Google Maps 지도 표시 | Google Maps API 키 발급 | 🟡 중간 |
| 오프라인 동기화 실환경 | 네트워크 차단 환경 | 🟡 중간 |
| 릴리즈 APK 실기기 설치 | 실제 Android 기기 | 🟡 중간 |
| PostgreSQL 프로덕션 연결 | 192.168.0.35 네트워크 접근 | 🟡 중간 |

---

## 4. Phase 3 — 프로덕션 배포 (다음 단계)

### 4.1 웹 관리자 대시보드
- [ ] **React + Next.js** 기반 웹 프론트엔드
  - 현장 목록/상세, 점검/결함 관리 UI
  - Google Maps 또는 Kakao Maps 현장 지도
  - 실시간 차트 (Chart.js or Recharts)
  - PDF 보고서 다운로드 버튼

### 4.2 서버 배포 인프라
- [ ] 도메인 구입 + DNS 설정
- [ ] **Nginx 리버스 프록시** — HTTPS (Let's Encrypt) 적용
  ```nginx
  server {
      listen 443 ssl;
      location /api { proxy_pass http://api:8000; }
      location /ws  { proxy_pass http://api:8000; proxy_http_version 1.1; }
  }
  ```
- [ ] **PostgreSQL 자동 백업** — pg_dump cron (`0 3 * * * pg_dump ...`)
- [ ] **서버 모니터링** — Sentry (에러 추적) 또는 Prometheus + Grafana

### 4.3 테스트 강화
- [ ] **pytest 백엔드 테스트** — 핵심 API 단위 + 통합 테스트
  ```python
  tests/
  ├── test_auth.py      # 로그인, 블랙리스트
  ├── test_sites.py     # CRUD
  └── test_inspections.py
  ```
- [ ] **Flutter 위젯 테스트** — LoginScreen, DashboardScreen
- [ ] **GitHub Actions** — pytest 결과 PR 코멘트 자동 게시

### 4.4 기술 부채 해소

| 항목 | 내용 |
|------|------|
| refresh token | `POST /auth/refresh` 구현됨, 클라이언트 자동 갱신 로직 미적용 |
| Flutter 에러 처리 | API 오류 시 일부 화면 빈 상태 → Provider별 error state + 재시도 UI |
| SQLite fallback 제거 | 프로덕션에서 PostgreSQL 필수 설정으로 전환 |
| WS 전체 현장 구독 | 현재 site별 구독 — 관리자용 전체 알림 (`broadcast_all`) 미연결 |

---

## 5. 실행 참조 명령어

```bash
# Docker 전체 스택
cp smart_inspection/.env.example smart_inspection/.env
docker compose up -d

# 백엔드 단독
cd smart_inspection && source venv/bin/activate
nohup python main.py > server.log 2>&1 &

# Alembic 마이그레이션
alembic upgrade head

# Flutter 실행
cd smart_inspection_app && flutter run -d emulator-5554

# Flutter 릴리즈 APK
flutter build apk --release
```

---

**작성자**: AI Assistant
**최종 업데이트**: 2026-04-19 (Phase 1 · Phase 2 완료)
