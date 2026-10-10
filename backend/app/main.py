#  main.py
#  FastAPI 应用入口：装配中间件、路由与统一错误体

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.adapters import oss
from app.config import settings
from app.routers import auth, chat, health, matches, profile, recommendations


@asynccontextmanager
async def lifespan(app: FastAPI):
    # 启动：WS Hub 在 P8 初始化
    yield
    # 关闭：释放 Redis 连接与数据库引擎连接池
    from app.deps import engine, redis_client

    await redis_client.aclose()
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


@app.exception_handler(RequestValidationError)
async def validation_error_handler(request: Request, exc: RequestValidationError):
    """请求体校验错误转统一错误体：code = invalid_{字段名}，与业务 422 错误码风格对齐"""
    errors = exc.errors()
    if errors:
        field = errors[0].get("loc", ("body",))[-1]
        code = f"invalid_{field}"
    else:
        code = "invalid_request"
    return JSONResponse(
        status_code=422,
        content={"error": {"code": code, "message": "请求参数格式不正确"}},
    )


@app.exception_handler(StarletteHTTPException)
async def unified_http_error_handler(request: Request, exc: StarletteHTTPException):
    """统一错误体：{"error": {"code": "...", "message": "..."}}，对齐 iOS APIError 解析"""
    if isinstance(exc.detail, dict):
        error = exc.detail
    else:
        error = {"code": f"http_{exc.status_code}", "message": str(exc.detail)}
    return JSONResponse(status_code=exc.status_code, content={"error": error})


app.include_router(health.router, prefix="/api/v1")
app.include_router(auth.router, prefix="/api/v1")
app.include_router(profile.router, prefix="/api/v1")
app.include_router(recommendations.router, prefix="/api/v1")
app.include_router(matches.router, prefix="/api/v1")
app.include_router(chat.router, prefix="/api/v1")

# 照片静态访问（开发环境本地落盘；生产由 OSS/CDN 替代）
# check_dir=False：photos 目录在首次保存时才创建
app.mount("/static", StaticFiles(directory=oss.PHOTOS_DIR, check_dir=False))
