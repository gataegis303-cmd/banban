#  test_chat_push_filter.py
#  Task 9 测试：HTTP 兜底发消息（未读累加 / seq / 摘要 / 已读 / 非参与方 404）、
#  APNs 离线才推（hub.is_online 分支）、筛选条件惰性建行与全量覆盖

import pytest

from app.models.chat import Conversation
from app.models.matching import Match
from app.models.profile import Profile
from app.models.user import DeviceToken, User
from app.services.auth import create_access_token
from app.ws.hub import hub

API = "/api/v1"


async def _make_matched_pair(db, *, with_profile: bool = False):
    """两个用户 + match + conversation（UUID 升序对齐 matches 的 user_a < user_b 约束）"""
    ua = User(phone="13800009001")
    ub = User(phone="13800009002")
    db.add_all([ua, ub])
    await db.flush()
    user_a_id, user_b_id = sorted([ua.id, ub.id])
    match = Match(user_a_id=user_a_id, user_b_id=user_b_id)
    db.add(match)
    await db.flush()
    conv = Conversation(user_a_id=ua.id, user_b_id=ub.id, match_id=match.id)
    db.add(conv)
    if with_profile:
        db.add(Profile(user_id=ua.id, nickname="小斑"))
    await db.flush()
    return ua, ub, conv


def _auth_headers(user: User) -> dict:
    token, _ = create_access_token(user.id)
    return {"Authorization": f"Bearer {token}"}


class _FakeAPNS:
    """记录 send 调用的假 APNs 客户端"""

    def __init__(self) -> None:
        self.sent: list[tuple[str, dict]] = []

    async def send(self, token: str, payload: dict) -> None:
        self.sent.append((token, payload))


@pytest.fixture
def fake_apns(monkeypatch):
    fake = _FakeAPNS()
    monkeypatch.setattr("app.adapters.apns.get_apns_sender", lambda: fake)
    return fake


# ── 会话/消息链路 ─────────────────────────────────────────────


async def test_send_message_increments_unread(client, db):
    """发 2 条消息：seq 递增、摘要取最新、接收方未读累加为 2、发送方为 0"""
    ua, ub, conv = await _make_matched_pair(db)
    h_ua = _auth_headers(ua)
    h_ub = _auth_headers(ub)

    r1 = await client.post(
        f"{API}/conversations/{conv.id}/messages", json={"content": "你好"}, headers=h_ua,
    )
    assert r1.status_code == 201, r1.text
    r2 = await client.post(
        f"{API}/conversations/{conv.id}/messages", json={"content": "在吗"}, headers=h_ua,
    )
    assert r2.status_code == 201
    assert r2.json()["seq"] == 2

    r = await client.get(f"{API}/conversations", headers=h_ua)
    assert r.status_code == 200
    assert r.json()["items"][0]["unread_count"] == 0
    assert r.json()["items"][0]["last_message_text"] == "在吗"

    r = await client.get(f"{API}/conversations", headers=h_ub)
    assert r.json()["items"][0]["unread_count"] == 2


async def test_messages_history_and_mark_read(client, db):
    """消息历史按 seq 旧→新返回；对方已读后未读清零"""
    ua, ub, conv = await _make_matched_pair(db)
    h_ua = _auth_headers(ua)
    h_ub = _auth_headers(ub)
    for content in ("第一条", "第二条"):
        r = await client.post(
            f"{API}/conversations/{conv.id}/messages", json={"content": content}, headers=h_ua,
        )
        assert r.status_code == 201

    r = await client.get(f"{API}/conversations/{conv.id}/messages", headers=h_ub)
    items = r.json()["items"]
    assert [m["seq"] for m in items] == [1, 2]
    assert [m["content"] for m in items] == ["第一条", "第二条"]

    r = await client.post(f"{API}/conversations/{conv.id}/read", headers=h_ub)
    assert r.status_code == 204
    r = await client.get(f"{API}/conversations", headers=h_ub)
    assert r.json()["items"][0]["unread_count"] == 0


async def test_conversation_hidden_from_outsider(client, db):
    """非参与方访问会话消息一律 404，不泄露存在性"""
    ua, _, conv = await _make_matched_pair(db)
    outsider = User(phone="13800009003")
    db.add(outsider)
    await db.flush()

    r = await client.get(
        f"{API}/conversations/{conv.id}/messages", headers=_auth_headers(outsider),
    )
    assert r.status_code == 404
    assert r.json()["error"]["code"] == "conversation_not_found"


# ── APNs 离线推送 ─────────────────────────────────────────────


async def test_push_offline_only(client, db, fake_apns):
    """对方在线不推（WS 实时送达）；离线才推且 payload 完整（badge=累计未读）"""
    ua, ub, conv = await _make_matched_pair(db, with_profile=True)
    db.add(DeviceToken(user_id=ub.id, token="ub-device-token-abcdef"))
    await db.flush()
    h_ua = _auth_headers(ua)

    # 对方在线：不推
    ws = object()  # hub 仅作集合成员，哨兵对象即可
    await hub.connect(ub.id, ws)
    try:
        r = await client.post(
            f"{API}/conversations/{conv.id}/messages", json={"content": "第一条"}, headers=h_ua,
        )
        assert r.status_code == 201
        assert fake_apns.sent == []
    finally:
        await hub.disconnect(ub.id, ws)

    # 对方离线：推送到其注册设备
    r = await client.post(
        f"{API}/conversations/{conv.id}/messages", json={"content": "第二条"}, headers=h_ua,
    )
    assert r.status_code == 201
    assert len(fake_apns.sent) == 1
    token, payload = fake_apns.sent[0]
    assert token == "ub-device-token-abcdef"
    assert payload["aps"]["alert"]["title"] == "小斑"
    assert payload["aps"]["alert"]["body"] == "第二条"
    assert payload["aps"]["badge"] == 2  # 该会话累计未读
    assert payload["conversation_id"] == str(conv.id)


async def test_push_skipped_without_device_token(client, db, fake_apns):
    """对方离线但未注册设备令牌 → 静默跳过，不报错不推送"""
    ua, _, conv = await _make_matched_pair(db)
    r = await client.post(
        f"{API}/conversations/{conv.id}/messages", json={"content": "hi"},
        headers=_auth_headers(ua),
    )
    assert r.status_code == 201
    assert fake_apns.sent == []


# ── 筛选条件 ──────────────────────────────────────────────────


async def test_filter_defaults_lazy_create(client, db):
    """GET /me/filter 无行时惰性建行，返回默认筛选（20-40 岁、其余不限）"""
    ua, _, _ = await _make_matched_pair(db)
    r = await client.get(f"{API}/me/filter", headers=_auth_headers(ua))
    assert r.status_code == 200
    body = r.json()
    assert body["age_min"] == 20
    assert body["age_max"] == 40
    assert body["pets"] == []
    assert body["no_accept"] == []


async def test_filter_put_overrides(client, db):
    """PUT /me/filter 全量覆盖生效，再读为更新后的值"""
    ua, _, _ = await _make_matched_pair(db)
    headers = _auth_headers(ua)
    body = {
        "city": "杭州", "age_min": 25, "age_max": 35,
        "direction": "异地可接受", "pets": ["猫"], "no_accept": ["吸烟"],
    }
    r = await client.put(f"{API}/me/filter", json=body, headers=headers)
    assert r.status_code == 200, r.text
    assert r.json()["age_min"] == 25
    assert r.json()["city"] == "杭州"

    r = await client.get(f"{API}/me/filter", headers=headers)
    assert r.json()["age_min"] == 25
    assert r.json()["no_accept"] == ["吸烟"]
