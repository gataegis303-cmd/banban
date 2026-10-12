#  push.py
#  APNs 离线推送服务：对方 WS 离线时，向其注册设备推送新消息通知
#
#  推送为 best-effort 旁路：任何失败只记日志，不影响消息主链路。

import logging
import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.adapters import apns
from app.models.chat import Conversation
from app.models.profile import Profile
from app.models.user import DeviceToken
from app.ws.hub import hub

logger = logging.getLogger(__name__)

# 通知栏正文截断长度
_MAX_ALERT_BODY_LEN = 100


async def push_new_message(
    db: AsyncSession,
    conversation_id: uuid.UUID,
    sender_id: uuid.UUID,
    content: str,
) -> None:
    """新消息离线推送：对方 Hub 在线则跳过，否则向其全部设备发通知。

    badge = 对方在该会话的累计未读数；title = 发送者昵称。
    """
    conversation = await db.get(Conversation, conversation_id)
    if conversation is None or sender_id not in (
        conversation.user_a_id,
        conversation.user_b_id,
    ):
        return
    other_id = (
        conversation.user_b_id
        if conversation.user_a_id == sender_id
        else conversation.user_a_id
    )
    if hub.is_online(other_id):
        return  # 对方在线，WS 已实时送达

    tokens = list(
        await db.scalars(select(DeviceToken.token).where(DeviceToken.user_id == other_id))
    )
    if not tokens:
        return

    badge = (
        conversation.user_a_unread
        if conversation.user_a_id == other_id
        else conversation.user_b_unread
    )
    sender_profile = await db.scalar(
        select(Profile.nickname).where(Profile.user_id == sender_id)
    )
    title = sender_profile or "斑斑"
    payload = {
        "aps": {
            "alert": {"title": title, "body": content[:_MAX_ALERT_BODY_LEN]},
            "badge": badge,
            "sound": "default",
        },
        "conversation_id": str(conversation_id),
    }

    sender = apns.get_apns_sender()
    for token in tokens:
        try:
            await sender.send(token, payload)
        except Exception as exc:  # noqa: BLE001 — 旁路推送不阻塞消息主链路
            logger.warning("APNs 推送失败 device_token=%s…: %s", token[:12], exc)
