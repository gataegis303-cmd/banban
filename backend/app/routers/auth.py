#  auth.py
#  认证路由：短信发送/验证登录 + 微信/Apple OAuth 登录 + refresh 换新 + logout 撤销

from fastapi import APIRouter, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.adapters import apple_auth, wechat_oauth
from app.config import settings
from app.deps import DBSession, redis_client
from app.models.profile import Profile
from app.models.user import User
from app.schemas.auth import (
    AppleLoginRequest,
    LogoutRequest,
    OkResponse,
    RefreshRequest,
    RefreshResponse,
    SmsSendRequest,
    SmsSendResponse,
    SmsVerifyRequest,
    TokenPairResponse,
    UserInfo,
    WechatLoginRequest,
)
from app.services import auth as auth_service
from app.services import sms as sms_service

router = APIRouter(prefix="/auth", tags=["auth"])


async def _build_token_pair(db: AsyncSession, user: User, is_new_user: bool) -> TokenPairResponse:
    """签发令牌对 + 组装登录响应（短信/微信/Apple 三种登录共用）"""
    access_token, expires_in = auth_service.create_access_token(user.id)
    refresh_token = await auth_service.issue_refresh_token(db, user.id)
    has_profile = await db.scalar(
        select(Profile.user_id).where(Profile.user_id == user.id)
    ) is not None
    return TokenPairResponse(
        access_token=access_token,
        expires_in=expires_in,
        refresh_token=refresh_token,
        is_new_user=is_new_user,
        user=UserInfo(
            id=user.id,
            phone=user.phone,
            verification=user.verification.value,
            has_profile=has_profile,
        ),
    )


@router.post("/sms/send", response_model=SmsSendResponse)
async def send_sms_code(body: SmsSendRequest, request: Request) -> SmsSendResponse:
    """发送短信验证码（限流：60s 间隔 / 手机号日上限 / IP 日上限）"""
    phone = sms_service.validate_phone(body.phone)
    ip = sms_service.client_ip(request)
    cooldown = await sms_service.send_code(phone, ip)

    debug_code = None
    if settings.app_debug:
        # 开发闭环：响应里带出验证码（生产 APP_DEBUG=false 恒为 None）
        debug_code = await redis_client.get(f"banban:sms:code:{phone}")
    return SmsSendResponse(cooldown=cooldown, debug_code=debug_code)


@router.post("/sms/verify", response_model=TokenPairResponse)
async def verify_sms_code(body: SmsVerifyRequest, db: DBSession) -> TokenPairResponse:
    """验证码校验 → 登录/注册 → 签发 access + refresh"""
    phone = sms_service.validate_phone(body.phone)
    await sms_service.verify_code(phone, body.code)

    user, is_new_user = await auth_service.login_or_register_by_phone(db, phone)
    response = await _build_token_pair(db, user, is_new_user)
    await db.commit()
    return response


@router.post("/wechat/login", response_model=TokenPairResponse)
async def wechat_login(body: WechatLoginRequest, db: DBSession) -> TokenPairResponse:
    """微信授权 code 换 unionid → 登录/注册（无手机号，verification=pending）"""
    try:
        unionid = await wechat_oauth.exchange_code_for_unionid(body.code)
    except wechat_oauth.WechatAuthError as exc:
        raise HTTPException(
            status_code=exc.status_code,
            detail={"code": "wechat_auth_failed", "message": str(exc)},
        ) from exc

    user, is_new_user = await auth_service.login_or_register_by_wechat(db, unionid)
    response = await _build_token_pair(db, user, is_new_user)
    await db.commit()
    return response


@router.post("/apple/login", response_model=TokenPairResponse)
async def apple_login(body: AppleLoginRequest, db: DBSession) -> TokenPairResponse:
    """Apple identity_token 校验 → sub 登录/注册（无手机号，verification=pending）"""
    try:
        apple_sub = await apple_auth.verify_identity_token(body.identity_token, body.nonce)
    except apple_auth.AppleAuthError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_apple_token", "message": str(exc)},
        ) from exc

    user, is_new_user = await auth_service.login_or_register_by_apple(db, apple_sub)
    response = await _build_token_pair(db, user, is_new_user)
    await db.commit()
    return response


@router.post("/refresh", response_model=RefreshResponse)
async def refresh_access_token(body: RefreshRequest, db: DBSession) -> RefreshResponse:
    """refresh token 换新 access（不轮换 refresh；撤销只能通过 logout）"""
    row = await auth_service.get_valid_refresh_token(db, body.refresh_token)
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"code": "invalid_refresh_token", "message": "刷新令牌无效或已过期，请重新登录"},
        )
    access_token, expires_in = auth_service.create_access_token(row.user_id)
    await db.commit()  # 事务内只有读，commit 释放连接
    return RefreshResponse(access_token=access_token, expires_in=expires_in)


@router.post("/logout", response_model=OkResponse)
async def logout(body: LogoutRequest, db: DBSession) -> OkResponse:
    """撤销 refresh token（access 自然过期，15 分钟内失效）"""
    await auth_service.revoke_refresh_token(db, body.refresh_token)
    await db.commit()
    return OkResponse(ok=True)
