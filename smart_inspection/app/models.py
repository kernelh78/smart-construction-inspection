"""
데이터베이스 모델 정의

User, Site, Inspection, Defect 모델을 정의합니다.
"""

from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Text, Enum, DECIMAL
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
import uuid

from .database import Base

class UserRole(str, enum.Enum):
    admin = "admin"
    inspector = "inspector"
    viewer = "viewer"

class SiteStatus(str, enum.Enum):
    active = "active"
    completed = "completed"
    paused = "paused"

class InspectionStatus(str, enum.Enum):
    pass_ = "pass"
    fail = "fail"
    pending = "pending"

class DefectSeverity(str, enum.Enum):
    critical = "critical"
    major = "major"
    minor = "minor"

# 사용자 모델
class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), nullable=False)
    email = Column(String(200), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    role = Column(Enum(UserRole), default=UserRole.inspector, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 관계
    inspections = relationship("Inspection", back_populates="inspector", lazy="joined")
    sites = relationship("Site", back_populates="manager", lazy="joined")
    defects = relationship("Defect", back_populates="resolved_by", lazy="joined")

# 현장 모델
class Site(Base):
    __tablename__ = "sites"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(200), nullable=False)
    address = Column(Text, nullable=False)
    lat = Column(DECIMAL(10, 8), nullable=True)
    lng = Column(DECIMAL(11, 8), nullable=True)
    status = Column(Enum(SiteStatus), default=SiteStatus.active, nullable=False)
    start_date = Column(DateTime(timezone=True), nullable=True)
    end_date = Column(DateTime(timezone=True), nullable=True)
    manager_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 관계
    manager = relationship("User", foreign_keys=[manager_id], back_populates="sites", lazy="joined")
    inspections = relationship("Inspection", back_populates="site", cascade="all, delete-orphan", lazy="joined")

# 점검 기록 모델
class Inspection(Base):
    __tablename__ = "inspections"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    site_id = Column(String(36), ForeignKey("sites.id"), nullable=False, index=True)
    inspector_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    category = Column(String(100), nullable=False)  # 공종 (골조/설비/전기 등)
    status = Column(Enum(InspectionStatus), default=InspectionStatus.pending, nullable=False)
    memo = Column(Text, nullable=True)  # 음성인식 변환 메모
    location_lat = Column(DECIMAL(10, 8), nullable=True)
    location_lng = Column(DECIMAL(11, 8), nullable=True)
    inspected_at = Column(DateTime(timezone=True), server_default=func.now())
    is_synced = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 관계
    site = relationship("Site", back_populates="inspections", lazy="joined")
    inspector = relationship("User", back_populates="inspections", lazy="joined")
    photos = relationship("InspectionPhoto", back_populates="inspection", cascade="all, delete-orphan", lazy="joined")
    defects = relationship("Defect", back_populates="inspection", cascade="all, delete-orphan", lazy="joined")

# 점검 사진 모델
class InspectionPhoto(Base):
    __tablename__ = "inspection_photos"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    inspection_id = Column(String(36), ForeignKey("inspections.id"), nullable=False)
    s3_key = Column(String(500), nullable=False)
    ocr_result = Column(Text, nullable=True)
    taken_at = Column(DateTime(timezone=True), server_default=func.now())

    # 관계
    inspection = relationship("Inspection", back_populates="photos", lazy="joined")

# 결함 모델
class Defect(Base):
    __tablename__ = "defects"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    inspection_id = Column(String(36), ForeignKey("inspections.id"), nullable=False, index=True)
    severity = Column(Enum(DefectSeverity), nullable=False)
    description = Column(Text, nullable=False)
    resolved_at = Column(DateTime(timezone=True), nullable=True)
    resolved_by_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # 관계
    inspection = relationship("Inspection", back_populates="defects", lazy="joined")
    resolved_by = relationship("User", foreign_keys=[resolved_by_id], back_populates="defects", lazy="joined")

# 인덱스 정의
from sqlalchemy import Index

Index("idx_inspections_site_id", Inspection.site_id, Inspection.inspected_at, unique=False)
Index("idx_inspections_sync", Inspection.is_synced, unique=False, postgresql_where=Inspection.is_synced == False)
Index("idx_defects_resolved", Defect.resolved_at, unique=False, postgresql_where=Defect.resolved_at == None)
