#  user.py
#  认证身份层：users / user_presence / user_verifications / refresh_tokens

import enum
import uuid
from datetime import date, datetime

from sqlalchemy import (
    Boolean,
    Date,
    Enum,
    ForeignKey,
    Integer,
    String,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDPKMixin

# ── PG 原生枚举（存储值为英文标识符，与 API 层一致）──────────────

class VerificationLevel(enum.Enum):
    pending = "pending"
    phone_verified = "phone_verified"
    id_verified = "id_verified"
    face_verified = "face_verified"
    complete = "complete"


class VerificationType(enum.Enum):
    id_card = "id_card"
    face = "face"


class VerificationStepStatus(enum.Enum):
    pending = "pending"
    in_progress = "in_progress"
    passed = "passed"
    failed = "failed"


# ── users 表（认证身份层）─────────────────────────────────────

class User(UUIDPKMixin, TimestampMixin, Base):
    __tablename__ = "users"

    phone: Mapped[str | None] = mapped_column(String(20), unique=True, index=True)
    wechat_unionid: Mapped[str | None] = mapped_column(String(64), unique=True, index=True)
    apple_sub: Mapped[str | None] = mapped_column(String(64), unique=True, index=True)
    verification: Mapped[VerificationLevel] = mapped_column(
        Enum(VerificationLevel, name="verification_level"),
        default=VerificationLevel.pending,
        server_default=VerificationLevel.pending.name,
        nullable=False,
    )
    birthday: Mapped[date | None] = mapped_column(Date)

    # age 由服务层在 birthday 写入时计算（max(18, 周岁)，服务端权威）。
    # 不用生成列：PG 要求表达式 immutable，而年龄计算依赖 current_date；
    # 且 STORED 列会冻结年龄，生日过后不会自动 +1。
    age: Mapped[int | None] = mapped_column(Integer)


# ── user_presence 表（在线态，Redis 为热数据、本表为冷备）────────

class UserPresence(Base):
    __tablename__ = "user_presence"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    is_online: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default=text("false"), nullable=False,
    )
    last_seen_at: Mapped[datetime | None] = mapped_column()


# ── user_verifications 表（实名认证记录）──────────────────────

class UserVerification(UUIDPKMixin, Base):
    __tablename__ = "user_verifications"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    type: Mapped[VerificationType] = mapped_column(
        Enum(VerificationType, name="verification_type"), nullable=False,
    )
    status: Mapped[VerificationStepStatus] = mapped_column(
        Enum(VerificationStepStatus, name="verification_step_status"),
        default=VerificationStepStatus.pending,
        server_default=VerificationStepStatus.pending.name,
        nullable=False,
    )
    result: Mapped[dict | None] = mapped_column(JSONB)


# ── refresh_tokens 表（JWT 刷新令牌，存哈希不存原文）─────────────

class RefreshToken(UUIDPKMixin, Base):
    __tablename__ = "refresh_tokens"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    token_hash: Mapped[str] = mapped_column(String(512), unique=True, index=True, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(nullable=False)
    revoked: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default=text("false"), nullable=False,
    )
