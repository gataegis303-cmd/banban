#  matching.py
#  推荐/匹配层：recommendations / likes / matches

import enum
import uuid
from datetime import date

from sqlalchemy import (
    CheckConstraint,
    Date,
    Enum,
    Float,
    ForeignKey,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDPKMixin


class LikeDirection(enum.Enum):
    like = "like"
    skip = "skip"
    block = "block"


class RecommendationStatus(enum.Enum):
    pending = "pending"
    shown = "shown"
    liked = "liked"
    skipped = "skipped"
    blocked = "blocked"


# ── recommendations 表（推荐流水，同一天每对用户一条）─────────────

class Recommendation(UUIDPKMixin, Base):
    __tablename__ = "recommendations"
    __table_args__ = (
        UniqueConstraint("user_id", "target_id", name="uq_recommendations_user_target"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    target_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    batch_date: Mapped[date] = mapped_column(Date, index=True, nullable=False)
    score: Mapped[float] = mapped_column(
        Float, default=0.0, server_default=text("0.0"), nullable=False,
    )
    status: Mapped[RecommendationStatus] = mapped_column(
        Enum(RecommendationStatus, name="recommendation_status"),
        default=RecommendationStatus.pending,
        server_default=RecommendationStatus.pending.name,
        nullable=False,
    )


# ── likes 表（liker → likee，direction=like/skip/block）──────────

class Like(UUIDPKMixin, Base):
    __tablename__ = "likes"
    __table_args__ = (
        UniqueConstraint("liker_id", "likee_id", name="uq_likes_liker_likee"),
    )

    liker_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    likee_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    direction: Mapped[LikeDirection] = mapped_column(
        Enum(LikeDirection, name="like_direction"), nullable=False,
    )


# ── matches 表（双向 like 触发，user_a_id < user_b_id 保证唯一）───

class Match(UUIDPKMixin, Base):
    __tablename__ = "matches"
    __table_args__ = (
        UniqueConstraint("user_a_id", "user_b_id", name="uq_matches_pair"),
        CheckConstraint("user_a_id < user_b_id", name="ck_matches_user_order"),
    )

    user_a_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    user_b_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
