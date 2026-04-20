"""
대시보드 API 라우터

전체 현황 요약 및 미결 결함 현황을 제공합니다.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func, cast, Date
from pydantic import BaseModel
from datetime import datetime, timedelta, timezone

from ..database import get_db
from ..models import Inspection, Defect, Site, User, InspectionStatus, DefectSeverity
from ..core.security import get_current_user

router = APIRouter()

# Pydantic 스키마
class DashboardSummary(BaseModel):
    total_sites: int
    active_sites: int
    total_inspections: int
    pass_rate: float
    pending_inspections: int
    total_defects: int
    unresolved_defects: int

class DefectSummary(BaseModel):
    critical: int
    major: int
    minor: int
    total: int

class DashboardDefectResponse(BaseModel):
    id: str
    site_name: str
    inspection_id: str
    severity: str
    description: str
    created_at: str

    class Config:
        from_attributes = True

class DashboardResponse(BaseModel):
    summary: DashboardSummary
    defect_summary: DefectSummary
    recent_inspections: list
    unresolved_defects: list[DashboardDefectResponse]

# 전체 현황 요약 API
@router.get("/summary", response_model=DashboardSummary)
async def get_dashboard_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 전체 현장 수
    total_sites = db.query(func.count(Site.id)).scalar()
    active_sites = db.query(func.count(Site.id)).filter(Site.status == "active").scalar()
    
    # 전체 점검 수
    total_inspections = db.query(func.count(Inspection.id)).scalar()
    
    # 합격률 계산
    pass_count = db.query(func.count(Inspection.id)).filter(
        Inspection.status == InspectionStatus.pass_
    ).scalar()
    pass_rate = (pass_count / total_inspections * 100) if total_inspections > 0 else 0.0
    
    # 대기 중인 점검 수
    pending_inspections = db.query(func.count(Inspection.id)).filter(
        Inspection.status == InspectionStatus.pending
    ).scalar()
    
    # 전체 결함 수
    total_defects = db.query(func.count(Defect.id)).scalar()
    
    # 미결 결함 수
    unresolved_defects = db.query(func.count(Defect.id)).filter(
        Defect.resolved_at == None
    ).scalar()
    
    return DashboardSummary(
        total_sites=total_sites,
        active_sites=active_sites,
        total_inspections=total_inspections,
        pass_rate=round(pass_rate, 2),
        pending_inspections=pending_inspections,
        total_defects=total_defects,
        unresolved_defects=unresolved_defects
    )

# 미결 결함 현황 API
@router.get("/defects", response_model=list[DashboardDefectResponse])
async def get_unresolved_defects(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 미결 결함 조회
    defects = db.query(Defect).filter(
        Defect.resolved_at == None
    ).order_by(Defect.created_at.desc()).limit(50).all()
    
    # 현장 이름 추가
    result = []
    for defect in defects:
        inspection = db.query(Inspection).filter(Inspection.id == defect.inspection_id).first()
        site = db.query(Site).filter(Site.id == inspection.site_id).first() if inspection else None
        
        result.append(DashboardDefectResponse(
            id=defect.id,
            site_name=site.name if site else "Unknown",
            inspection_id=defect.inspection_id,
            severity=defect.severity,
            description=defect.description,
            created_at=defect.created_at.isoformat() if defect.created_at else None
        ))
    
    return result

# 결함 심각도 요약 API
@router.get("/defects/summary", response_model=DefectSummary)
async def get_defect_summary(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    critical = db.query(func.count(Defect.id)).filter(
        Defect.severity == DefectSeverity.critical,
        Defect.resolved_at == None
    ).scalar()
    major = db.query(func.count(Defect.id)).filter(
        Defect.severity == DefectSeverity.major,
        Defect.resolved_at == None
    ).scalar()
    minor = db.query(func.count(Defect.id)).filter(
        Defect.severity == DefectSeverity.minor,
        Defect.resolved_at == None
    ).scalar()
    total = critical + major + minor
    
    return DefectSummary(
        critical=critical,
        major=major,
        minor=minor,
        total=total
    )

# 전체 대시보드 API (모든 데이터 통합)
@router.get("/", response_model=DashboardResponse)
async def get_dashboard(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 요약 정보
    total_sites = db.query(func.count(Site.id)).scalar()
    active_sites = db.query(func.count(Site.id)).filter(Site.status == "active").scalar()
    total_inspections = db.query(func.count(Inspection.id)).scalar()
    pass_count = db.query(func.count(Inspection.id)).filter(
        Inspection.status == InspectionStatus.pass_
    ).scalar()
    pass_rate = (pass_count / total_inspections * 100) if total_inspections > 0 else 0.0
    pending_inspections = db.query(func.count(Inspection.id)).filter(
        Inspection.status == InspectionStatus.pending
    ).scalar()
    total_defects = db.query(func.count(Defect.id)).scalar()
    unresolved_defects = db.query(func.count(Defect.id)).filter(
        Defect.resolved_at == None
    ).scalar()
    
    summary = DashboardSummary(
        total_sites=total_sites,
        active_sites=active_sites,
        total_inspections=total_inspections,
        pass_rate=round(pass_rate, 2),
        pending_inspections=pending_inspections,
        total_defects=total_defects,
        unresolved_defects=unresolved_defects
    )
    
    # 결함 심각도 요약
    critical = db.query(func.count(Defect.id)).filter(
        Defect.severity == DefectSeverity.critical,
        Defect.resolved_at == None
    ).scalar()
    major = db.query(func.count(Defect.id)).filter(
        Defect.severity == DefectSeverity.major,
        Defect.resolved_at == None
    ).scalar()
    minor = db.query(func.count(Defect.id)).filter(
        Defect.severity == DefectSeverity.minor,
        Defect.resolved_at == None
    ).scalar()
    defect_summary = DefectSummary(
        critical=critical,
        major=major,
        minor=minor,
        total=critical + major + minor
    )
    
    # 최근 점검 기록
    recent_inspections = db.query(Inspection).order_by(
        Inspection.inspected_at.desc()
    ).limit(5).all()
    
    recent_inspections_data = []
    for inspection in recent_inspections:
        site = db.query(Site).filter(Site.id == inspection.site_id).first()
        inspector = db.query(User).filter(User.id == inspection.inspector_id).first()
        
        recent_inspections_data.append({
            "id": inspection.id,
            "site_name": site.name if site else "Unknown",
            "inspector_name": inspector.name if inspector else "Unknown",
            "category": inspection.category,
            "status": inspection.status,
            "inspected_at": inspection.inspected_at.isoformat() if inspection.inspected_at else None
        })
    
    # 미결 결함
    unresolved_defects_list = db.query(Defect).filter(
        Defect.resolved_at == None
    ).order_by(Defect.created_at.desc()).limit(10).all()
    
    unresolved_defects_data = []
    for defect in unresolved_defects_list:
        inspection = db.query(Inspection).filter(Inspection.id == defect.inspection_id).first()
        site = db.query(Site).filter(Site.id == inspection.site_id).first() if inspection else None
        
        unresolved_defects_data.append(DashboardDefectResponse(
            id=defect.id,
            site_name=site.name if site else "Unknown",
            inspection_id=defect.inspection_id,
            severity=defect.severity,
            description=defect.description,
            created_at=defect.created_at.isoformat() if defect.created_at else None
        ))
    
    return DashboardResponse(
        summary=summary,
        defect_summary=defect_summary,
        recent_inspections=recent_inspections_data,
        unresolved_defects=unresolved_defects_data
    )


class DailyInspectionStat(BaseModel):
    date: str
    count: int
    pass_count: int


class WeeklyStatsResponse(BaseModel):
    daily_inspections: list[DailyInspectionStat]
    defect_severity: DefectSummary


@router.get("/weekly-stats", response_model=WeeklyStatsResponse)
async def get_weekly_stats(
    _current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    today = datetime.now(timezone.utc).date()
    daily = []
    for i in range(6, -1, -1):
        day = today - timedelta(days=i)
        day_start = datetime(day.year, day.month, day.day, tzinfo=timezone.utc)
        day_end = day_start + timedelta(days=1)

        count = db.query(func.count(Inspection.id)).filter(
            Inspection.created_at >= day_start,
            Inspection.created_at < day_end,
        ).scalar() or 0

        pass_count = db.query(func.count(Inspection.id)).filter(
            Inspection.created_at >= day_start,
            Inspection.created_at < day_end,
            Inspection.status == InspectionStatus.pass_,
        ).scalar() or 0

        daily.append(DailyInspectionStat(
            date=day.strftime("%m/%d"),
            count=count,
            pass_count=pass_count,
        ))

    critical = db.query(func.count(Defect.id)).filter(
        Defect.severity == DefectSeverity.critical, Defect.resolved_at == None
    ).scalar() or 0
    major = db.query(func.count(Defect.id)).filter(
        Defect.severity == DefectSeverity.major, Defect.resolved_at == None
    ).scalar() or 0
    minor = db.query(func.count(Defect.id)).filter(
        Defect.severity == DefectSeverity.minor, Defect.resolved_at == None
    ).scalar() or 0

    return WeeklyStatsResponse(
        daily_inspections=daily,
        defect_severity=DefectSummary(critical=critical, major=major, minor=minor, total=critical + major + minor),
    )
