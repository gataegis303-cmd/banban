#  auth.py
#  认证接口的请求/响应模型（Pydantic v2）

import uuid

from pydantic import BaseModel, Field

# 手机号 / 验证码格式约束在 schema 层做（系统边界）
_PHONE = r"^1[3-9]\d{9}$"
_CODE = r"^\d{6}$"


class SmsSendRequest(BaseModel):
    phone: str = Field(pattern=_PHONE, description="中国大陆手机号")


class SmsSendResponse(BaseModel):
    cooldown: int = Field(description="重发冷却秒数")
    # 仅 APP_DEBUG=true 时返回，供开发环境 curl 全链路验收；生产恒为 None
    debug_code: str | None = Field(default=None, description="开发环境调试用验证码")


class SmsVerifyRequest(BaseModel):
    phone: str = Field(pattern=_PHONE)
    code: str = Field(pattern=_CODE, description="6 位数字验证码")


class UserInfo(BaseModel):
    id: uuid.UUID
    phone: str | None
    verification: str
    has_profile: bool


class TokenPairResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int = Field(description="access 有效期（秒）")
    refresh_token: str
    is_new_user: bool
    user: UserInfo


class RefreshRequest(BaseModel):
    refresh_token: str = Field(min_length=32)


class WechatLoginRequest(BaseModel):
    # 微信 App 授权 SDK 回传的 code；开发降级模式为 dev:{unionid}
    code: str = Field(min_length=1, max_length=128)


class AppleLoginRequest(BaseModel):
    # ASAuthorizationAppleIDCredential.identityToken（RS256 JWT）
    identity_token: str = Field(min_length=1, max_length=4096)
    # 客户端生成的原值 nonce（非哈希），用于与 token 内 sha256(nonce) 比对防重放
    nonce: str | None = Field(default=None, min_length=8, max_length=128)


class RefreshResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int


class LogoutRequest(BaseModel):
    refresh_token: str = Field(min_length=32)


class OkResponse(BaseModel):
    ok: bool = True
