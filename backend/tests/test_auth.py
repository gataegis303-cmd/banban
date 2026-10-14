#  test_auth.py
#  Task 7：认证链路测试 —— 短信发码/验证登录、refresh 换发、logout 撤销、
#  设备令牌 upsert 换绑/注销、微信 dev 直通、未认证访问
#
#  验证码经由 APP_DEBUG=true 的 debug_code 从响应带出（conftest 注入），无需读日志。

import uuid

from sqlalchemy import select

from app.models.user import DeviceToken, User

API = "/api/v1/auth"


async def _sms_login(client, redis, phone: str) -> dict:
    """发码 + 验证登录，返回 TokenPairResponse 原始 dict"""
    r = await client.post(f"{API}/sms/send", json={"phone": phone})
    assert r.status_code == 200, r.text
    code = r.json()["debug_code"]
    r = await client.post(f"{API}/sms/verify", json={"phone": phone, "code": code})
    assert r.status_code == 200, r.text
    return r.json()


async def _clear_cooldown(redis, phone: str) -> None:
    """跳过 60s 重发间隔（模拟时间流逝），便于同号二次登录"""
    await redis.delete(f"banban:sms:cd:{phone}")


def _auth_headers(token_body: dict) -> dict:
    return {"Authorization": f"Bearer {token_body['access_token']}"}


# ── 短信发码 ──────────────────────────────────────────────


async def test_sms_send_cooldown_429(client):
    """60s 重发间隔：同号第二次立即 429 sms_cooldown"""
    r1 = await client.post(f"{API}/sms/send", json={"phone": "13800008001"})
    assert r1.status_code == 200
    r2 = await client.post(f"{API}/sms/send", json={"phone": "13800008001"})
    assert r2.status_code == 429
    assert r2.json()["error"]["code"] == "sms_cooldown"


async def test_sms_send_invalid_phone_422(client):
    """非大陆手机号格式 → 422 invalid_phone"""
    r = await client.post(f"{API}/sms/send", json={"phone": "12345"})
    assert r.status_code == 422
    assert r.json()["error"]["code"] == "invalid_phone"


# ── 短信验证登录 ──────────────────────────────────────────


async def test_sms_verify_new_user(client, redis):
    body = await _sms_login(client, redis, "13800008001")
    assert body["is_new_user"] is True
    assert body["user"]["verification"] == "phone_verified"
    assert body["access_token"] and body["refresh_token"]
    assert body["expires_in"] > 0


async def test_sms_verify_existing_user(client, redis):
    """同号二次登录：不再新建用户"""
    first = await _sms_login(client, redis, "13800008001")
    await _clear_cooldown(redis, "13800008001")
    second = await _sms_login(client, redis, "13800008001")
    assert second["is_new_user"] is False
    assert second["user"]["id"] == first["user"]["id"]


async def test_sms_verify_one_time_code(client, redis):
    """验证码一次性：成功校验后即删，重放 → 400 code_expired"""
    r = await client.post(f"{API}/sms/send", json={"phone": "13800008001"})
    code = r.json()["debug_code"]
    r1 = await client.post(f"{API}/sms/verify", json={"phone": "13800008001", "code": code})
    assert r1.status_code == 200
    r2 = await client.post(f"{API}/sms/verify", json={"phone": "13800008001", "code": code})
    assert r2.status_code == 400
    assert r2.json()["error"]["code"] == "code_expired"


async def test_sms_verify_wrong_code(client, redis):
    await client.post(f"{API}/sms/send", json={"phone": "13800008001"})
    # debug_code 为 6 位随机，000000 撞上的概率可忽略
    r = await client.post(f"{API}/sms/verify", json={"phone": "13800008001", "code": "000000"})
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "code_mismatch"


async def test_sms_verify_too_many_attempts_invalidates_code(client, redis):
    """连错 5 次强制作废：正确码也登不进，需重新发码"""
    phone = "13800008001"
    r = await client.post(f"{API}/sms/send", json={"phone": phone})
    real_code = r.json()["debug_code"]
    for _ in range(5):
        r = await client.post(f"{API}/sms/verify", json={"phone": phone, "code": "000000"})
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "too_many_attempts"
    # 作废后连正确码也过期
    r = await client.post(f"{API}/sms/verify", json={"phone": phone, "code": real_code})
    assert r.status_code == 400
    assert r.json()["error"]["code"] == "code_expired"


# ── refresh / logout ──────────────────────────────────────


async def test_refresh_exchanges_access_token(client, redis):
    login = await _sms_login(client, redis, "13800008001")
    r = await client.post(f"{API}/refresh", json={"refresh_token": login["refresh_token"]})
    assert r.status_code == 200
    body = r.json()
    assert body["access_token"]
    assert body["expires_in"] == login["expires_in"]


async def test_refresh_invalid_token_401(client):
    # min_length=32 的合法格式但库中不存在的 token
    r = await client.post(f"{API}/refresh", json={"refresh_token": "x" * 64})
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "invalid_refresh_token"


async def test_logout_revokes_refresh_token(client, redis):
    login = await _sms_login(client, redis, "13800008001")
    r = await client.post(f"{API}/logout", json={"refresh_token": login["refresh_token"]})
    assert r.status_code == 200
    # 撤销后 refresh 换发失败
    r = await client.post(f"{API}/refresh", json={"refresh_token": login["refresh_token"]})
    assert r.status_code == 401


async def test_logout_unknown_token_still_ok(client):
    """logout 未知 token 幂等返回 200（不泄露存在性）"""
    r = await client.post(f"{API}/logout", json={"refresh_token": "x" * 64})
    assert r.status_code == 200


# ── 设备令牌（APNs）───────────────────────────────────────

_TOKEN = "a1b2c3d4e5f60718293a4b5c6d7e8f90"  # ≥10 字符满足 DeviceTokenIn 校验


async def test_device_token_upsert_and_rebind(client, redis, db):
    """同 token 换账号上报改绑：只一行，user_id 指向最新上报者"""
    login_a = await _sms_login(client, redis, "13800008001")
    login_b = await _sms_login(client, redis, "13800008002")

    r = await client.put(
        "/api/v1/me/device-token", json={"token": _TOKEN, "platform": "ios"},
        headers=_auth_headers(login_a),
    )
    assert r.status_code == 204
    r = await client.put(
        "/api/v1/me/device-token", json={"token": _TOKEN, "platform": "ios"},
        headers=_auth_headers(login_b),
    )
    assert r.status_code == 204

    rows = (await db.execute(
        select(DeviceToken).where(DeviceToken.token == _TOKEN)
    )).scalars().all()
    assert len(rows) == 1
    assert str(rows[0].user_id) == login_b["user"]["id"]
    assert login_a["user"]["id"] != login_b["user"]["id"]


async def test_device_token_delete(client, redis, db):
    login = await _sms_login(client, redis, "13800008001")
    r = await client.put(
        "/api/v1/me/device-token", json={"token": _TOKEN, "platform": "ios"},
        headers=_auth_headers(login),
    )
    assert r.status_code == 204

    # 登出注销：凭 token 删除（无 Bearer），未知 token 同样 204
    r = await client.delete("/api/v1/me/device-token", params={"token": _TOKEN})
    assert r.status_code == 204
    assert (await db.execute(
        select(DeviceToken).where(DeviceToken.token == _TOKEN)
    )).scalars().all() == []

    r = await client.delete("/api/v1/me/device-token", params={"token": "unknown-token"})
    assert r.status_code == 204


# ── 微信 dev 直通（APP_DEBUG=true）────────────────────────


async def test_wechat_login_dev_passthrough(client, redis):
    r1 = await client.post(f"{API}/wechat/login", json={"code": "dev:unionid123"})
    assert r1.status_code == 200
    body = r1.json()
    assert body["is_new_user"] is True
    assert body["user"]["verification"] == "pending"  # 微信新用户待补手机验证

    r2 = await client.post(f"{API}/wechat/login", json={"code": "dev:unionid123"})
    assert r2.status_code == 200
    assert r2.json()["is_new_user"] is False
    assert r2.json()["user"]["id"] == body["user"]["id"]


# ── 未认证访问 ────────────────────────────────────────────


async def test_profile_requires_token(client):
    r = await client.get("/api/v1/me/profile")
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "missing_token"


async def test_profile_rejects_garbage_token(client):
    r = await client.get("/api/v1/me/profile", headers={"Authorization": "Bearer garbage"})
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "invalid_token"


async def test_profile_rejects_token_of_deleted_user(client, redis, db):
    """JWT 签名有效但用户已不存在 → 401 user_not_found"""
    login = await _sms_login(client, redis, "13800008001")
    user = await db.get(User, uuid.UUID(login["user"]["id"]))
    await db.delete(user)
    await db.flush()
    r = await client.get("/api/v1/me/profile", headers=_auth_headers(login))
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "user_not_found"
