"""
테스트 데이터 시드 스크립트
현장 10개 + 점검 기록 10개 (현장당 1개) + 결함 데이터 삽입
"""
import os
import sys
import uuid
from datetime import datetime, timedelta
import random

# SQLite 사용 (로컬 테스트)
os.environ["DATABASE_URL"] = "sqlite:///./smart_inspection.db"
os.environ["REDIS_URL"] = "redis://localhost:6379/0"

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database import SessionLocal, engine
from app.models import Base, Site, Inspection, Defect, SiteStatus, InspectionStatus, DefectSeverity

Base.metadata.create_all(bind=engine)

ADMIN_USER_ID = "24c25109-6c5d-4156-b24c-08e12075628d"

SITES = [
    {"name": "강남 주상복합 신축공사", "address": "서울시 강남구 테헤란로 123", "lat": 37.5012, "lng": 127.0396, "status": SiteStatus.active},
    {"name": "판교 오피스빌딩 공사", "address": "경기도 성남시 분당구 판교로 45", "lat": 37.3943, "lng": 127.1112, "status": SiteStatus.active},
    {"name": "인천 물류센터 건설", "address": "인천시 남동구 논현동 678", "lat": 37.4001, "lng": 126.7322, "status": SiteStatus.active},
    {"name": "부산 해운대 리조트 증축", "address": "부산시 해운대구 해운대해변로 99", "lat": 35.1587, "lng": 129.1604, "status": SiteStatus.active},
    {"name": "대전 도심 아파트 재개발", "address": "대전시 서구 둔산동 456", "lat": 36.3504, "lng": 127.3845, "status": SiteStatus.active},
    {"name": "수원 공장 리모델링", "address": "경기도 수원시 권선구 산업로 200", "lat": 37.2636, "lng": 127.0286, "status": SiteStatus.paused},
    {"name": "광주 복합문화시설 공사", "address": "광주시 북구 용봉동 88", "lat": 35.1768, "lng": 126.9078, "status": SiteStatus.active},
    {"name": "제주 호텔 신축", "address": "제주시 노형동 관광로 55", "lat": 33.4890, "lng": 126.4983, "status": SiteStatus.active},
    {"name": "서울 마포 주거단지 개발", "address": "서울시 마포구 상암동 1591", "lat": 37.5757, "lng": 126.8882, "status": SiteStatus.completed},
    {"name": "울산 산업단지 신축", "address": "울산시 북구 염포동 산업로 300", "lat": 35.5665, "lng": 129.3615, "status": SiteStatus.active},
]

CATEGORIES = ["골조", "설비", "전기", "마감", "방수", "토목", "조경", "소방", "통신", "가설"]

INSPECTION_DATA = [
    {"status": InspectionStatus.pass_, "memo": "골조 철근 배근 상태 양호. 피복두께 기준 충족.", "category": "골조"},
    {"status": InspectionStatus.fail, "memo": "3층 배관 누수 의심 구간 발견. 즉시 보수 필요.", "category": "설비"},
    {"status": InspectionStatus.pass_, "memo": "전기 배선 규격 및 접지 상태 이상 없음.", "category": "전기"},
    {"status": InspectionStatus.pending, "memo": "외벽 마감재 시공 중. 다음 주 재점검 예정.", "category": "마감"},
    {"status": InspectionStatus.fail, "memo": "옥상 방수층 균열 발생. 방수 재시공 필요.", "category": "방수"},
    {"status": InspectionStatus.pass_, "memo": "지하 토공사 다짐 상태 기준치 이상. 합격.", "category": "토목"},
    {"status": InspectionStatus.pass_, "memo": "조경 식재 계획 대비 90% 완료. 잔여 식재 중.", "category": "조경"},
    {"status": InspectionStatus.fail, "memo": "스프링클러 헤드 위치 설계 도면 불일치. 수정 필요.", "category": "소방"},
    {"status": InspectionStatus.pending, "memo": "통신 덕트 배관 설치 완료. 케이블 포설 대기 중.", "category": "통신"},
    {"status": InspectionStatus.pass_, "memo": "가설 비계 설치 상태 안전기준 충족. 이상 없음.", "category": "가설"},
]

DEFECT_DATA = [
    # site 1 (pass) - no defect
    # site 2 (fail)
    [
        {"severity": DefectSeverity.critical, "description": "3층 급수관 연결부 누수. 즉시 차수 조치 및 배관 교체 필요."},
        {"severity": DefectSeverity.major, "description": "위생도기 고정 불량. 볼트 재체결 필요."},
    ],
    # site 3 (pass) - no defect
    # site 4 (pending) - no defect
    # site 5 (fail)
    [
        {"severity": DefectSeverity.critical, "description": "옥상 방수층 균열 3개소. 우기 전 긴급 보수 필요."},
        {"severity": DefectSeverity.minor, "description": "파라펫 상단 마감재 박리. 코킹 재시공 필요."},
    ],
    # site 6 (pass) - no defect
    # site 7 (pass) - no defect
    # site 8 (fail)
    [
        {"severity": DefectSeverity.major, "description": "스프링클러 헤드 22개소 위치 설계 도면 불일치. 이설 필요."},
        {"severity": DefectSeverity.major, "description": "소화전 함체 도어 개폐 불량. 경첩 교체 필요."},
    ],
    # site 9 (pending) - no defect
    # site 10 (pass) - no defect
]

def run():
    db = SessionLocal()
    try:
        now = datetime.now()
        created_sites = []

        print("현장 10개 생성 중...")
        for i, site_data in enumerate(SITES):
            start = now - timedelta(days=random.randint(30, 180))
            end = start + timedelta(days=random.randint(180, 365))
            site = Site(
                id=str(uuid.uuid4()),
                name=site_data["name"],
                address=site_data["address"],
                lat=site_data["lat"],
                lng=site_data["lng"],
                status=site_data["status"],
                start_date=start,
                end_date=end,
                manager_id=ADMIN_USER_ID,
            )
            db.add(site)
            created_sites.append(site)
            print(f"  [{i+1}] {site.name}")

        db.flush()

        print("\n점검 기록 10개 생성 중...")
        defect_indices = {1: 0, 4: 1, 7: 2}  # fail인 site index -> defect 배열 index
        created_inspections = []

        for i, (site, insp_data) in enumerate(zip(created_sites, INSPECTION_DATA)):
            inspected_at = now - timedelta(days=random.randint(1, 14))
            inspection = Inspection(
                id=str(uuid.uuid4()),
                site_id=site.id,
                inspector_id=ADMIN_USER_ID,
                category=insp_data["category"],
                status=insp_data["status"],
                memo=insp_data["memo"],
                location_lat=float(site.lat) + random.uniform(-0.001, 0.001),
                location_lng=float(site.lng) + random.uniform(-0.001, 0.001),
                inspected_at=inspected_at,
                is_synced=True,
            )
            db.add(inspection)
            created_inspections.append(inspection)
            print(f"  [{i+1}] {site.name} - {insp_data['category']} ({insp_data['status'].value})")

        db.flush()

        print("\n결함 데이터 생성 중...")
        defect_map = {1: 0, 4: 1, 7: 2}
        for site_idx, defect_arr_idx in defect_map.items():
            inspection = created_inspections[site_idx]
            for d in DEFECT_DATA[defect_arr_idx]:
                defect = Defect(
                    id=str(uuid.uuid4()),
                    inspection_id=inspection.id,
                    severity=d["severity"],
                    description=d["description"],
                )
                db.add(defect)
                print(f"  [{d['severity'].value}] {d['description'][:40]}...")

        db.commit()
        print(f"\n완료! 현장 {len(created_sites)}개, 점검 {len(created_inspections)}개, 결함 6개 생성됨.")

    except Exception as e:
        db.rollback()
        print(f"오류: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    run()
