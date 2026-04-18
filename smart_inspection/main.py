"""
FastAPI 애플리케이션 진입점

uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""

from app.main import app

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
