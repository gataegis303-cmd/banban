#  wechat_oauth.py
#  微信 OAuth 适配器：code → access_token/unionid（移动 App 授权流程）
#
#  开发降级：APP_DEBUG=true 且未配置 WECHAT_APP_SECRET 时，code 形如 `dev:{unionid}`
#  直接放行（对齐短信 DevMock 思路），供无微信开放平台资质时的 curl 闭环验收。

import httpx

from app.config import settings

_WECHAT_TOKEN_URL = "https://api.weixin.qq.com/sns/oauth2/access_token"

# 微信 errcode → 客户端可见错误（invalid code 属用户可重试，其余归为服务不可用）
_CODE_INVALID_ERRCODES = {40029, 42003}


class WechatAuthError(Exception):
    """code 换 unionid 失败；status_code 供路由层映射 HTTP 状态"""

    def __init__(self, message: str, status_code: int = 401):
        super().__init__(message)
        self.status_code = status_code


async def exchange_code_for_unionid(code: str) -> str:
    """微信授权 code 换 unionid（要求开放平台账号已绑定移动应用）。

    未绑定开放平台时授权响应不含 unionid，视为配置错误（500）。
    """
    # 开发降级：dev:<unionid> 直通（仅调试模式且未配置密钥时生效）
    if not settings.wechat_app_secret:
        if settings.app_debug and code.startswith("dev:"):
            unionid = code.removeprefix("dev:")
            if unionid.isalnum() and 5 <= len(unionid) <= 63:
                return unionid
            raise WechatAuthError("开发模式 code 格式应为 dev:{unionid}（字母数字，5-63 位）")
        raise WechatAuthError("微信登录未配置", status_code=503)

    try:
        async with httpx.AsyncClient(timeout=5) as client:
            response = await client.get(_WECHAT_TOKEN_URL, params={
                "appid": settings.wechat_app_id,
                "secret": settings.wechat_app_secret,
                "code": code,
                "grant_type": "authorization_code",
            })
            response.raise_for_status()
    except httpx.HTTPError as exc:
        raise WechatAuthError("微信服务不可用，请稍后重试", status_code=503) from exc

    data = response.json()
    errcode = data.get("errcode")
    if errcode is not None:
        if errcode in _CODE_INVALID_ERRCODES:
            raise WechatAuthError("微信授权已失效，请重新发起登录")
        raise WechatAuthError("微信服务异常，请稍后重试", status_code=502)

    unionid = data.get("unionid")
    if not unionid:
        # 应用未绑定微信开放平台账号：移动授权不返回 unionid
        raise WechatAuthError("微信登录配置异常（未绑定开放平台）", status_code=500)
    return unionid
