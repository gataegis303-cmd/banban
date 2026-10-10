#  chat.py
#  会话/消息 DTO：会话列表、消息历史（游标分页）、发送消息
#
#  投影约定：user 字段直接承载 projection_service.project_user_profile 的输出
#  （与 matching.py 的 MatchOut 一致）

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


class ConversationOut(BaseModel):
    """单条会话：对方投影 + 摘要 + 我的未读数"""

    id: uuid.UUID
    user: dict[str, Any]
    last_message_text: str | None
    last_message_at: datetime | None
    unread_count: int
    created_at: datetime


class ConversationListOut(BaseModel):
    items: list[ConversationOut]


class MessageOut(BaseModel):
    """单条消息：id 为服务端 public_id（iOS ChatMessage.id）"""

    id: uuid.UUID
    sender_id: uuid.UUID
    seq: int
    type: str
    content: str
    created_at: datetime


class MessageListOut(BaseModel):
    """游标分页（按 seq 倒序取更早消息，items 以旧→新排序返回）：

    next_cursor 非 None 时带上继续拉更早的历史；None 表示已到最早一条
    """

    items: list[MessageOut]
    next_cursor: str | None = None


class SendMessageIn(BaseModel):
    """HTTP 兜底发消息（WS 为主通道，P8 接入）；client_msg_id 供乐观更新对齐"""

    content: str = Field(min_length=1, max_length=2000)
    client_msg_id: str | None = Field(default=None, max_length=64)
