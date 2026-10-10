#  chat.py
#  会话/消息服务：会话列表、消息历史（seq 游标分页）、HTTP 兜底发消息、已读、unmatch
#
#  seq 分配：发送前 FOR UPDATE 锁会话行串行化同会话并发，
#  取 max(seq)+1，uq_messages_conv_seq 唯一约束兜底。
#  unmatch 语义：删除 match 行，conversations / messages 随 FK 级联清除。

import uuid

from fastapi import HTTPException, status
from sqlalchemy import func, nulls_last, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.chat import Conversation, Message
from app.models.matching import Match
from app.models.user import User
from app.schemas.chat import (
    ConversationListOut,
    ConversationOut,
    MessageListOut,
    MessageOut,
    SendMessageIn,
)
from app.services.matching import _project_batch
from app.services.projection import project_user_profile

# 消息历史单页条数
DEFAULT_MESSAGE_PAGE_SIZE = 20


async def list_conversations(db: AsyncSession, user: User) -> ConversationListOut:
    """我的会话列表：最近活跃优先（无消息的会话沉底，按建立时间倒序）。"""
    conversations = list(
        (
            await db.scalars(
                select(Conversation)
                .where(
                    (Conversation.user_a_id == user.id)
                    | (Conversation.user_b_id == user.id)
                )
                .order_by(
                    nulls_last(Conversation.last_message_at.desc()),
                    Conversation.id.desc(),
                )
            )
        ).all()
    )
    if not conversations:
        return ConversationListOut(items=[])

    other_ids = [
        conv.user_b_id if conv.user_a_id == user.id else conv.user_a_id
        for conv in conversations
    ]
    users, profiles, photos_by_user = await _project_batch(db, other_ids)
    items = [
        ConversationOut(
            id=conv.id,
            user=project_user_profile(
                users[other_id], profiles[other_id], photos_by_user.get(other_id, [])
            ),
            last_message_text=conv.last_message_text,
            last_message_at=conv.last_message_at,
            unread_count=(
                conv.user_a_unread if conv.user_a_id == user.id else conv.user_b_unread
            ),
            created_at=conv.created_at,
        )
        for conv, other_id in zip(conversations, other_ids, strict=True)
    ]
    return ConversationListOut(items=items)


async def list_messages(
    db: AsyncSession,
    user: User,
    conversation_id: uuid.UUID,
    cursor: str | None,
    limit: int = DEFAULT_MESSAGE_PAGE_SIZE,
) -> MessageListOut:
    """消息历史：seq 倒序取页（cursor 之前的更早消息），items 以旧→新排序返回。"""
    conversation = await _get_conversation_or_404(db, user, conversation_id)

    stmt = (
        select(Message)
        .where(Message.conversation_id == conversation.id)
        .order_by(Message.seq.desc())
    )
    if cursor:
        cursor_seq = _decode_cursor(cursor)
        stmt = stmt.where(Message.seq < cursor_seq)
    messages = list((await db.scalars(stmt.limit(limit + 1))).all())
    has_more = len(messages) > limit
    messages = messages[:limit]
    messages.reverse()  # DB 倒序取页 → 时间线旧→新展示

    items = [
        MessageOut(
            id=msg.id,
            sender_id=msg.sender_id,
            seq=msg.seq,
            type=msg.type.value,
            content=msg.content,
            created_at=msg.created_at,
        )
        for msg in messages
    ]
    next_cursor = (
        _encode_cursor(messages[0].seq) if has_more and messages else None
    )
    return MessageListOut(items=items, next_cursor=next_cursor)


async def send_message(
    db: AsyncSession, user: User, conversation_id: uuid.UUID, data: SendMessageIn
) -> MessageOut:
    """HTTP 兜底发消息：锁会话行分配 seq，更新摘要与对方未读（WS 主通道 P8 接入）。"""
    # FOR UPDATE 锁会话行：同会话并发发送串行化，保证 seq 严格递增
    conversation = await db.scalar(
        select(Conversation).where(Conversation.id == conversation_id).with_for_update()
    )
    if conversation is None or user.id not in (
        conversation.user_a_id,
        conversation.user_b_id,
    ):
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            {"code": "conversation_not_found", "message": "会话不存在"},
        )

    max_seq = await db.scalar(
        select(func.max(Message.seq)).where(
            Message.conversation_id == conversation.id
        )
    )
    message = Message(
        conversation_id=conversation.id,
        sender_id=user.id,
        seq=(max_seq or 0) + 1,
        content=data.content,
        client_msg_id=data.client_msg_id,
    )
    db.add(message)
    await db.flush()  # 取回服务端生成的 id / created_at

    conversation.last_message_text = data.content
    conversation.last_message_at = message.created_at
    if conversation.user_a_id == user.id:
        conversation.user_b_unread += 1
    else:
        conversation.user_a_unread += 1

    await db.commit()
    return MessageOut(
        id=message.id,
        sender_id=message.sender_id,
        seq=message.seq,
        type=message.type.value,
        content=message.content,
        created_at=message.created_at,
    )


async def mark_read(db: AsyncSession, user: User, conversation_id: uuid.UUID) -> None:
    """清零我的未读计数（进入会话/收到已读回执时调用）。"""
    conversation = await _get_conversation_or_404(db, user, conversation_id)
    if conversation.user_a_id == user.id:
        conversation.user_a_unread = 0
    else:
        conversation.user_b_unread = 0
    await db.commit()


async def delete_conversation(
    db: AsyncSession, user: User, conversation_id: uuid.UUID
) -> None:
    """unmatch：删 match 行，conversations / messages 随级联清除。"""
    conversation = await _get_conversation_or_404(db, user, conversation_id)
    match = await db.get(Match, conversation.match_id)
    if match is not None:
        await db.delete(match)
    await db.commit()


# ── 内部辅助 ──────────────────────────────────────────────────


async def _get_conversation_or_404(
    db: AsyncSession, user: User, conversation_id: uuid.UUID
) -> Conversation:
    """取会话并校验参与方身份（非参与方与不存在一律 404，不泄露存在性）。"""
    conversation = await db.get(Conversation, conversation_id)
    if conversation is None or user.id not in (
        conversation.user_a_id,
        conversation.user_b_id,
    ):
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            {"code": "conversation_not_found", "message": "会话不存在"},
        )
    return conversation


def _encode_cursor(seq: int) -> str:
    return str(seq)


def _decode_cursor(cursor: str) -> int:
    try:
        return int(cursor)
    except ValueError:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            {"code": "invalid_cursor", "message": "游标格式不正确"},
        ) from None
