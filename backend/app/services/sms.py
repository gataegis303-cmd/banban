#  sms.py
#  短信验证码服务：生成 / 限流（60s 间隔、日上限、IP 上限）/ 存取 / 校验
#  全部热数据存 Redis；key 统一加 banban: 前缀避免与其他服务混用

import logging
import random
import re

from fastapi import HTTPException, Request, status

from app.adapters.aliyun_sms import SmsSendError, build_sms_sender
from app.config import settings
from app.deps import redis_client

logger = logging.getLogger("banban.sms")

# 中国大陆手机号
PHONE_PATTERN = re.compile(r"^1[3-9]\d{9}$")

KEY_PREFIX = "banban:sms"

# 发送渠道：模块加载时按配置选定（配了 AK → 阿里云，否则 dev mock）
_sender = build_sms_sender()

# 日上限窗口（简化为 24h 滑动，P13 限流加固时再按自然日切分）
_DAILY_WINDOW_SECONDS = settings.sms_code_ttl_seconds * 3


def validate_phone(phone: str) -> str:
    """手机号格式校验，不合法直接 422"""
    if not PHONE_PATTERN.match(phone):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"code": "invalid_phone", "message": "手机号格式不正确"},
        )
    return phone


def client_ip(request: Request) -> str:
    """取客户端真实 IP：nginx 反代场景优先读 X-Forwarded-For 首段"""
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


async def send_code(phone: str, ip: str) -> int:
    """发送验证码。返回重发冷却秒数；触发限流抛 429，渠道失败抛 502。

    限流键：
    - {p}:cd:{phone}     SET NX EX 60 → 60s 重发间隔
    - {p}:daily:{phone}  INCR + EXPIRE → 每日上限
    - {p}:ip:{ip}        INCR + EXPIRE → IP 每日上限
    """
    p = KEY_PREFIX

    # 60s 重发间隔（占位失败说明冷却窗口内已发过）
    cooldown_key = f"{p}:cd:{phone}"
    acquired = await redis_client.set(
        cooldown_key, "1", nx=True, ex=settings.sms_send_cooldown_seconds,
    )
    if not acquired:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "code": "sms_cooldown",
                "message": f"发送过于频繁，请 {settings.sms_send_cooldown_seconds} 秒后重试",
            },
        )

    # 手机号每日上限
    daily_count = await _incr_with_expire(f"{p}:daily:{phone}")
    if daily_count > settings.sms_daily_limit:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={"code": "sms_daily_limit", "message": "今日验证码发送次数已达上限"},
        )

    # IP 每日上限
    ip_count = await _incr_with_expire(f"{p}:ip:{ip}")
    if ip_count > settings.sms_ip_daily_limit:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={"code": "sms_ip_limit", "message": "当前网络发送次数已达上限"},
        )

    code = f"{random.randint(0, 999999):06d}"
    try:
        await _sender.send_code(phone, code)
    except SmsSendError as exc:
        # 发送失败立即释放冷却键，避免用户白等 60s
        await redis_client.delete(cooldown_key)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail={"code": "sms_provider_error", "message": "验证码发送失败，请稍后重试"},
        ) from exc

    # 存码：TTL 即有效期；同时重置校验尝试计数
    pipe = redis_client.pipeline()
    pipe.set(f"{p}:code:{phone}", code, ex=settings.sms_code_ttl_seconds)
    pipe.delete(f"{p}:att:{phone}")
    await pipe.execute()

    logger.info("验证码已发送 phone=%s ip=%s", phone, ip)
    return settings.sms_send_cooldown_seconds


async def verify_code(phone: str, code: str) -> None:
    """校验验证码：成功即删码（一次性）；失败计数，超限强制作废（需重新发送）"""
    p = KEY_PREFIX
    code_key = f"{p}:code:{phone}"
    att_key = f"{p}:att:{phone}"

    stored = await redis_client.get(code_key)
    if stored is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "code_expired", "message": "验证码已过期，请重新获取"},
        )

    if code != stored:
        attempts = await redis_client.incr(att_key)
        # 首次失败才设 TTL，生命周期与验证码对齐
        if attempts == 1:
            await redis_client.expire(att_key, settings.sms_code_ttl_seconds)
        if attempts >= settings.sms_code_max_attempts:
            # 连续错满：作废验证码，防止在线爆破
            await redis_client.delete(code_key, att_key)
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={"code": "too_many_attempts", "message": "错误次数过多，请重新获取验证码"},
            )
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "code_mismatch", "message": "验证码错误"},
        )

    # 校验通过：即用即删
    await redis_client.delete(code_key, att_key)


async def _incr_with_expire(key: str) -> int:
    """INCR 并在首次创建时补 EXPIRE"""
    count = await redis_client.incr(key)
    if count == 1:
        await redis_client.expire(key, _DAILY_WINDOW_SECONDS)
    return count
