#  chat.py
#  会话/消息层：conversations / messages / reports

import enum
import uuid
from datetime import datetime

from sqlalchemy import (
    BigInteger,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDPKMixin


class MessageType(enum.Enum):
    text = "text"
    system = "system"
    image = "image"


class ReportStatus(enum.Enum):
    pending = "pending"
    reviewed = "reviewed"
    actioned = "actioned"
    dismissed = "dismissed"


# ── conversations 表（1 match 1 conversation，双方独立未读计数）──

class Conversation(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "conversations"

    match_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("matches.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    user_a_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    user_b_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    user_a_unread: Mapped[int] = mapped_column(
        Integer, default=0, server_default=text("0"), nullable=False,
    )
    user_b_unread: Mapped[int] = mapped_column(
        Integer, default=0, server_default=text("0"), nullable=False,
    )
    last_message_text: Mapped[str | None] = mapped_column(Text)
    last_message_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


# ── messages 表（seq 会话内严格递增，游标分页依据）────────────────

class Message(UUIDPKMixin, Base):
    __tablename__ = "messages"
    __table_args__ = (
        UniqueConstraint("conversation_id", "seq", name="uq_messages_conv_seq"),
    )

    conversation_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("conversations.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    sender_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False,
    )
    seq: Mapped[int] = mapped_column(BigInteger, nullable=False)
    type: Mapped[MessageType] = mapped_column(
        Enum(MessageType, name="message_type"),
        default=MessageType.text,
        server_default=MessageType.text.name,
        nullable=False,
    )
    content: Mapped[str] = mapped_column(
        Text, default="", server_default=text("''"), nullable=False,
    )
    client_msg_id: Mapped[str | None] = mapped_column(String(64))  # 乐观更新临时 id


# ── reports 表（举报）──────────────────────────────────────────

class Report(UUIDPKMixin, Base):
    __tablename__ = "reports"

    reporter_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    reported_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    reason: Mapped[str] = mapped_column(String(200), nullable=False)
    details: Mapped[dict | None] = mapped_column(JSONB)
    status: Mapped[ReportStatus] = mapped_column(
        Enum(ReportStatus, name="report_status"),
        default=ReportStatus.pending,
        server_default=ReportStatus.pending.name,
        nullable=False,
    )
