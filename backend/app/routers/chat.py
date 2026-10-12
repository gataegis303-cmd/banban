#  chat.py
#  会话路由：会话列表、消息历史（seq 游标分页）、HTTP 兜底发消息、已读、unmatch

import uuid

from fastapi import APIRouter, Query, Response

from app.deps import CurrentUser, DBSession
from app.schemas.chat import (
    ConversationListOut,
    MessageListOut,
    MessageOut,
    SendMessageIn,
)
from app.services import chat, push

router = APIRouter(prefix="/conversations", tags=["conversations"])


@router.get("", response_model=ConversationListOut)
async def list_conversations(user: CurrentUser, db: DBSession) -> ConversationListOut:
    return await chat.list_conversations(db, user)


@router.get("/{conversation_id}/messages", response_model=MessageListOut)
async def list_messages(
    conversation_id: uuid.UUID,
    user: CurrentUser,
    db: DBSession,
    cursor: str | None = None,
    limit: int = Query(default=chat.DEFAULT_MESSAGE_PAGE_SIZE, ge=1, le=50),
) -> MessageListOut:
    """cursor 为上一页最早一条消息的 seq，None 表示取完历史"""
    return await chat.list_messages(db, user, conversation_id, cursor, limit)


@router.post("/{conversation_id}/messages", response_model=MessageOut, status_code=201)
async def send_message(
    conversation_id: uuid.UUID,
    data: SendMessageIn,
    user: CurrentUser,
    db: DBSession,
) -> MessageOut:
    """HTTP 兜底发消息（WS 为主通道）"""
    message = await chat.send_message(db, user.id, conversation_id, data)
    # 对方离线时 APNs 离线推送（服务内先判在线态，在线则跳过）
    await push.push_new_message(db, conversation_id, user.id, message.content)
    return message


@router.post("/{conversation_id}/read", status_code=204)
async def mark_read(
    conversation_id: uuid.UUID, user: CurrentUser, db: DBSession
) -> Response:
    await chat.mark_read(db, user.id, conversation_id)
    return Response(status_code=204)


@router.delete("/{conversation_id}", status_code=204)
async def delete_conversation(
    conversation_id: uuid.UUID, user: CurrentUser, db: DBSession
) -> Response:
    """unmatch：删除匹配并级联清除会话与消息"""
    await chat.delete_conversation(db, user, conversation_id)
    return Response(status_code=204)
