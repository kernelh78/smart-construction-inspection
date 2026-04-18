# 미테스트 항목 (Fortest.md)

> OCR/STT/S3 기능은 구현 완료되었으나 실제 환경 테스트가 필요합니다.  
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
# 서버 실행 후
curl -X POST http://localhost:8000/api/v1/inspections/{inspection_id}/photos \
  -H "Authorization: Bearer {token}" \
  -F "file=@test_image.jpg"

# 기대 응답
# {
#   "id": "...",
#   "s3_key": "inspections/.../...",
#   "ocr_result": "인식된 텍스트",
#   "url": null  # S3 미설정 시
# }
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
- 마이크 아이콘 재탭 → 인식 중지

#### 2-2. 결함 등록 화면 STT 테스트
- `결함 등록` 화면 진입
- **결함 설명** 필드 우측 마이크 아이콘 탭
- 음성 인식 후 설명 필드 자동 입력 확인

### 확인 포인트
- [ ] 에뮬레이터에서 `SpeechToText.initialize()` 반환값이 `true`인지 확인
- [ ] 한국어(`ko_KR`) 로케일 인식 정상 동작 확인
- [ ] 인식 중 마이크 아이콘이 빨간색으로 변경되는지 확인
- [ ] 인식 완료 후 텍스트가 커서 위치에 삽입되는지 확인
- [ ] STT 불가 환경(권한 거부 등)에서 마이크 버튼이 표시되지 않는지 확인

---

## 3. S3 이미지 업로드

### 사전 준비
```bash
# .env 파일 생성
cp smart_inspection/.env.example smart_inspection/.env

# .env 파일 편집
AWS_ACCESS_KEY_ID=실제_액세스_키
AWS_SECRET_ACCESS_KEY=실제_시크릿_키
AWS_REGION=ap-northeast-2
S3_BUCKET_NAME=실제_버킷_이름
```

#### AWS S3 버킷 설정 (없는 경우)
1. AWS 콘솔 → S3 → 버킷 생성
2. 버킷 이름 설정 (예: `smart-inspection-photos`)
3. 리전: `ap-northeast-2` (서울)
4. 퍼블릭 액세스 차단 유지 (pre-signed URL 방식 사용)

#### IAM 권한 설정
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    }
  ]
}
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

#### 3-3. API 통합 테스트
```bash
# 사진 업로드
curl -X POST http://localhost:8000/api/v1/inspections/{inspection_id}/photos \
  -H "Authorization: Bearer {token}" \
  -F "file=@test_image.jpg"

# 기대 응답 (S3 설정 시)
# {
#   "id": "...",
#   "s3_key": "inspections/{id}/{uuid}_test_image.jpg",
#   "ocr_result": "...",
#   "url": "https://bucket.s3.ap-northeast-2.amazonaws.com/..."
# }

# 사진 목록 조회
curl http://localhost:8000/api/v1/inspections/{inspection_id}/photos \
  -H "Authorization: Bearer {token}"
```

#### 3-4. Flutter 앱 사진 목록 표시 테스트
- 사진 업로드 후 `점검 상세` 화면으로 이동
- **첨부 사진** 섹션에 업로드한 사진 썸네일 표시 확인
- 썸네일 탭 시 원본 사진 + OCR 텍스트 다이얼로그 표시 확인

### 확인 포인트
- [ ] `is_configured()` 가 `True` 반환 확인
- [ ] S3 버킷에 `inspections/{id}/` 경로로 파일 생성되는지 확인
- [ ] pre-signed URL이 브라우저에서 열리는지 확인 (1시간 유효)
- [ ] S3 미설정 시 s3_key만 DB 저장, url은 `null` 반환 확인
- [ ] Flutter `InspectionDetailScreen`에서 `Image.network(url)` 정상 로드 확인
- [ ] 네트워크 오류 시 placeholder 이미지(`Icons.image`) 표시 확인

---

## 4. 통합 플로우 테스트

### 전체 OCR + S3 플로우
1. Flutter `결함 등록` 화면 진입
2. **사진 촬영 후 텍스트 인식 (OCR)** 버튼 탭
3. 카메라로 텍스트가 있는 피사체 촬영
4. 백엔드: 이미지 수신 → S3 업로드 → OCR 처리
5. Flutter: OCR 결과가 설명 필드에 자동 입력됨
6. 결함 등록 완료
7. `점검 상세` 화면에서 첨부 사진 확인

### 전체 STT 플로우
1. Flutter `점검 기록 등록` 화면 진입
2. 메모 필드 마이크 버튼 탭 → 권한 허용
3. "철근 배근 간격 불량 발견, 설계도면과 상이" 발화
4. 메모 필드 자동 입력 확인
5. 점검 등록 완료 후 상세 화면에서 메모 확인

---

## 5. PostgreSQL 프로덕션 연결 검증

### 사전 준비
```bash
# .env 파일에 PostgreSQL URL 설정
DATABASE_URL=postgresql://smart_user:smart_password@192.168.0.35:5432/smart_inspection_db
```

### 테스트 방법

#### 5-1. Alembic 마이그레이션 상태 확인
```bash
cd smart_inspection
source venv/bin/activate
alembic current      # 현재 적용된 revision 확인
alembic history      # 전체 이력 확인
```

#### 5-2. 백엔드 서버 PostgreSQL 연결 확인
```bash
# PostgreSQL URL로 서버 기동
DATABASE_URL=postgresql://smart_user:smart_password@192.168.0.35:5432/smart_inspection_db \
  uvicorn app.main:app --host 0.0.0.0 --port 8000

# 로그에 "Application startup complete" 확인
# Swagger: http://localhost:8000/docs
```

#### 5-3. CRUD 통합 테스트
```bash
# 로그인
curl -X POST http://localhost:8000/api/v1/auth/login \
  -d "username=admin@smartinspection.com&password=admin123"

# 현장 목록 조회 (PostgreSQL에서 반환되는지 확인)
curl http://localhost:8000/api/v1/sites \
  -H "Authorization: Bearer {token}"
```

#### 5-4. 씨드 데이터 삽입
```bash
# PostgreSQL URL 설정 후 씨드 실행
DATABASE_URL=postgresql://smart_user:smart_password@192.168.0.35:5432/smart_inspection_db \
  python -m app.core.seed
```

### 확인 포인트
- [ ] `alembic current`가 `7fc9390837e0` 반환하는지 확인
- [ ] 서버 기동 시 PostgreSQL 연결 오류 없는지 확인
- [ ] 씨드 데이터 삽입 후 API 조회 정상 동작 확인
- [ ] SQLite fallback이 필요한 경우 `DATABASE_URL` 미설정 시 자동 전환 확인

---

## 6. 릴리즈 APK 실기기 설치 및 동작 확인

### 사전 준비
- Android 실기기 준비 (API 24 이상)
- 기기 설정 → 개발자 옵션 → USB 디버깅 활성화
- 기기 설정 → 보안 → 알 수 없는 출처 허용

### 테스트 방법

#### 6-1. APK 실기기 설치
```bash
# ADB로 설치
adb install smart_inspection_app/build/app/outputs/flutter-apk/app-release.apk

# 또는 파일 직접 전송 후 설치
# 파일 경로: build/app/outputs/flutter-apk/app-release.apk (49MB)
```

#### 6-2. 서명 검증
```bash
# APK 서명 확인
keytool -printcert -jarfile app-release.apk
# Owner: CN=Smart Inspection, OU=Dev, O=SmartDB, L=Seoul, ST=Seoul, C=KR 확인
```

#### 6-3. 실기기 기능 테스트
- 로그인 → JWT 토큰 정상 발급 및 저장 확인
- 현장/점검/결함 CRUD 확인
- STT: 실기기 마이크로 한국어 음성 입력 확인 (에뮬레이터보다 정확도 높음)
- 카메라: 실 카메라로 사진 촬영 후 OCR 확인
- 릴리즈 빌드 ProGuard 난독화 후 앱 정상 동작 확인

### 확인 포인트
- [ ] 릴리즈 APK 설치 및 실행 성공
- [ ] ProGuard 난독화 후 API 통신 정상 동작 확인
- [ ] 실기기에서 STT 한국어 인식 정확도 확인
- [ ] 실기기 카메라 OCR 동작 확인
- [ ] `flutter_secure_storage` 토큰 암호화 저장 확인
- [ ] 앱 종료 후 재진입 시 자동 로그인 확인

---

## 7. 알려진 제약사항

| 항목 | 제약 | 비고 |
|------|------|------|
| Tesseract | 시스템 설치 필요 | `brew install tesseract tesseract-lang` |
| OCR 정확도 | 저화질·필기체 인식률 낮음 | 인쇄물·표지판에 최적화 |
| STT | 에뮬레이터 마이크 지원 제한적 | 실기기 테스트 권장 |
| S3 pre-signed URL | 1시간 후 만료 | 만료 후 재요청 필요 (현재 자동갱신 미구현) |
| S3 미설정 | 업로드 건너뜀, url=null | 사진 썸네일 미표시 (placeholder 표시) |
