# 스마트 건설 감리 시스템 - 개발 진행 보고서 (Phase 3 완료)

**작성일**: 2026-04-19
**버전**: v0.5 (Phase 3 완료)
**상태**: pytest 통합 테스트, Nginx + HTTPS, PostgreSQL 자동 백업, Next.js 웹 대시보드 완료

---

## 1. Phase 3 개요

| 항목 | 내용 |
|------|------|
| 대상 버전 | v0.5 (Phase 3) |
| 작업 기간 | 2026-04-19 |
| 주요 목표 | 프로덕션 배포 인프라 + 관리자 웹 대시보드 구축 |

---

## 2. 완료된 작업

### 2.1 pytest 백엔드 테스트 (28개 전체 통과)

**파일 구조**
```
smart_inspection/tests/
├── __init__.py
├── conftest.py          # SQLite in-memory DB, 공통 픽스처
├── test_auth.py         # 인증 테스트 7개
├── test_sites.py        # 현장 CRUD 테스트 10개
└── test_inspections.py  # 점검/결함 테스트 11개
```

**테스트 항목**

| 파일 | 테스트 항목 | 결과 |
|------|------------|------|
| test_auth.py | 로그인 성공/실패, /me, 로그아웃, 토큰 갱신 | ✅ 7/7 |
| test_sites.py | 현장 CRUD, 관리자/감리원 권한 분리 | ✅ 10/10 |
| test_inspections.py | 점검 CRUD, 결함 등록, 404 처리 | ✅ 11/11 |

**핵심 설계**
- SQLite in-memory + `StaticPool` — PostgreSQL 없이 격리된 테스트 실행
- `os.environ["DATABASE_URL"]` 선행 설정 → pydantic-settings가 SQLite URL 사용
- `get_db` 의존성 오버라이드 → 실제 앱 코드 변경 없이 테스트 DB 주입
- autouse fixture로 테스트별 DB 초기화/정리 (독립성 보장)

**실행 명령**
```bash
cd smart_inspection
source venv/bin/activate
python -m pytest tests/ -v
# 결과: 28 passed in 6.18s
```

**의존성 추가 (requirements.txt)**
```
pytest
pytest-asyncio
httpx
```

---

### 2.2 Nginx + HTTPS 설정

**파일 구조**
```
nginx/
├── nginx.conf              # worker, MIME, WebSocket upgrade map
├── conf.d/
│   └── app.conf            # HTTP→HTTPS 리다이렉트, SSL, 프록시 설정
├── certbot/
│   ├── conf/               # Let's Encrypt 인증서 저장 위치
│   └── www/                # ACME 챌린지 웹루트
└── init-letsencrypt.sh     # 인증서 최초 발급 스크립트
```

**Nginx 구성 (app.conf 주요 설정)**

| 경로 | 프록시 대상 | 비고 |
|------|------------|------|
| `/.well-known/acme-challenge/` | certbot webroot | Let's Encrypt 인증용 |
| `http://` | `https://` 301 리다이렉트 | 모든 HTTP 요청 강제 HTTPS |
| `/api/` | `http://api:8000` | FastAPI 백엔드 |
| `/ws/` | `http://api:8000` (WebSocket) | HTTP/1.1 Upgrade 헤더 |
| `/docs`, `/openapi.json` | `http://api:8000` | Swagger UI |
| `/` | `http://web:3000` | Next.js 웹 대시보드 |

**보안 헤더**
```nginx
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

**인증서 발급 절차**
1. `nginx/conf.d/app.conf`의 `YOUR_DOMAIN.com` → 실제 도메인 교체
2. `nginx/init-letsencrypt.sh`의 `DOMAIN`, `EMAIL` 변수 설정
3. `./nginx/init-letsencrypt.sh` 실행 (자동화: 임시 자체서명 → Nginx 기동 → Let's Encrypt 발급 → 재로드)

---

### 2.3 PostgreSQL 자동 백업

**파일 구조**
```
scripts/
├── backup_postgres.sh      # pg_dump, 일간/주간 보관 정책
├── restore_postgres.sh     # 백업 파일로 DB 복구
└── backup_entrypoint.sh    # Docker 컨테이너 crond 실행
```

**백업 정책**

| 종류 | 보관 개수 | 실행 주기 | 저장 경로 |
|------|----------|---------|---------|
| 일간 | 최근 7개 | 매일 03:00 | `/backups/daily/` |
| 주간 | 최근 4개 | 매주 일요일 03:00 | `/backups/weekly/` |

**Docker 서비스 구성**
```yaml
# docker-compose.yml
backup:
  image: postgres:16-alpine
  entrypoint: ["/scripts/backup_entrypoint.sh"]
  volumes:
    - backup_data:/backups       # 영속 볼륨
    - ./scripts/backup_postgres.sh:/scripts/backup_postgres.sh:ro
```

**수동 즉시 백업**
```bash
docker compose exec backup /scripts/backup_postgres.sh
```

**백업 복구**
```bash
./scripts/restore_postgres.sh backups/daily/smart_inspection_db_20260419_030000.sql.gz
```

---

### 2.4 Next.js 웹 관리자 대시보드

**기술 스택**

| 항목 | 내용 |
|------|------|
| 프레임워크 | Next.js 16.2.4 (App Router, TypeScript) |
| 스타일 | Tailwind CSS |
| 차트 | Recharts |
| HTTP | axios (JWT Bearer 자동 주입, 401→로그인 리다이렉트) |
| 인증 저장 | js-cookie (1일 만료) |
| 빌드 | standalone 모드 (Docker 멀티스테이지) |

**페이지 구성**

| 경로 | 내용 |
|------|------|
| `/login` | 로그인 폼 |
| `/dashboard` | 요약 카드 + 주간 BarChart + 결함 PieChart + 최근 점검/미결 결함 테이블 |
| `/dashboard/sites` | 현장 목록 테이블 |
| `/dashboard/sites/[id]` | 현장 상세 + 해당 현장 점검 기록 |
| `/dashboard/inspections` | 전체 점검 기록 목록 |
| `/dashboard/inspections/[id]` | 점검 상세 + WebSocket 실시간 결함 알림 |

**컴포넌트 구조**
```
web/
├── app/
│   ├── page.tsx                          # / → /dashboard 리다이렉트
│   ├── login/page.tsx
│   └── dashboard/
│       ├── layout.tsx                    # Sidebar 포함 레이아웃
│       ├── page.tsx
│       ├── sites/page.tsx
│       ├── sites/[id]/page.tsx
│       ├── inspections/page.tsx
│       └── inspections/[id]/page.tsx    # WebSocket 실시간 알림
├── components/
│   ├── Sidebar.tsx                       # 네비게이션 + 로그아웃
│   ├── charts/
│   │   ├── WeeklyBarChart.tsx
│   │   └── DefectPieChart.tsx
│   └── ui/
│       ├── StatCard.tsx
│       └── Badge.tsx                     # 상태/심각도 색상 뱃지
├── lib/
│   ├── api.ts                            # axios 클라이언트
│   └── types.ts                          # TypeScript 타입 정의
├── Dockerfile                            # 멀티스테이지 빌드
└── next.config.ts                        # output: standalone
```

**빌드 결과**
```
Route (app)           Size
○ /login
○ /dashboard
○ /dashboard/sites
ƒ /dashboard/sites/[id]
○ /dashboard/inspections
ƒ /dashboard/inspections/[id]

28 passed in build (TypeScript 오류 0건)
```

---

## 3. docker-compose 전체 구성 (Phase 3 완료 기준)

```
서비스        역할                    포트
─────────────────────────────────────────
api           FastAPI 백엔드          (내부 8000)
db            PostgreSQL 16           5432
redis         Redis 7                 (내부)
nginx         리버스 프록시 + SSL     80, 443
web           Next.js 대시보드        (내부 3000)
certbot       Let's Encrypt 인증서    (일회성)
backup        pg_dump cron 03:00      (내부)
```

---

## 4. 로컬 실행 현황 (2026-04-19 기준)

| 서비스 | 주소 | 상태 |
|--------|------|------|
| Next.js 웹 대시보드 | http://localhost:3000 | ✅ 실행중 |
| FastAPI 백엔드 | http://localhost:8000 | ✅ 실행중 |
| API 문서 (Swagger) | http://localhost:8000/docs | ✅ 접근 가능 |
| PostgreSQL | localhost:5432 (Docker) | ✅ healthy |
| Redis | Docker 내부 | ✅ healthy |

**기본 계정**
- 이메일: `admin@smartinspection.com`
- 비밀번호: `admin123`

---

## 5. 실행 명령어

### 로컬 개발 환경

```bash
# DB / Redis 기동
docker compose up -d db redis

# 백엔드 마이그레이션 + 기동
cd smart_inspection
source venv/bin/activate
alembic upgrade head
nohup python main.py > server.log 2>&1 &

# 웹 대시보드
cd web
npm run dev      # http://localhost:3000

# 테스트 실행
cd smart_inspection
python -m pytest tests/ -v
```

### Docker 전체 스택 (프로덕션)

```bash
# 최초 실행 (SSL 인증서 발급 포함)
./nginx/init-letsencrypt.sh

# 이후 실행
docker compose up -d
```

---

## 6. 다음 단계

**기술 부채 해소**

| 항목 | 내용 |
|------|------|
| refresh token 자동 갱신 | 클라이언트(Flutter/Web) 만료 전 자동 갱신 로직 미적용 |
| Flutter 에러 처리 | API 오류 시 일부 화면 빈 상태 → Provider별 error state + 재시도 UI |
| WS 전체 현장 구독 | 관리자용 broadcast_all 미연결 |

**모니터링 (미구현)**
- Sentry 에러 추적 또는 Prometheus + Grafana

---

---

## 7. 테스트 데이터 생성 및 API 검증 (2026-04-20)

### 7.1 테스트 환경

| 항목 | 내용 |
|------|------|
| DB | SQLite (`smart_inspection.db`, PostgreSQL 미기동 상태) |
| 서버 | FastAPI + Uvicorn (`DATABASE_URL=sqlite:///./smart_inspection.db`) |
| 기동 방법 | `DATABASE_URL=sqlite:///./smart_inspection.db python main.py` |

---

### 7.2 시드 데이터 생성 (`seed_data.py`)

테스트용 현실적인 건설 현장 데이터를 SQLAlchemy ORM으로 직접 삽입.

**생성 결과**

| 구분 | 수량 | 상세 |
|------|------|------|
| 현장 (Site) | 10개 | active 8, paused 1, completed 1 |
| 점검 (Inspection) | 10개 | pass 5, fail 3, pending 2 |
| 결함 (Defect) | 6개 | critical 2, major 3, minor 1 |

**현장 목록**

| # | 현장명 | 주소 | 상태 |
|---|--------|------|------|
| 1 | 강남 주상복합 신축공사 | 서울시 강남구 테헤란로 123 | active |
| 2 | 판교 오피스빌딩 공사 | 경기도 성남시 분당구 판교로 45 | active |
| 3 | 인천 물류센터 건설 | 인천시 남동구 논현동 678 | active |
| 4 | 부산 해운대 리조트 증축 | 부산시 해운대구 해운대해변로 99 | active |
| 5 | 대전 도심 아파트 재개발 | 대전시 서구 둔산동 456 | active |
| 6 | 수원 공장 리모델링 | 경기도 수원시 권선구 산업로 200 | paused |
| 7 | 광주 복합문화시설 공사 | 광주시 북구 용봉동 88 | active |
| 8 | 제주 호텔 신축 | 제주시 노형동 관광로 55 | active |
| 9 | 서울 마포 주거단지 개발 | 서울시 마포구 상암동 1591 | completed |
| 10 | 울산 산업단지 신축 | 울산시 북구 염포동 산업로 300 | active |

**점검 기록**

| 현장 | 공종 | 결과 | 주요 메모 |
|------|------|------|----------|
| 강남 주상복합 | 골조 | pass | 철근 배근 상태 양호, 피복두께 기준 충족 |
| 판교 오피스빌딩 | 설비 | fail | 3층 배관 누수 의심, 즉시 보수 필요 |
| 인천 물류센터 | 전기 | pass | 배선 규격·접지 이상 없음 |
| 부산 해운대 리조트 | 마감 | pending | 외벽 마감재 시공 중, 재점검 예정 |
| 대전 아파트 | 방수 | fail | 옥상 방수층 균열, 재시공 필요 |
| 수원 공장 | 토목 | pass | 지하 다짐 상태 기준치 이상 |
| 광주 복합문화 | 조경 | pass | 식재 계획 대비 90% 완료 |
| 제주 호텔 | 소방 | fail | 스프링클러 헤드 도면 불일치, 수정 필요 |
| 서울 마포 | 통신 | pending | 덕트 배관 완료, 케이블 포설 대기 |
| 울산 산업단지 | 가설 | pass | 비계 안전기준 충족 |

**결함 목록**

| 현장 | 심각도 | 내용 |
|------|--------|------|
| 판교 오피스빌딩 | critical | 3층 급수관 연결부 누수 — 즉시 차수 조치 및 배관 교체 |
| 판교 오피스빌딩 | major | 위생도기 고정 불량 — 볼트 재체결 |
| 대전 아파트 | critical | 옥상 방수층 균열 3개소 — 우기 전 긴급 보수 |
| 대전 아파트 | minor | 파라펫 상단 마감재 박리 — 코킹 재시공 |
| 제주 호텔 | major | 스프링클러 헤드 22개소 도면 불일치 — 이설 |
| 제주 호텔 | major | 소화전 함체 도어 개폐 불량 — 경첩 교체 |

---

### 7.3 버그 수정

시드 데이터 삽입 후 서버 기동 중 발견된 버그 2건 수정.

| 파일 | 버그 | 수정 내용 |
|------|------|----------|
| `app/routers/sites.py` | `SiteResponse.start_date / end_date` 타입을 `str \| None`으로 선언 → DB의 `datetime` 객체 직렬화 실패 (HTTP 500) | 타입을 `datetime \| None`으로 변경 |
| `app/routers/dashboard.py` | `weekly-stats` 엔드포인트에서 `cast(day.strftime("%m/%d"), str)` 사용 — SQLAlchemy의 `cast()`를 Python 문자열에 잘못 적용해 `AttributeError` 발생 | `day.strftime("%m/%d")` 직접 사용으로 수정 |

---

### 7.4 API 테스트 결과

SQLite 모드 FastAPI 서버(`http://localhost:8000`) 기동 후 전체 핵심 엔드포인트 검증.

| # | 테스트 항목 | 엔드포인트 | 결과 |
|---|------------|-----------|------|
| 1 | JWT 로그인 | `POST /api/v1/auth/login` | ✅ 토큰 발급 성공 |
| 2 | 현재 사용자 확인 | `GET /api/v1/auth/me` | ✅ Admin 반환 |
| 3 | 현장 목록 조회 | `GET /api/v1/sites/` | ✅ 10개 반환 |
| 4 | 현장 상세 조회 | `GET /api/v1/sites/{id}` | ✅ 이름·주소·위치 정상 |
| 5 | 점검 목록 조회 | `GET /api/v1/inspections/` | ✅ 10개 반환 |
| 6 | 대시보드 전체 현황 | `GET /api/v1/dashboard/` | ✅ 요약·결함·최근점검 정상 |
| 7 | 주간 통계 | `GET /api/v1/dashboard/weekly-stats` | ✅ 7일 일별 데이터 반환 |
| 8 | PDF 일일 보고서 | `POST /api/v1/reports/daily` | ✅ 3,886 bytes PDF 생성 |
| 9 | PDF 주간 보고서 | `POST /api/v1/reports/weekly` | ✅ 2,897 bytes PDF 생성 |

**대시보드 집계 결과**
```
총 현장: 10개 (active 8)
총 점검: 10개 | 합격률: 50.0%
미결 결함: 6개 (critical 2, major 3, minor 1)
```

---

**보고서 작성자**: AI Assistant
**최종 업데이트**: 2026-04-20 (테스트 데이터 생성 + API 검증 + 버그 수정 2건)
