#  rate_limit.py
#  通用 IP 限流：Redis INCR + EXPIRE 固定窗口计数器（FastAPI 依赖工厂形式）
#
#  用法：dependencies=[Depends(rate_limit("scope", limit=N, window_seconds=S))]
#  计数键带窗口序号：跨窗口自动换新键，旧键由 TTL 自然过期。
#  多实例部署时计数集中在 Redis，语义不变。

import time

from fastapi import HTTPException, Request, status

from app.deps import client_ip, redis_client


def rate_limit(scope: str, *, limit: int, window_seconds: int):
    """按「客户端 IP + scope」限流的 FastAPI 依赖工厂（固定窗口）。"""
    prefix = f"banban:rl:{scope}"

    async def dependency(request: Request) -> None:
        ip = client_ip(request)
        window = int(time.time()) // window_seconds
        key = f"{prefix}:{ip}:{window}"
        count = await redis_client.incr(key)
        if count == 1:
            await redis_client.expire(key, window_seconds)
        if count > limit:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail={"code": "rate_limited", "message": "请求过于频繁，请稍后重试"},
            )

    return dependency
