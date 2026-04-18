from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from .database import engine, Base
from .routers import auth, sites, inspections, reports, dashboard, websocket
from .config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="Smart Inspection API",
    description="스마트 건설 감리 실시간 관리 시스템 API",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.get_allowed_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(sites.router, prefix="/api/v1/sites", tags=["Site Management"])
app.include_router(inspections.router, prefix="/api/v1/inspections", tags=["Inspection Records"])
app.include_router(reports.router, prefix="/api/v1/reports", tags=["Reports"])
app.include_router(dashboard.router, prefix="/api/v1/dashboard", tags=["Dashboard"])
app.include_router(websocket.router, tags=["WebSocket"])


@app.get("/")
def root():
    return {"message": "Smart Inspection API is running"}
