#  handler.py
#  /ws/chat 端点：JWT 认证 → Hub 注册 → 事件循环（message/typing/read/ping）
#
#  认证：query param token（浏览器 WebSocket API 无法自定义 Header）；
#  校验失败以自定义 close code 4401 拒绝。
#  每个连接独占一个 DB 会话（长连接持有，原型阶段连接量小可接受）。

import contextlib
import json
import uuid

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from jose import JWTError
from jose import jwt as jose_jwt
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.deps import AsyncSessionFactory
from app.models.chat import Conversation
from app.models.user import User
from app.schemas.chat import SendMessageIn
from app.services import chat, presence
from app.ws import events
from app.ws.hub import hub

router = APIRouter()

# 自定义 close code（4000-4990 应用保留段）
CLOSE_INVALID_TOKEN = 4401

# WS 消息载荷约束（与 SendMessageIn 对齐）
_MAX_CONTENT_LEN = 2000
_MAX_CLIENT_MSG_ID_LEN = 64


@router.websocket("/ws/chat")
async def chat_socket(ws: WebSocket, token: str = Query(default="")) -> None:
    user_id = _decode_access_token(token)
    if user_id is None:
        await ws.close(code=CLOSE_INVALID_TOKEN)
        return
    # 确认用户仍存在（JWT 有效但用户可能已注销）
    async with AsyncSessionFactory() as db:
        if await db.get(User, user_id) is None:
            await ws.close(code=CLOSE_INVALID_TOKEN)
            return

    await ws.accept()
    await hub.connect(user_id, ws)
    await _broadcast_online_status(user_id, online=True)

    try:
        async with AsyncSessionFactory() as db:
            await presence.set_online(db, user_id)
            # hello 附带当前在线的匹配对象：后连接方能立即感知对方在线
            # （online_status 只广播增量事件，错过不补）
            partner_ids = await presence.match_partner_ids(db, user_id)
            online_partners = [pid for pid in partner_ids if hub.is_online(pid)]
            await _send(ws, {
                "type": events.HELLO,
                "user_id": str(user_id),
                "online_partner_ids": [str(pid) for pid in online_partners],
            })
            while True:
                raw = await ws.receive_text()
                try:
                    event = json.loads(raw)
                except json.JSONDecodeError:
                    await _send(ws, _error("invalid_json", "事件格式不正确"))
                    continue
                if not isinstance(event, dict):
                    await _send(ws, _error("invalid_json", "事件格式不正确"))
                    continue
                await _dispatch(db, user_id, ws, event)
    except WebSocketDisconnect:
        pass
    finally:
        await hub.disconnect(user_id, ws)
        await _broadcast_online_status(user_id, online=False)
        async with AsyncSessionFactory() as db:
            await presence.set_offline(db, user_id)


# ── 事件分发 ──────────────────────────────────────────────────


async def _dispatch(
    db: AsyncSession, user_id: uuid.UUID, ws: WebSocket, event: dict
) -> None:
    etype = event.get("type")
    match etype:
        case events.PING:
            await presence.touch(user_id)  # 心跳续期在线态
            await _send(ws, {"type": events.PONG})
        case events.MESSAGE:
            await _handle_message(db, user_id, ws, event)
        case events.TYPING:
            await _handle_typing(db, user_id, event)
        case events.READ:
            await _handle_read(db, user_id, event)
        case _:
            await _send(ws, _error("unknown_event", f"未知事件类型 {etype!r}"))


async def _handle_message(
    db: AsyncSession, user_id: uuid.UUID, ws: WebSocket, event: dict
) -> None:
    conversation_id = _parse_uuid(event.get("conversation_id"))
    content = event.get("content")
    client_msg_id = event.get("client_msg_id")
    if (
        conversation_id is None
        or not isinstance(content, str)
        or not 1 <= len(content) <= _MAX_CONTENT_LEN
        or (client_msg_id is not None and not isinstance(client_msg_id, str))
        or (isinstance(client_msg_id, str) and len(client_msg_id) > _MAX_CLIENT_MSG_ID_LEN)
    ):
        await _send(ws, _error("invalid_message", "消息格式不正确"))
        return

    try:
        message = await chat.send_message(
            db, user_id, conversation_id,
            SendMessageIn(content=content, client_msg_id=client_msg_id),
        )
    except Exception:
        # 会话不存在 / 非参与方等：统一 error 回执，不断开连接
        await _send(ws, _error("send_failed", "消息发送失败"))
        return

    payload = {"message": message.model_dump(mode="json")}
    # ack：发送方连接替换临时 id
    await _send(ws, {
        "type": events.ACK,
        "conversation_id": str(conversation_id),
        "client_msg_id": client_msg_id,
        **payload,
    })
    # message 广播：双方所有连接（含发送者的其他设备）
    await hub.send_to_user(user_id, {
        "type": events.MESSAGE,
        "conversation_id": str(conversation_id),
        **payload,
    })
    other_id = await _other_participant(db, user_id, conversation_id)
    if other_id is not None:
        await hub.send_to_user(other_id, {
            "type": events.MESSAGE,
            "conversation_id": str(conversation_id),
            **payload,
        })


async def _handle_typing(db: AsyncSession, user_id: uuid.UUID, event: dict) -> None:
    conversation_id = _parse_uuid(event.get("conversation_id"))
    if conversation_id is None:
        return  # typing 属可丢弃信号，格式不对静默忽略
    other_id = await _other_participant(db, user_id, conversation_id)
    if other_id is not None:
        await hub.send_to_user(other_id, {
            "type": events.TYPING,
            "conversation_id": str(conversation_id),
            "user_id": str(user_id),
        })


async def _handle_read(db: AsyncSession, user_id: uuid.UUID, event: dict) -> None:
    conversation_id = _parse_uuid(event.get("conversation_id"))
    if conversation_id is None:
        return
    try:
        await chat.mark_read(db, user_id, conversation_id)
    except Exception:
        return  # 会话不存在 / 非参与方，静默忽略
    other_id = await _other_participant(db, user_id, conversation_id)
    if other_id is not None:
        await hub.send_to_user(other_id, {
            "type": events.READ,
            "conversation_id": str(conversation_id),
            "user_id": str(user_id),
        })


async def _other_participant(
    db: AsyncSession, user_id: uuid.UUID, conversation_id: uuid.UUID
) -> uuid.UUID | None:
    """会话对方的 user_id；非参与方返回 None"""
    conversation = await db.get(Conversation, conversation_id)
    if conversation is None:
        return None
    if conversation.user_a_id == user_id:
        return conversation.user_b_id
    if conversation.user_b_id == user_id:
        return conversation.user_a_id
    return None


async def _broadcast_online_status(user_id: uuid.UUID, *, online: bool) -> None:
    """我的上下线通知我的全部匹配对象（只发当前在 Hub 里的）。"""
    async with AsyncSessionFactory() as db:
        partner_ids = await presence.match_partner_ids(db, user_id)
    event = {
        "type": events.ONLINE_STATUS,
        "user_id": str(user_id),
        "online": online,
    }
    for partner_id in partner_ids:
        if hub.is_online(partner_id):
            await hub.send_to_user(partner_id, event)


# ── 基础辅助 ──────────────────────────────────────────────────


def _decode_access_token(token: str) -> uuid.UUID | None:
    try:
        payload = jose_jwt.decode(
            token, settings.app_secret_key, algorithms=[settings.jwt_algorithm]
        )
        if payload.get("type") != "access":
            return None
        return uuid.UUID(payload["sub"])
    except (JWTError, KeyError, ValueError):
        return None


def _error(code: str, message: str) -> dict:
    return {"type": events.ERROR, "error": {"code": code, "message": message}}


def _parse_uuid(value: object) -> uuid.UUID | None:
    if not isinstance(value, str):
        return None
    try:
        return uuid.UUID(value)
    except ValueError:
        return None


async def _send(ws: WebSocket, payload: dict) -> None:
    """单连接发送；失败静默（连接已断时 receive 循环会抛 Disconnect 走清理）"""
    with contextlib.suppress(Exception):
        await ws.send_text(json.dumps(payload, ensure_ascii=False))
