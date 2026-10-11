#  auth.py
#  认证服务：JWT access 签发/校验 + refresh token（入库 SHA-256 哈希）生命周期 + 手机号登录/注册

import hashlib
import secrets
import uuid
from datetime import UTC, datetime, timedelta

from jose import jwt as jose_jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.user import RefreshToken, User, VerificationLevel


def create_access_token(user_id: uuid.UUID) -> tuple[str, int]:
    """签发 JWT access token。返回 (token, expires_in 秒)。

    payload 带 type=access，防止 refresh/其他用途 token 混用。
    """
    expires_in = settings.jwt_access_expire_minutes * 60
    now = datetime.now(UTC)
    payload = {
        "sub": str(user_id),
        "type": "access",
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(seconds=expires_in)).timestamp()),
    }
    token = jose_jwt.encode(payload, settings.app_secret_key, algorithm=settings.jwt_algorithm)
    return token, expires_in


def _hash_refresh_token(raw: str) -> str:
    """refresh token 入库哈希：高熵随机值用 SHA-256 即可，无需慢哈希"""
    return hashlib.sha256(raw.encode()).hexdigest()


async def issue_refresh_token(db: AsyncSession, user_id: uuid.UUID) -> str:
    """生成 refresh token（48 字节 urlsafe），仅入库哈希。返回原文（只此一次）。"""
    raw = secrets.token_urlsafe(48)
    db.add(RefreshToken(
        user_id=user_id,
        token_hash=_hash_refresh_token(raw),
        expires_at=datetime.now(UTC) + timedelta(days=settings.jwt_refresh_expire_days),
    ))
    await db.flush()
    return raw


async def get_valid_refresh_token(db: AsyncSession, raw: str) -> RefreshToken | None:
    """按原文查 refresh token；未撤销且未过期才返回"""
    row = await db.scalar(
        select(RefreshToken).where(RefreshToken.token_hash == _hash_refresh_token(raw))
    )
    if row is None or row.revoked or row.expires_at <= datetime.now(UTC):
        return None
    return row


async def revoke_refresh_token(db: AsyncSession, raw: str) -> bool:
    """撤销 refresh token（logout 用）。返回是否确实撤销了一条。"""
    row = await get_valid_refresh_token(db, raw)
    if row is None:
        return False
    row.revoked = True
    await db.flush()
    return True


async def login_or_register_by_phone(db: AsyncSession, phone: str) -> tuple[User, bool]:
    """手机号登录/注册：已注册返回现有用户，否则创建（验证等级 phone_verified）。

    返回 (用户, 是否新注册)。
    """
    user = await db.scalar(select(User).where(User.phone == phone))
    if user is not None:
        return user, False

    user = User(phone=phone, verification=VerificationLevel.phone_verified)
    db.add(user)
    await db.flush()  # 拿到 user.id 供后续 refresh token 关联
    return user, True


async def login_or_register_by_wechat(db: AsyncSession, unionid: str) -> tuple[User, bool]:
    """微信登录/注册：unionid 唯一定位；新用户无手机号，verification=pending 待补手机验证。"""
    user = await db.scalar(select(User).where(User.wechat_unionid == unionid))
    if user is not None:
        return user, False

    user = User(wechat_unionid=unionid, verification=VerificationLevel.pending)
    db.add(user)
    await db.flush()
    return user, True


async def login_or_register_by_apple(db: AsyncSession, apple_sub: str) -> tuple[User, bool]:
    """Apple 登录/注册：apple_sub 唯一定位；新用户同微信，verification=pending。"""
    user = await db.scalar(select(User).where(User.apple_sub == apple_sub))
    if user is not None:
        return user, False

    user = User(apple_sub=apple_sub, verification=VerificationLevel.pending)
    db.add(user)
    await db.flush()
    return user, True
