"""
점검 기록 API 라우터

점검 기록 CRUD 및 조회를 제공합니다.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel
from datetime import datetime

from ..database import get_db
from ..models import Inspection, Site, User, InspectionStatus, InspectionPhoto, Defect
from ..core.security import get_current_user

router = APIRouter()

# Pydantic 스키마
class InspectionCreate(BaseModel):
    site_id: str
    inspector_id: str
    category: str
    status: InspectionStatus = InspectionStatus.pending
    memo: str | None = None
    location_lat: float | None = None
    location_lng: float | None = None

class InspectionUpdate(BaseModel):
    status: InspectionStatus | None = None
    memo: str | None = None
    location_lat: float | None = None
    location_lng: float | None = None

class InspectionResponse(BaseModel):
    id: str
    site_id: str
    inspector_id: str
    category: str
    status: str
    memo: str | None
    location_lat: float | None
    location_lng: float | None
    inspected_at: datetime
    is_synced: bool
    created_at: datetime

    class Config:
        from_attributes = True

class InspectionPhotoResponse(BaseModel):
    id: str
    inspection_id: str
    s3_key: str
    ocr_result: str | None
    taken_at: str

    class Config:
        from_attributes = True

class DefectResponse(BaseModel):
    id: str
    inspection_id: str
    severity: str
    description: str
    resolved_at: str | None
    resolved_by_id: str | None
    created_at: str

    class Config:
        from_attributes = True

# 점검 목록 조회 API
@router.get("/", response_model=List[InspectionResponse])
async def get_inspections(
    skip: int = 0,
    limit: int = 100,
    site_id: str | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(Inspection)
    if site_id:
        query = query.filter(Inspection.site_id == site_id)
    inspections = query.offset(skip).limit(limit).all()
    return inspections

# 현장별 점검 목록 조회 API
@router.get("/sites/{site_id}/inspections", response_model=List[InspectionResponse])
async def get_site_inspections(
    site_id: str,
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 현장 존재 확인
    site = db.query(Site).filter(Site.id == site_id).first()
    if not site:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Site not found"
        )
    
    inspections = db.query(Inspection).filter(
        Inspection.site_id == site_id
    ).offset(skip).limit(limit).all()
    return inspections

# 점검 기록 상세 조회 API
@router.get("/{inspection_id}", response_model=InspectionResponse)
async def get_inspection(
    inspection_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    inspection = db.query(Inspection).filter(Inspection.id == inspection_id).first()
    if not inspection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inspection not found"
        )
    return inspection

# 점검 기록 등록 API
@router.post("/", response_model=InspectionResponse, status_code=status.HTTP_201_CREATED)
async def create_inspection(
    inspection_data: InspectionCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 현장 존재 확인
    site = db.query(Site).filter(Site.id == inspection_data.site_id).first()
    if not site:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Site not found"
        )
    
    # 감리자 존재 확인
    inspector = db.query(User).filter(User.id == inspection_data.inspector_id).first()
    if not inspector:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inspector not found"
        )
    
    inspection = Inspection(
        site_id=inspection_data.site_id,
        inspector_id=inspection_data.inspector_id,
        category=inspection_data.category,
        status=inspection_data.status,
        memo=inspection_data.memo,
        location_lat=inspection_data.location_lat,
        location_lng=inspection_data.location_lng,
        is_synced=True
    )
    db.add(inspection)
    db.commit()
    db.refresh(inspection)
    return inspection

# 점검 기록 수정 API
@router.put("/{inspection_id}", response_model=InspectionResponse)
async def update_inspection(
    inspection_id: str,
    inspection_data: InspectionUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    inspection = db.query(Inspection).filter(Inspection.id == inspection_id).first()
    if not inspection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inspection not found"
        )
    
    update_data = inspection_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(inspection, field, value)
    
    db.commit()
    db.refresh(inspection)
    return inspection

# 점검 기록 삭제 API
@router.delete("/{inspection_id}")
async def delete_inspection(
    inspection_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    inspection = db.query(Inspection).filter(Inspection.id == inspection_id).first()
    if not inspection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inspection not found"
        )
    
    db.delete(inspection)
    db.commit()
    return {"message": "Inspection deleted successfully"}

# 사진 업로드 API
@router.post("/{inspection_id}/photos", response_model=InspectionPhotoResponse)
async def upload_inspection_photo(
    inspection_id: str,
    s3_key: str,
    ocr_result: str | None = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    inspection = db.query(Inspection).filter(Inspection.id == inspection_id).first()
    if not inspection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inspection not found"
        )
    
    photo = InspectionPhoto(
        inspection_id=inspection_id,
        s3_key=s3_key,
        ocr_result=ocr_result
    )
    db.add(photo)
    db.commit()
    db.refresh(photo)
    return photo

# 결함 등록 API
@router.post("/{inspection_id}/defects", response_model=DefectResponse)
async def create_defect(
    inspection_id: str,
    severity: str,
    description: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    inspection = db.query(Inspection).filter(Inspection.id == inspection_id).first()
    if not inspection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inspection not found"
        )
    
    defect = Defect(
        inspection_id=inspection_id,
        severity=severity,
        description=description,
        resolved_by_id=current_user.id
    )
    db.add(defect)
    db.commit()
    db.refresh(defect)
    return defect
