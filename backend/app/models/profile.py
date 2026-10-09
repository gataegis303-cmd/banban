#  profile.py
#  富资料层：profiles / user_photos / user_filters
#
#  设计原则：
#  - profiles 与 users 1:1，对齐 iOS MyProfile 全字段
#  - 枚举字段存中文 rawValue（对齐 Enums.swift），免翻译层
#  - 集合字段用 JSONB（pets/noAccept/transportCounts 等）
#  - birthday/age 只存 users（服务端权威派生），profiles 不冗余

import uuid

from sqlalchemy import (
    Boolean,
    ForeignKey,
    SmallInteger,
    String,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDPKMixin


class Profile(TimestampMixin, Base):
    __tablename__ = "profiles"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )

    # ── 基本信息 ──────────────────────────────────────────────
    nickname: Mapped[str] = mapped_column(
        String(50), default="", server_default=text("''"), nullable=False,
    )
    gender: Mapped[str | None] = mapped_column(String(10))            # 男/女
    city: Mapped[str] = mapped_column(
        String(50), default="", server_default=text("''"), nullable=False,
    )
    height: Mapped[str] = mapped_column(
        String(20), default="", server_default=text("''"), nullable=False,
    )
    education: Mapped[str] = mapped_column(
        String(50), default="", server_default=text("''"), nullable=False,
    )
    occupation: Mapped[str] = mapped_column(
        String(100), default="", server_default=text("''"), nullable=False,
    )
    income: Mapped[str] = mapped_column(
        String(50), default="", server_default=text("''"), nullable=False,
    )
    marriage: Mapped[str | None] = mapped_column(String(10))          # 未婚/离异
    # 无子女/有子女随我/有子女不随我
    children: Mapped[str | None] = mapped_column(String(20))
    living_situation: Mapped[str] = mapped_column(
        String(100), default="", server_default=text("''"), nullable=False,
    )

    # ── 生活方式 ──────────────────────────────────────────────
    pets: Mapped[list] = mapped_column(
        JSONB, default=list, server_default=text("'[]'::jsonb"), nullable=False,
    )
    sleep: Mapped[str | None] = mapped_column(String(20))             # 早睡早起/晚睡晚起/不规律
    smoking: Mapped[str | None] = mapped_column(String(10))           # 是/否/偶尔
    drinking: Mapped[str | None] = mapped_column(String(10))          # 是/否/偶尔

    # ── 匹配意图 ──────────────────────────────────────────────
    match_type: Mapped[str] = mapped_column(
        String(50), default="", server_default=text("''"), nullable=False,
    )
    direction: Mapped[str | None] = mapped_column(String(20))         # 领证结婚/协议搭伴/自由式
    partner_status: Mapped[str | None] = mapped_column(String(20))    # 未婚无伴侣/有同性伴侣/离异
    seeking: Mapped[str | None] = mapped_column(String(10))           # 异性/同性/不限
    living_mode: Mapped[str | None] = mapped_column(String(20))       # 同居同房/同居分房/同城分居
    child_intent: Mapped[str | None] = mapped_column(String(20))      # 是/否/领养/不确定
    # 保持独立社交/共同朋友圈/可商量
    social_boundary: Mapped[str | None] = mapped_column(String(20))
    # 与其同住/同城居住/脱离关系/父母双亡
    parent_relation: Mapped[str | None] = mapped_column(String(20))
    finance_trial: Mapped[str | None] = mapped_column(String(20))     # AA/按收入比例/一事一议
    # AA/按收入比例/一事一议/共同财富
    finance_formal: Mapped[str | None] = mapped_column(String(20))
    intended_city: Mapped[str] = mapped_column(
        String(50), default="", server_default=text("''"), nullable=False,
    )

    # ── 标签 / 雷区 ───────────────────────────────────────────
    no_accept: Mapped[list] = mapped_column(
        JSONB, default=list, server_default=text("'[]'::jsonb"), nullable=False,
    )

    # ── 交通 ──────────────────────────────────────────────────
    transport_none: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default=text("false"), nullable=False,
    )
    transport_tools: Mapped[list] = mapped_column(
        JSONB, default=list, server_default=text("'[]'::jsonb"), nullable=False,
    )
    transport_counts: Mapped[dict] = mapped_column(
        JSONB, default=dict, server_default=text("'{}'::jsonb"), nullable=False,
    )
    taxi_monthly_quota: Mapped[str] = mapped_column(
        String(50), default="", server_default=text("''"), nullable=False,
    )

    # ── 住房 ──────────────────────────────────────────────────
    housing_situation: Mapped[str | None] = mapped_column(String(50))
    spare_rooms: Mapped[int] = mapped_column(
        SmallInteger, default=0, server_default=text("0"), nullable=False,
    )
    housing_conditions: Mapped[list] = mapped_column(
        JSONB, default=list, server_default=text("'[]'::jsonb"), nullable=False,
    )

    # ── 资源 / 其他标签 ───────────────────────────────────────
    resources: Mapped[list] = mapped_column(
        JSONB, default=list, server_default=text("'[]'::jsonb"), nullable=False,
    )
    other_tags: Mapped[list] = mapped_column(
        JSONB, default=list, server_default=text("'[]'::jsonb"), nullable=False,
    )

    # ── 自述 ──────────────────────────────────────────────────
    headline: Mapped[str] = mapped_column(
        String(200), default="", server_default=text("''"), nullable=False,
    )
    about_me: Mapped[str] = mapped_column(
        Text, default="", server_default=text("''"), nullable=False,
    )

    # ── 状态 ──────────────────────────────────────────────────
    start_time: Mapped[str] = mapped_column(
        String(50), default="尽快", server_default=text("'尽快'"), nullable=False,
    )
    completion: Mapped[int] = mapped_column(
        SmallInteger, default=0, server_default=text("0"), nullable=False,
    )
    profile_submitted: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default=text("false"), nullable=False,
    )


# ── user_photos 表（上限 6，sort_order 0-5）───────────────────

class UserPhoto(UUIDPKMixin, Base):
    __tablename__ = "user_photos"
    __table_args__ = (
        UniqueConstraint("user_id", "sort_order", name="uq_user_photos_user_sort"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False,
    )
    sort_order: Mapped[int] = mapped_column(SmallInteger, nullable=False)  # 0-5
    url: Mapped[str] = mapped_column(String(500), nullable=False)
    oss_key: Mapped[str] = mapped_column(String(500), nullable=False)


# ── user_filters 表（筛选条件，对齐 FilterState）───────────────

class UserFilter(TimestampMixin, Base):
    __tablename__ = "user_filters"

    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"),
        primary_key=True,
    )
    city: Mapped[str | None] = mapped_column(String(50))
    age_min: Mapped[int] = mapped_column(
        SmallInteger, default=20, server_default=text("20"), nullable=False,
    )
    age_max: Mapped[int] = mapped_column(
        SmallInteger, default=40, server_default=text("40"), nullable=False,
    )
    direction: Mapped[str | None] = mapped_column(String(20))
    partner_status: Mapped[str | None] = mapped_column(String(20))
    seeking: Mapped[str | None] = mapped_column(String(10))
    living_mode: Mapped[str | None] = mapped_column(String(20))
    parent_relation: Mapped[str | None] = mapped_column(String(20))
    finance_trial: Mapped[str | None] = mapped_column(String(20))
    finance_formal: Mapped[str | None] = mapped_column(String(20))
    child_intent: Mapped[str | None] = mapped_column(String(20))
    pets: Mapped[list] = mapped_column(
        JSONB, default=list, server_default=text("'[]'::jsonb"), nullable=False,
    )
    no_accept: Mapped[list] = mapped_column(
        JSONB, default=list, server_default=text("'[]'::jsonb"), nullable=False,
    )
