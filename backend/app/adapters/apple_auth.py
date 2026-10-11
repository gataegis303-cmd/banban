#  apple_auth.py
#  Apple Sign-In 适配器：拉取 JWKS 公钥并校验 identity_token（RS256 + iss/aud/exp/nonce）

import hashlib
import time

import httpx
from jose import jwk as jose_jwk
from jose import jwt as jose_jwt

from app.config import settings

APPLE_ISSUER = "https://appleid.apple.com"
_JWKS_CACHE_TTL_SECONDS = 24 * 3600  # Apple 轮换密钥频率极低，缓存 24h，拉取失败时旧缓存兜底

_jwks_cache: tuple[list[dict], float] | None = None  # (JWKS keys, 缓存时间戳)


class AppleAuthError(Exception):
    """identity_token 校验失败（映射 401 交给路由层）"""


async def _fetch_jwks() -> list[dict]:
    """拉取 Apple JWKS；带缓存，网络失败时用旧缓存兜底"""
    global _jwks_cache
    now = time.monotonic()
    if _jwks_cache is not None and now - _jwks_cache[1] < _JWKS_CACHE_TTL_SECONDS:
        return _jwks_cache[0]

    async with httpx.AsyncClient(timeout=5) as client:
        response = await client.get(settings.apple_jwks_url)
        response.raise_for_status()
    keys = response.json().get("keys", [])
    if not keys:
        raise AppleAuthError("Apple JWKS 为空")
    _jwks_cache = (keys, now)
    return keys


async def verify_identity_token(token: str, nonce: str | None) -> str:
    """校验 Apple identity_token，返回 sub（即 apple_sub）。

    - RS256 签名（JWKS 按 kid 路由公钥）
    - iss=https://appleid.apple.com、aud=本 App bundle id、exp 自动校验
    - 客户端传 nonce 时，token 内 nonce 必须等于 sha256(客户端 nonce)（防重放）
    """
    try:
        header = jose_jwt.get_unverified_header(token)
    except jose_jwt.JWTError as exc:
        raise AppleAuthError("token 格式无效") from exc
    kid = header.get("kid")
    alg = header.get("alg")
    if alg != "RS256":
        raise AppleAuthError("签名算法非 RS256")

    keys = await _fetch_jwks()
    key_dict = next((k for k in keys if k.get("kid") == kid), None)
    if key_dict is None:
        # kid 未命中：强制刷新一次缓存再试（Apple 刚轮换密钥的场景）
        global _jwks_cache
        _jwks_cache = None
        keys = await _fetch_jwks()
        key_dict = next((k for k in keys if k.get("kid") == kid), None)
        if key_dict is None:
            raise AppleAuthError("未找到匹配的 Apple 公钥")

    public_key = jose_jwk.construct(key_dict, algorithm="RS256")
    try:
        payload = jose_jwt.decode(
            token,
            public_key,
            algorithms=["RS256"],
            audience=settings.apple_bundle_id,
            issuer=APPLE_ISSUER,
        )
    except jose_jwt.ExpiredSignatureError as exc:
        raise AppleAuthError("token 已过期") from exc
    except jose_jwt.JWTError as exc:
        raise AppleAuthError("token 校验失败（签名/受众/签发者不符）") from exc

    if nonce is not None and payload.get("nonce") != hashlib.sha256(nonce.encode()).hexdigest():
        raise AppleAuthError("nonce 不匹配")

    sub = payload.get("sub")
    if not sub or len(sub) > 64:
        raise AppleAuthError("token 缺少有效 sub")
    return sub
