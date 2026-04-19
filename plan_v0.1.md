# 스마트 건설 감리 시스템 - 향후 계획 (plan_v0.1)

**작성일**: 2026-04-18
**업데이트**: 2026-04-19 (Phase 3 완료 반영)
**기준 버전**: v0.5 (Phase 3 완료)
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
| Phase 3 | 프로덕션 배포 인프라 + 웹 대시보드 | ✅ 완료 |
| Phase 4 | 기술 부채 해소 + 모니터링 | 🔲 예정 |

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
| pytest 단위/통합 테스트 (28개) | ✅ | Phase 3 |
| Nginx 리버스 프록시 + HTTPS 설정 | ✅ | Phase 3 |
| PostgreSQL 자동 백업 (pg_dump cron) | ✅ | Phase 3 |

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

### 2.3 웹 대시보드 (Next.js)

| 항목 | 상태 | 버전 |
|------|------|------|
| 로그인 페이지 | ✅ | Phase 3 |
| 대시보드 (요약 카드 + 차트) | ✅ | Phase 3 |
| 현장 목록/상세 | ✅ | Phase 3 |
| 점검 기록 목록/상세 | ✅ | Phase 3 |
| 실시간 결함 알림 (WebSocket) | ✅ | Phase 3 |
| Recharts (BarChart + PieChart) | ✅ | Phase 3 |
| Docker 멀티스테이지 빌드 | ✅ | Phase 3 |

---

## 3. 미테스트 항목 (구현 완료, 실환경 검증 필요)

| 항목 | 선행 조건 | 우선순위 |
|------|-----------|---------|
| OCR 실제 동작 | `brew install tesseract tesseract-lang` | 🔴 높음 |
| STT 실기기 테스트 | 실제 Android 기기 | 🔴 높음 |
| S3 실제 업로드 | AWS 자격증명 (.env 설정) | 🔴 높음 |
| WebSocket E2E (결함 등록 → 실시간 알림) | 에뮬레이터 + 서버 실기동 | 🔴 높음 |
| 웹 대시보드 E2E (로그인 → 대시보드 → 데이터 표시) | 백엔드 실기동 | 🔴 높음 |
| pytest CI 자동 실행 (GitHub Actions) | push 이벤트 | 🔴 높음 |
| Nginx HTTPS (도메인 + Let's Encrypt) | 도메인 구입 + 공인 IP | 🟡 중간 |
| PostgreSQL 백업 복구 검증 | Docker 스택 실행 | 🟡 중간 |
| Google Maps 지도 표시 | Google Maps API 키 발급 | 🟡 중간 |
| 오프라인 동기화 실환경 | 네트워크 차단 환경 | 🟡 중간 |
| 릴리즈 APK 실기기 설치 | 실제 Android 기기 | 🟡 중간 |

---

## 4. Phase 4 — 기술 부채 해소 + 모니터링

### 4.1 기술 부채

| 항목 | 내용 | 우선순위 |
|------|------|---------|
| refresh token 자동 갱신 | Flutter/Web 클라이언트에서 만료 전 자동 갱신 로직 | 🔴 높음 |
| Flutter API 에러 처리 | Provider별 error state + 재시도 UI | 🟡 중간 |
| WS 전체 현장 구독 | 관리자용 `broadcast_all` 엔드포인트 연결 | 🟡 중간 |
| SQLite fallback 제거 | 프로덕션 PostgreSQL 전용 설정 | 🟢 낮음 |
| Flutter 위젯 테스트 | LoginScreen, DashboardScreen 위젯 테스트 | 🟡 중간 |

### 4.2 서버 모니터링

```
옵션 A: Sentry (에러 추적, 간편 설정)
  - pip install sentry-sdk[fastapi]
  - SENTRY_DSN 환경변수 설정

옵션 B: Prometheus + Grafana (메트릭 시각화)
  - prometheus-fastapi-instrumentator 추가
  - docker-compose에 prometheus, grafana 서비스 추가
```

### 4.3 웹 대시보드 기능 확장

| 항목 | 내용 |
|------|------|
| 현장 등록/수정 폼 | 관리자용 현장 생성/수정 UI |
| 점검 기록 필터 | 현장별/상태별/기간별 필터 |
| 결함 처리 | 결함 resolved 처리 버튼 |
| PDF 보고서 다운로드 | 버튼 클릭 → 일일/주간 PDF 다운로드 |
| Google Maps 현장 지도 | 웹 대시보드에서 Kakao Maps 또는 Google Maps |

---

## 5. 실행 참조 명령어

```bash
# 로컬 개발 환경
docker compose up -d db redis
cd smart_inspection && source venv/bin/activate
alembic upgrade head
nohup python main.py > server.log 2>&1 &
cd ../web && npm run dev        # http://localhost:3000

# 테스트 실행
cd smart_inspection
python -m pytest tests/ -v      # 28개 테스트

# Docker 전체 스택 (프로덕션)
./nginx/init-letsencrypt.sh     # 최초 1회 (SSL 발급)
docker compose up -d

# PostgreSQL 수동 백업
docker compose exec backup /scripts/backup_postgres.sh

# 백업 복구
./scripts/restore_postgres.sh backups/daily/<파일명>.sql.gz

# Flutter 실행
cd smart_inspection_app && flutter run -d emulator-5554

# Flutter 릴리즈 APK
flutter build apk --release
```

---

**작성자**: AI Assistant
**최종 업데이트**: 2026-04-19 (Phase 3 완료)
