#  conftest.py
#  pytest 基础设施：banban_test 独立库 + fakeredis 打桩 + 请求级事务回滚
#
#  隔离策略：
#  - DB：每用例外层事务 + SAVEPOINT（join_transaction_mode="create_savepoint"），
#    服务层显式 commit 也逃不出外层事务，用例结束统一回滚，无需 truncate
#  - Redis：每用例全新 FakeAsyncRedis 实例；sms/auth/presence/rate_limit 均为
#    import 时 from-import 绑定，需逐个 patch（不随 deps 模块属性动态更新）
#  - engine 用 NullPool：不跨事件循环持有连接，pytest-asyncio 每用例新 loop 也安全

import asyncio
import os

# 必须在导入任何 app.* 之前注入测试环境（pydantic-settings 中环境变量优先于 .env）
os.environ["DATABASE_URL"] = os.environ.get(
    "BANBAN_TEST_DATABASE_URL",
    "postgresql+asyncpg://banban:banban_dev_2025@localhost:5432/banban_test",
)
os.environ["APP_DEBUG"] = "true"  # 测试走 dev 降级：debug_code 可直接从响应读验证码
os.environ["APP_SECRET_KEY"] = "test-secret-key-not-for-production"

import pytest  # noqa: E402
from fakeredis import FakeAsyncRedis  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402
from sqlalchemy.ext.asyncio import (  # noqa: E402
    AsyncSession,
    create_async_engine,
)
from sqlalchemy.pool import NullPool  # noqa: E402

import app.models  # noqa: E402, F401  全量注册模型到 Base.metadata
from app.config import settings  # noqa: E402
from app.deps import get_db  # noqa: E402
from app.main import app  # noqa: E402
from app.models.base import Base  # noqa: E402

# 测试专用引擎：指向 banban_test，NullPool 保证连接不跨事件循环复用
test_engine = create_async_engine(settings.database_url, poolclass=NullPool)


@pytest.fixture(scope="session", autouse=True)
def _create_tables():
    """会话开始时按当前模型建表（独立临时事件循环，NullPool 不留连接）"""

    async def _run():
        async with test_engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

    asyncio.run(_run())
    yield


@pytest.fixture
async def db():
    """每用例独立事务的 AsyncSession，用例结束整体回滚"""
    async with test_engine.connect() as conn:
        trans = await conn.begin()
        session = AsyncSession(
            bind=conn, expire_on_commit=False, join_transaction_mode="create_savepoint",
        )
        yield session
        await session.close()
        await trans.rollback()


@pytest.fixture
async def redis(monkeypatch):
    """fakeredis 实例，patch 全部 import 时绑定点"""
    fake = FakeAsyncRedis(decode_responses=True)
    for target in (
        "app.deps.redis_client",
        "app.routers.auth.redis_client",
        "app.services.sms.redis_client",
        "app.services.presence.redis_client",
        "app.services.rate_limit.redis_client",
    ):
        monkeypatch.setattr(target, fake)
    yield fake
    await fake.aclose()


@pytest.fixture
async def client(db, redis, monkeypatch):
    """httpx AsyncClient：覆盖 get_db 注入测试事务会话，engine 换 NullPool 测试引擎"""
    monkeypatch.setattr("app.deps.engine", test_engine)
    monkeypatch.setattr("app.routers.health.engine", test_engine)  # health 为 import 时绑定

    async def _override_get_db():
        yield db

    app.dependency_overrides[get_db] = _override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()
