#  test_smoke.py
#  Task 6 验收冒烟：conftest 基础设施（banban_test 库 / fakeredis / 事务回滚）全链路可用


async def test_health_db_ready(client):
    resp = await client.get("/api/v1/health")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ok"
    assert body["db"] is True  # 测试引擎连通 banban_test


async def test_sms_send_writes_fakeredis(client, redis):
    """发码走 dev 降级：验证码从响应带出，且确实写入 fakeredis 实例而非真实 Redis"""
    resp = await client.post("/api/v1/auth/sms/send", json={"phone": "13800008001"})
    assert resp.status_code == 200
    body = resp.json()
    code = body["debug_code"]
    assert code and len(code) == 6 and code.isdigit()
    assert await redis.get("banban:sms:code:13800008001") == code
