"""
보고서 생성 API 라우터

일일/주간 감리보고서 PDF 생성을 제공합니다.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime, timedelta

from ..database import get_db
from ..models import Inspection, Defect, Site, User
from ..core.security import get_current_user
from ..core.reports import ReportGenerator

router = APIRouter()

# Pydantic 스키마
class DailyReportRequest(BaseModel):
    end_date: str  # 일일 보고서는 end_date만 필요

class WeeklyReportRequest(BaseModel):
    start_date: str
    end_date: str  # 주간 보고서는 start_date, end_date 필요
class ReportResponse(BaseModel):
    id: str
    report_type: str
    site_id: str | None
    start_date: str
    end_date: str
    generated_at: str
    download_url: str

    class Config:
        from_attributes = True

# 일일 보고서 생성 API
@router.post("/daily", response_class=Response)
async def generate_daily_report(
    report_data: DailyReportRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # ReportGenerator 인스턴스 생성
        generator = ReportGenerator(db)
        
        # 대상 날짜 파싱
        target_date = datetime.strptime(report_data.end_date, "%Y-%m-%d")
        
        # PDF 생성
        pdf_content = generator.generate_daily_report(target_date)
        
        # PDF 응답 반환
        return Response(
            content=pdf_content,
            media_type="application/pdf",
            headers={
                "Content-Disposition": f"attachment; filename=daily_report_{target_date.strftime('%Y%m%d')}.pdf"
            }
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"보고서 생성 중 오류 발생: {str(e)}"
        )

# 주간 보고서 생성 API
@router.post("/weekly", response_class=Response)
async def generate_weekly_report(
    report_data: WeeklyReportRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    try:
        # ReportGenerator 인스턴스 생성
        generator = ReportGenerator(db)
        
        # 대상 날짜 파싱
        end_date = datetime.strptime(report_data.end_date, "%Y-%m-%d")
        start_date = datetime.strptime(report_data.start_date, "%Y-%m-%d")
        
        # 주간 보고서 생성 (7일 기준)
        weeks = (end_date - start_date).days // 7
        if weeks < 1:
            weeks = 1
        
        # PDF 생성
        pdf_content = generator.generate_weekly_report(weeks)
        
        # PDF 응답 반환
        return Response(
            content=pdf_content,
            media_type="application/pdf",
            headers={
                "Content-Disposition": f"attachment; filename=weekly_report_{start_date.strftime('%Y%m%d')}_to_{end_date.strftime('%Y%m%d')}.pdf"
            }
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"보고서 생성 중 오류 발생: {str(e)}"
        )

# 보고서 다운로드 API (호환성용)
@router.get("/{report_id}/download")
async def download_report(
    report_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # PDF 파일 다운로드 로직 (S3 연동 필요)
    # 현재는 더미 응답 반환
    return {
        "message": "PDF 다운로드 준비 중...",
        "report_id": report_id,
        "download_url": f"https://s3.amazonaws.com/reports/{report_id}.pdf"
    }

