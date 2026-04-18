# 스마트 건설 감리 시스템 - 개발 진행 보고서 (v0.3 → v0.4)

**최초 작성일**: 2026-04-18 (v0.3)
**업데이트**: 2026-04-19 (Phase 1 안정화 + Phase 2 기능 고도화)
**상태**: Phase 1 · Phase 2 완료 — 백엔드 보안 강화, CI/CD, WebSocket 실시간 알림, 오프라인 동기화, 지도/차트 추가

---

## 1. 프로젝트 개요

### 1.1 프로젝트명
**스마트 건설 감리 시스템 (Smart Construction Inspection System)**

### 1.2 기술 스택

#### 백엔드
| 항목 | 내용 |
|------|------|
| 프레임워크 | FastAPI 0.136.0 |
| 서버 | Uvicorn 0.44.0 |
| DB | SQLite (로컬 fallback), PostgreSQL 16 (프로덕션, 192.168.0.35) |
| ORM | SQLAlchemy 2.0.49 |
| 마이그레이션 | Alembic |
| 인증 | JWT (python-jose) + Redis 블랙리스트 (**Phase 1 신규**) |
| 환경변수 | pydantic-settings (**Phase 1 신규**) |
| 비밀번호 해싱 | bcrypt |
| PDF 생성 | ReportLab 4.2.5 |
| OCR | pytesseract 0.3.13 + Pillow |
| 이미지 스토리지 | AWS S3 (boto3 1.42.91) |
| 실시간 통신 | FastAPI WebSocket (**Phase 2 신규**) |
| API 문서 | Swagger UI, ReDoc |

#### 모바일 앱
| 항목 | 내용 |
|------|------|
| 프레임워크 | Flutter 3.41.4 / Dart 3.11.1 |
| 상태 관리 | Provider 6.1.5 |
| HTTP | http 1.6.0 |
| 인증 저장 | flutter_secure_storage 9.2.4 |
| WebSocket | web_socket_channel 3.0.3 (**Phase 2 신규**) |
| 오프라인 DB | sqflite 2.3.3 (**Phase 2 신규**) |
| 네트워크 감지 | connectivity_plus 6.1.0 (**Phase 2 신규**) |
| 차트 | fl_chart 0.69.0 (**Phase 2 신규**) |
| 지도 | google_maps_flutter 2.9.0 (**Phase 2 신규**) |
| 음성 인식 | speech_to_text 7.3.0 |
| 카메라 | image_picker 1.2.1 |
| 대상 플랫폼 | Android (API 36) |
| 아키텍처 | MVVM (Model - Provider - Screen) |

#### 인프라
| 항목 | 내용 |
|------|------|
| CI/CD | GitHub Actions (**Phase 1 신규**) |
| 컨테이너 | Docker Compose (FastAPI + PostgreSQL + Redis) (**Phase 1 신규**) |

---

## 2. 구현 완료 기능 전체 목록

### 2.1 데이터베이스 모델
| 모델 | 주요 필드 |
|------|-----------|
| User | id, name, email, hashed_password, role |
| Site | id, name, address, lat, lng, status |
| Inspection | id, site_id, inspector_id, category, status, memo, is_synced |
| InspectionPhoto | id, inspection_id, s3_key, ocr_result, taken_at |
| Defect | id, inspection_id, severity, description, resolved_at, resolved_by_id |

### 2.2 인증 시스템
- ✅ JWT 기반 로그인/로그아웃
- ✅ bcrypt 비밀번호 해싱
- ✅ **Redis JWT 블랙리스트** — 로그아웃 시 토큰 실제 무효화 (**Phase 1**)
- ✅ `POST /auth/refresh` — 토큰 갱신

### 2.3 API 엔드포인트

#### 인증 (`/api/v1/auth`)
| 메서드 | 경로 | 설명 |
|--------|------|------|
| POST | /login | JWT 토큰 발급 |
| POST | /logout | 토큰 블랙리스트 등록 후 로그아웃 |
| POST | /refresh | 토큰 갱신 |
| GET | /me | 현재 사용자 정보 |

#### 현장 (`/api/v1/sites`)
`GET /` · `GET /{id}` · `POST /` · `PUT /{id}` · `DELETE /{id}`

#### 점검 (`/api/v1/inspections`)
`GET /` · `GET /{id}` · `POST /` · `PUT /{id}` · `DELETE /{id}`
· `GET /{id}/photos` · `POST /{id}/photos` · `POST /{id}/defects`

#### 보고서 (`/api/v1/reports`)
`POST /daily` (PDF) · `POST /weekly` (PDF)

#### 대시보드 (`/api/v1/dashboard`)
| 경로 | 설명 |
|------|------|
| GET /summary | 현황 요약 |
| GET /defects | 미결 결함 목록 |
| GET /defects/summary | 심각도별 집계 |
| GET /weekly-stats | **주간 일별 점검 통계 + 결함 분포 (Phase 2 신규)** |

#### WebSocket (`/ws/sites/{site_id}/live`) — **Phase 2 신규**
- JWT 토큰 쿼리 파라미터 인증
- 결함 등록 시 해당 현장 구독자에게 실시간 브로드캐스트

### 2.4 보안 강화 — Phase 1

| 항목 | 내용 |
|------|------|
| 환경변수 | `pydantic-settings` 기반 `Settings` 클래스 — 하드코딩 SECRET_KEY 완전 제거 |
| JWT 블랙리스트 | Redis `SETEX` — 토큰 잔여 만료 시간만큼 키 보관 |
| Redis fallback | Redis 미연결 시 graceful fallback (서비스 중단 없음) |
| CORS | `allow_origins=["*"]` → `.env`의 `ALLOWED_ORIGINS` 쉼표 목록으로 제한 |

### 2.5 CI/CD — Phase 1

**GitHub Actions** (`.github/workflows/ci.yml`):
- `backend` job: PostgreSQL 16 + Redis 서비스 컨테이너 → Alembic 마이그레이션 → pytest
- `flutter` job: `flutter analyze` + `flutter test` + debug APK 빌드

**Docker Compose** (`docker-compose.yml`):
```
api    (FastAPI + Tesseract)
db     (PostgreSQL 16, 볼륨 영속화)
redis  (Redis 7, 볼륨 영속화)
```

### 2.6 실시간 알림 (WebSocket) — Phase 2

#### 백엔드
- `app/core/ws_manager.py` — site별 Connection Pool, broadcast, dead connection 자동 정리
- `app/routers/websocket.py` — `/ws/sites/{id}/live`, JWT 검증, 30초 ping keepalive
- `inspections.py` `create_defect` — 결함 등록 직후 `asyncio.create_task`로 비동기 브로드캐스트

#### Flutter
- `WsService` — WebSocket 연결/재연결(5초 backoff)/ping 타이머
- `WsProvider` — 결함 이벤트 수신 → `notifyListeners`
- `DashboardScreen` — 결함 심각도별 색상 SnackBar 알림 + 자동 대시보드 갱신

### 2.7 오프라인 동기화 — Phase 2

- `LocalDbService` (`sqflite`) — `pending_inspections` / `pending_defects` 테이블
  - 오프라인 시 점검/결함 로컬 저장, `is_synced` 컬럼 관리
- `ConnectivityService` — `connectivity_plus` 네트워크 변화 감지
  - 온라인 복구 시 미동기화 레코드 자동 백엔드 업로드
- `AuthProvider` 로그인 성공 시 `ConnectivityService.init()` 실행

### 2.8 현장 지도 뷰 — Phase 2

- `SitesMapScreen` — `google_maps_flutter` 기반 Google Maps
  - 현장 lat/lng → 마커 표시, 상태별 색상(active=녹, completed=청, 기타=주황)
  - 마커 InfoWindow 탭 → 현장 상세 진입
- `SitesListScreen` AppBar에 지도 전환 아이콘 버튼 추가
- **API 키 필요**: `AndroidManifest.xml`의 `YOUR_MAPS_API_KEY` 교체

### 2.9 통계 차트 — Phase 2

- `WeeklyBarChart` (`fl_chart BarChart`) — 최근 7일 점검 건수, 합격/전체 스택 바
- `DefectPieChart` (`fl_chart PieChart`) — 미결 결함 심각도 분포 (Critical/Major/Minor)
- `DashboardScreen` 요약 카드 아래 두 차트 순서로 배치
- `DashboardProvider.fetch()` — `getWeeklyStats()` 병렬 호출 추가

---

## 3. 파일 구조 (신규/변경 파일)

```
SmartDB/
├── .github/
│   └── workflows/
│       └── ci.yml                          # GitHub Actions CI (신규 Phase 1)
├── docker-compose.yml                      # Docker Compose (신규 Phase 1)
│
├── smart_inspection/
│   ├── Dockerfile                          # 컨테이너 이미지 (신규 Phase 1)
│   ├── .env.example                        # Redis/CORS 항목 추가 (Phase 1)
│   ├── requirements.txt                    # pydantic-settings, redis 추가 (Phase 1)
│   └── app/
│       ├── config.py                       # pydantic-settings Settings (신규 Phase 1)
│       ├── main.py                         # CORS env 기반, ws 라우터 등록 (Phase 1/2)
│       ├── core/
│       │   ├── blacklist.py                # Redis JWT 블랙리스트 (신규 Phase 1)
│       │   ├── security.py                 # settings 통합, 블랙리스트 체크 (Phase 1)
│       │   └── ws_manager.py               # WebSocket ConnectionManager (신규 Phase 2)
│       └── routers/
│           ├── auth.py                     # settings 통합, 블랙리스트 연동 (Phase 1)
│           ├── websocket.py                # /ws/sites/{id}/live (신규 Phase 2)
│           ├── inspections.py              # 결함 등록 시 WS 브로드캐스트 (Phase 2)
│           └── dashboard.py               # /weekly-stats 엔드포인트 추가 (Phase 2)
│
└── smart_inspection_app/
    ├── android/app/src/main/
    │   └── AndroidManifest.xml             # Google Maps API Key 항목 추가 (Phase 2)
    ├── pubspec.yaml                        # 5개 패키지 추가 (Phase 2)
    └── lib/
        ├── main.dart                       # WsProvider 등록, ensureInitialized (Phase 2)
        ├── models/
        │   └── dashboard.dart              # WeeklyStats, DefectSeverityStat 추가 (Phase 2)
        ├── services/
        │   ├── ws_service.dart             # WebSocket 클라이언트 (신규 Phase 2)
        │   ├── local_db_service.dart       # sqflite 오프라인 DB (신규 Phase 2)
        │   ├── connectivity_service.dart   # 네트워크 감지 + 자동 sync (신규 Phase 2)
        │   └── api_service.dart            # getWeeklyStats() 추가 (Phase 2)
        ├── providers/
        │   ├── auth_provider.dart          # ConnectivityService 초기화 연동 (Phase 2)
        │   ├── dashboard_provider.dart     # weeklyStats 필드, 병렬 fetch (Phase 2)
        │   └── ws_provider.dart            # 결함 이벤트 수신 Provider (신규 Phase 2)
        ├── widgets/
        │   ├── weekly_bar_chart.dart       # 주간 점검 BarChart (신규 Phase 2)
        │   └── defect_pie_chart.dart       # 결함 심각도 PieChart (신규 Phase 2)
        └── screens/
            ├── dashboard_screen.dart       # WS 알림 토스트, 차트 추가 (Phase 2)
            └── sites/
                └── sites_map_screen.dart   # Google Maps 현장 지도 (신규 Phase 2)
```

---

## 4. 테스트 결과

### 4.1 Phase 1 — 보안 강화 테스트

| 테스트 항목 | 결과 | 비고 |
|------------|------|------|
| pydantic-settings config 로딩 | ✅ 성공 | .env 기반 SECRET_KEY/REDIS_URL/CORS |
| 서버 기동 (SQLite fallback) | ✅ 성공 | |
| JWT 로그인 / /me | ✅ 성공 | |
| 로그아웃 후 토큰 차단 | ✅ 성공 | `401 Token has been revoked` |
| Redis 미연결 graceful fallback | ✅ 성공 | 서비스 중단 없음 |
| CORS 허용 Origin (localhost:3000) | ✅ 성공 | `Access-Control-Allow-Origin` 반환 |
| CORS 차단 Origin (evil.com) | ✅ 성공 | 헤더 없음 |

### 4.2 Phase 2 — 신규 기능 검증

| 테스트 항목 | 결과 | 비고 |
|------------|------|------|
| 백엔드 임포트 (`app.main`) | ✅ 성공 | |
| `/ws/sites/{id}/live` 라우트 등록 | ✅ 성공 | |
| `/api/v1/dashboard/weekly-stats` 라우트 | ✅ 성공 | |
| Flutter `flutter analyze` | ✅ No issues | 경고 0건 |
| Flutter `flutter pub get` | ✅ 성공 | 27개 패키지 추가 |
| WebSocket 연결/결함 브로드캐스트 | ⏳ 에뮬레이터 실기동 테스트 필요 | |
| 오프라인 동기화 | ⏳ 네트워크 차단 환경 테스트 필요 | |
| Google Maps 지도 표시 | ⏳ API 키 설정 후 확인 필요 | `YOUR_MAPS_API_KEY` 교체 |
| 차트 (BarChart / PieChart) | ⏳ 에뮬레이터 실기동 테스트 필요 | |

---

## 5. 환경 설정

### 5.1 .env 설정 (백엔드)

```ini
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

DATABASE_URL=postgresql://smart_user:smart_password@localhost:5432/smart_inspection_db

REDIS_URL=redis://localhost:6379/0

ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000

AWS_ACCESS_KEY_ID=your-access-key-id
AWS_SECRET_ACCESS_KEY=your-secret-access-key
AWS_REGION=ap-northeast-2
S3_BUCKET_NAME=your-bucket-name
```

### 5.2 Google Maps API 키

`smart_inspection_app/android/app/src/main/AndroidManifest.xml` 내:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_MAPS_API_KEY"/>   <!-- 실제 키로 교체 -->
```

---

## 6. 실행 명령어

### Docker Compose (전체 스택)
```bash
cp smart_inspection/.env.example smart_inspection/.env
# .env 편집 후
docker compose up -d
```

### 백엔드 단독 실행
```bash
cd smart_inspection
pkill -f "python main.py"
nohup python main.py > server.log 2>&1 &
```

### PostgreSQL 마이그레이션
```bash
cd smart_inspection && source venv/bin/activate
alembic upgrade head
```

### Flutter 앱 실행
```bash
cd smart_inspection_app
flutter run -d emulator-5554
```

### Flutter 릴리즈 APK
```bash
cd smart_inspection_app
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

---

## 7. 다음 단계 (Phase 3)

### 7.1 완료 항목 (v0.1 ~ v0.4)
- [x] FastAPI 백엔드 전체 API 구현
- [x] JWT 인증 + Redis 블랙리스트
- [x] PDF 보고서 (일일/주간)
- [x] OCR/STT 연동
- [x] S3 이미지 업로드
- [x] PostgreSQL 전환 + Alembic
- [x] Flutter Android 앱 (9개 화면)
- [x] 릴리즈 APK (RSA 서명, 49MB)
- [x] pydantic-settings 환경변수 통합
- [x] Redis JWT 블랙리스트
- [x] CORS 제한 (env 기반)
- [x] GitHub Actions CI/CD
- [x] Docker Compose
- [x] WebSocket 실시간 결함 알림
- [x] 오프라인 동기화 (sqflite + connectivity_plus)
- [x] 현장 지도 뷰 (Google Maps)
- [x] 대시보드 통계 차트 (BarChart + PieChart)

### 7.2 미테스트 항목
- [ ] OCR 실제 환경 테스트 (Tesseract 설치 필요)
- [ ] STT 실기기 테스트
- [ ] S3 실제 업로드 (AWS 자격증명 필요)
- [ ] WebSocket 에뮬레이터 E2E 테스트
- [ ] Google Maps 지도 표시 (API 키 필요)
- [ ] 오프라인 동기화 실환경 테스트

### 7.3 Phase 3 — 프로덕션 배포
- [ ] React/Next.js 웹 관리자 대시보드
- [ ] 도메인 + HTTPS (Let's Encrypt + Nginx)
- [ ] PostgreSQL 자동 백업 (pg_dump cron)
- [ ] 서버 모니터링 (Prometheus + Grafana 또는 Sentry)
- [ ] pytest 백엔드 단위/통합 테스트 작성
- [ ] Flutter 위젯 테스트 추가

---

**보고서 작성자**: AI Assistant
**검토자**: (미작성)
**최종 업데이트**: 2026-04-19 (Phase 1 안정화 + Phase 2 기능 고도화 완료)
