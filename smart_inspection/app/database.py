"""
데이터베이스 설정 모듈

SQLAlchemy 엔진 및 세션 생성을 담당합니다.
"""

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from .config import settings

DATABASE_URL = settings.DATABASE_URL

# 엔진 생성
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
)

# 세션 생성 클래스
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 기본 클래스
Base = declarative_base()

def get_db():
    """
    데이터베이스 세션 생성 함수
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
