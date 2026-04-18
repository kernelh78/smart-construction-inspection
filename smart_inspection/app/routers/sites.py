"""
현장 관리 API 라우터

현장 CRUD 및 조회를 제공합니다.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel, Field
from datetime import datetime

from ..database import get_db
from ..models import Site, User, SiteStatus
from ..core.security import get_current_user

router = APIRouter()

# Pydantic 스키마
class SiteCreate(BaseModel):
    name: str
    address: str
    lat: float | None = None
    lng: float | None = None
    start_date: str | None = None
    end_date: str | None = None

class SiteUpdate(BaseModel):
    name: str | None = None
    address: str | None = None
    lat: float | None = None
    lng: float | None = None
    status: SiteStatus | None = None
    start_date: str | None = None
    end_date: str | None = None

class SiteResponse(BaseModel):
    id: str
    name: str
    address: str
    lat: float | None
    lng: float | None
    status: str
    start_date: str | None
    end_date: str | None
    manager_id: str | None
    created_at: datetime = Field(..., description="생성 시간")
    class Config:
        from_attributes = True

# 현장 목록 조회 API
@router.get("/", response_model=List[SiteResponse])
async def get_sites(
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    sites = db.query(Site).offset(skip).limit(limit).all()
    return sites

# 현장 상세 조회 API
@router.get("/{site_id}", response_model=SiteResponse)
async def get_site(
    site_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    site = db.query(Site).filter(Site.id == site_id).first()
    if not site:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Site not found"
        )
    return site

# 현장 등록 API
@router.post("/", response_model=SiteResponse, status_code=status.HTTP_201_CREATED)
async def create_site(
    site_data: SiteCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # 관리자만 현장 등록 가능 (RBAC 구현 필요)
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can create sites"
        )
    
    site = Site(
        name=site_data.name,
        address=site_data.address,
        lat=site_data.lat,
        lng=site_data.lng,
        start_date=site_data.start_date,
        end_date=site_data.end_date,
        status=SiteStatus.active
    )
    db.add(site)
    db.commit()
    db.refresh(site)
    return site

# 현장 정보 수정 API
@router.put("/{site_id}", response_model=SiteResponse)
async def update_site(
    site_id: str,
    site_data: SiteUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    site = db.query(Site).filter(Site.id == site_id).first()
    if not site:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Site not found"
        )
    
    # 관리자만 수정 가능
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can update sites"
        )
    
    update_data = site_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(site, field, value)
    
    db.commit()
    db.refresh(site)
    return site

# 현장 삭제 API
@router.delete("/{site_id}")
async def delete_site(
    site_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    site = db.query(Site).filter(Site.id == site_id).first()
    if not site:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Site not found"
        )
    
    # 관리자만 삭제 가능
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only admins can delete sites"
        )
    
    db.delete(site)
    db.commit()
    return {"message": "Site deleted successfully"}

