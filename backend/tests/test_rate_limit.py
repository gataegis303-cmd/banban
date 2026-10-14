#  test_rate_limit.py
#  Task 8 限流测试：rate_limit 固定窗口计数与 429、sms 自然日/IP 每日上限
#  通过 fakeredis 直接操纵限流键，避免真实等待窗口滚动

import time

from app.config import settings
from app.services.sms import KEY_PREFIX, _today_key_suffix

API = "/api/v1/auth"

# ASGITransport 固定对端地址（httpx scope["client"] = ("127.0.0.1", 123)）
_TEST_IP = "127.0.0.1"


def _rl_key(scope: str, ip: str = _TEST_IP) -> str:
    """当前窗口的 rate_limit 计数键（window = epoch // 60）"""
    return f"banban:rl:{scope}:{ip}:{int(time.time()) // 60}"


async def _verify_once(client):
    """发一次格式合法的 verify 请求（redis 无码 → 业务层 400 code_expired）"""
    return await client.post(
        f"{API}/sms/verify", json={"phone": "13800008001", "code": "123456"},
    )


async def test_rate_limit_blocks_at_limit(client, redis):
    """预置计数已满（10/min）→ 下一次请求 429 rate_limited"""
    await redis.set(_rl_key("sms_verify"), settings.rate_limit_verify_per_minute)

    r = await _verify_once(client)
    assert r.status_code == 429
    assert r.json()["error"]["code"] == "rate_limited"


async def test_rate_limit_window_rolls(client, redis):
    """窗口键清空（模拟跨窗口）→ 计数归零放行，且本次请求重建计数"""
    key = _rl_key("sms_verify")
    await redis.set(key, settings.rate_limit_verify_per_minute)
    assert (await _verify_once(client)).status_code == 429

    await redis.delete(key)  # 模拟跨窗口换新键
    r = await _verify_once(client)
    assert r.status_code == 400  # 非 429：limiter 放行
    assert r.json()["error"]["code"] == "code_expired"
    assert int(await redis.get(key)) == 1


async def test_rate_limit_key_ttl(client, redis):
    """首次计数写入后带窗口 TTL（≤60s），旧键自动过期"""
    r = await _verify_once(client)
    assert r.status_code == 400  # limiter 放行

    ttl = await redis.ttl(_rl_key("sms_verify"))
    assert 0 < ttl <= 60


async def test_rate_limit_per_ip_isolated(client, redis, monkeypatch):
    """不同来源 IP 各自计数（trusted_proxy_count=1 取 XFF 尾段，F3 语义）"""
    monkeypatch.setattr(settings, "app_trusted_proxy_count", 1)
    await redis.set(_rl_key("sms_verify", "9.9.9.9"), settings.rate_limit_verify_per_minute)

    # 该 IP 已满 → 429
    r = await _verify_once_with_ip(client, "1.1.1.1, 9.9.9.9")
    assert r.status_code == 429

    # 换 IP → 放行
    r = await _verify_once_with_ip(client, "1.1.1.1, 8.8.8.8")
    assert r.status_code == 400


async def _verify_once_with_ip(client, xff: str):
    return await client.post(
        f"{API}/sms/verify",
        json={"phone": "13800008001", "code": "123456"},
        headers={"X-Forwarded-For": xff},
    )


async def test_sms_daily_limit_429(client, redis):
    """手机号自然日计数已满（10/日）→ 429 sms_daily_limit"""
    phone = "13800008001"
    daily_key = f"{KEY_PREFIX}:daily:{phone}:{_today_key_suffix()}"
    await redis.set(daily_key, settings.sms_daily_limit)

    r = await client.post(f"{API}/sms/send", json={"phone": phone})
    assert r.status_code == 429
    assert r.json()["error"]["code"] == "sms_daily_limit"


async def test_sms_ip_daily_limit_429(client, redis):
    """IP 自然日计数已满（20/日）→ 429 sms_ip_limit"""
    phone = "13800008002"
    ip_key = f"{KEY_PREFIX}:ip:{_TEST_IP}:{_today_key_suffix()}"
    await redis.set(ip_key, settings.sms_ip_daily_limit)

    r = await client.post(f"{API}/sms/send", json={"phone": phone})
    assert r.status_code == 429
    assert r.json()["error"]["code"] == "sms_ip_limit"


async def test_sms_daily_key_uses_natural_day_window(client, redis):
    """发送成功后写入带 YYYYMMDD 后缀的日计数键，且带次日过期 TTL（东八区自然日归零）"""
    phone = "13800008003"
    r = await client.post(f"{API}/sms/send", json={"phone": phone})
    assert r.status_code == 200, r.text

    daily_key = f"{KEY_PREFIX}:daily:{phone}:{_today_key_suffix()}"
    assert await redis.get(daily_key) == "1"
    assert await redis.ttl(daily_key) > 0
