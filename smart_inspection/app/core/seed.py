"""
데이터베이스 시드 스크립트

기본 관리자 계정을 생성합니다.
"""

from sqlalchemy.orm import Session
import bcrypt
from ..database import SessionLocal, engine, Base
from ..models import User, UserRole

def hash_password(password: str) -> str:
    """
    비밀번호 해싱 (bcrypt 사용)
    """
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')

def verify_password(password: str, hashed_password: str) -> bool:
    """
    비밀번호 검증
    """
    return bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8'))

def create_admin_user(db: Session):
    """
    기본 관리자 계정 생성
    
    이메일: admin@smartinspection.com
    비밀번호: admin123
    """
    # 관리자 계정 확인
    existing_admin = db.query(User).filter(User.email == "admin@smartinspection.com").first()
    if existing_admin:
        print("Admin user already exists")
        return
    
    # 비밀번호 해싱
    hashed_password = hash_password("admin123")
    
    # 관리자 계정 생성
    admin = User(
        name="Admin",
        email="admin@smartinspection.com",
        hashed_password=hashed_password,
        role=UserRole.admin
    )
    
    db.add(admin)
    db.commit()
    db.refresh(admin)
    
    print(f"Admin user created: {admin.email} / admin123")

def create_sample_data(db: Session):
    """
    샘플 데이터 생성 (테스트용)
    """
    # 현장 생성
    from ..models import Site, SiteStatus
    from datetime import datetime
    
    sample_site = Site(
        name="테스트 건설 현장",
        address="서울시 강남구 테헤란로 123",
        lat=37.5665,
        lng=127.0000,
        status=SiteStatus.active,
        start_date=datetime(2025, 1, 1),
        end_date=datetime(2025, 12, 31)
    )
    db.add(sample_site)
    db.commit()
    db.refresh(sample_site)
    
    print(f"Sample site created: {sample_site.name} (ID: {sample_site.id})")

if __name__ == "__main__":
    # 데이터베이스 테이블 생성
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    try:
        # 관리자 계정 생성
        create_admin_user(db)
        
        # 샘플 데이터 생성 (선택적)
        # create_sample_data(db)
        
        print("Database seeding completed successfully!")
    finally:
        db.close()
