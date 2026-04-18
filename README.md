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

커밋 내용 (53 files changed, 4160 insertions):

구분	내용
보고서	report_v0.3.md — Phase 1/2 전체 반영, v0.4로 업데이트
계획서	plan_v0.1.md — Phase 1/2 완료 표기, Phase 3 로드맵 갱신
백엔드	smart_inspection/ gitlink → 일반 디렉토리 전환, 전체 파일 직접 추적 시작
CI/CD	.github/workflows/ci.yml, docker-compose.yml
Flutter	ws, local_db, connectivity, map, chart 신규 파일 7개 + 기존 파일 수정
GitHub: https://github.com/kernelh78/smart-construction-inspection — push 완료

참고: smart_inspection/ 이 이전에 잘못된 gitlink(160000)로 잠겨 있었는데, 이번에 일반 디렉토리로 전환하여 앞으로는 백엔드 파일이 정상 추적됩니다.
