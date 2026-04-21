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

SQLite 모드 FastAPI 서버(http://localhost:8000) 기동 후 전체 핵심 엔드포인트 검증.
#	테스트 항목	엔드포인트	결과
1	JWT 로그인	POST /api/v1/auth/login	✅ 토큰 발급 성공
2	현재 사용자 확인	GET /api/v1/auth/me	✅ Admin 반환
3	현장 목록 조회	GET /api/v1/sites/	✅ 10개 반환
4	현장 상세 조회	GET /api/v1/sites/{id}	✅ 이름·주소·위치 정상
5	점검 목록 조회	GET /api/v1/inspections/	✅ 10개 반환
6	대시보드 전체 현황	GET /api/v1/dashboard/	✅ 요약·결함·최근점검 정상
7	주간 통계	GET /api/v1/dashboard/weekly-stats	✅ 7일 일별 데이터 반환
8	PDF 일일 보고서	POST /api/v1/reports/daily	✅ 3,886 bytes PDF 생성
9	PDF 주간 보고서	POST /api/v1/reports/weekly	✅ 2,897 bytes PDF 생성
