#  health.py
#  健康检查：/health 返回应用与依赖状态

from fastapi import APIRouter, Response
from sqlalchemy import text

from app.deps import engine

router = APIRouter(tags=["health"])


@router.get("/health")
async def health() -> dict:
    """存活探针：检查数据库连通性（Redis 在 P1 认证接入后加入）"""
    db_ok = False
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        db_ok = True
    except Exception:
        db_ok = False

    # 数据库不可达仍返回 200（应用本身存活），状态字段区分依赖健康
    return {
        "status": "ok",
        "app": "banban-api",
        "version": "0.1.0",
        "db": db_ok,
    }


@router.get("/health/ready")
async def readiness(response: Response) -> dict:
    """就绪探针：数据库必须可达才算 ready，否则 503"""
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
    except Exception:
        response.status_code = 503
        return {"status": "unavailable", "db": False}
    return {"status": "ready", "db": True}
