#  main.py
#  FastAPI 应用入口：装配中间件与路由

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import health


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动：后续在此初始化 Redis 连接池 / WS Hub（P1/P8）
    yield
    # 关闭：释放引擎连接池
    from app.deps import engine

    await engine.dispose()


app = FastAPI(
    title="BanBan API",
    version="0.1.0",
    description="BanBan 搭伴交友平台后端",
    lifespan=lifespan,
)

# CORS：生产环境收敛到具体域名，开发放开本地
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if settings.app_debug else [],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, prefix="/api/v1")
