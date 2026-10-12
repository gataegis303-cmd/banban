#  apns.py
#  APNs 推送适配器：JWT（ES256）客户端令牌 + HTTP/2 推送请求
#
#  配置齐全（team_id / key_id / .p8 私钥）走真实 APNs；
#  任一缺失或私钥读取失败时降级 DevMock（推送内容打日志），聊天主链路不受影响。

import logging
import time
from pathlib import Path

import httpx
from cryptography.hazmat.primitives.serialization import load_pem_private_key
from jose import jwt as jose_jwt

from app.config import settings

logger = logging.getLogger(__name__)

_SANDBOX_HOST = "api.sandbox.push.apple.com"
_PROD_HOST = "api.push.apple.com"
# provider token 有效期上限 1h，留余量提前 5 分钟刷新
_PROVIDER_TOKEN_TTL_SECONDS = 55 * 60


class APNSError(Exception):
    """APNs 推送失败（调用方仅记日志，不影响消息主链路）"""


class DevMockAPNS:
    """未配置证书时的降级实现：推送内容打日志，本地可验证完整链路"""

    async def send(self, device_token: str, payload: dict) -> None:
        logger.info(
            "[APNs DevMock] 离线推送 device_token=%s… payload=%s",
            device_token[:12],
            payload,
        )


class RealAPNS:
    """真实 APNs 客户端（token-based 认证，HTTP/2）"""

    def __init__(self, private_key, key_id: str, team_id: str, host: str) -> None:
        self._private_key = private_key
        self._key_id = key_id
        self._team_id = team_id
        self._host = host
        self._token: tuple[str, float] | None = None  # (JWT, 签发时刻)
        self._client = httpx.AsyncClient(http2=True, timeout=10)

    def _provider_token(self) -> str:
        now = time.monotonic()
        if self._token is None or now - self._token[1] >= _PROVIDER_TOKEN_TTL_SECONDS:
            token = jose_jwt.encode(
                {"iss": self._team_id, "iat": int(time.time())},
                self._private_key,
                algorithm="ES256",
                headers={"kid": self._key_id, "alg": "ES256"},
            )
            self._token = (token, now)
        return self._token[0]

    async def send(self, device_token: str, payload: dict) -> None:
        try:
            response = await self._client.post(
                f"https://{self._host}/3/device/{device_token}",
                json=payload,
                headers={
                    "authorization": f"bearer {self._provider_token()}",
                    "apns-topic": settings.apple_bundle_id,
                    "apns-push-type": "alert",
                    "apns-priority": "10",
                },
            )
        except httpx.HTTPError as exc:
            raise APNSError(f"APNs 请求失败: {exc}") from exc
        if response.status_code != 200:
            raise APNSError(f"APNs 响应 {response.status_code}: {response.text}")


_sender = None  # 懒初始化单例


def get_apns_sender() -> DevMockAPNS | RealAPNS:
    global _sender
    if _sender is None:
        _sender = _build_sender()
    return _sender


def _build_sender() -> DevMockAPNS | RealAPNS:
    if not (
        settings.apns_team_id
        and settings.apns_key_id
        and settings.apns_private_key_path
    ):
        logger.warning("APNs 未配置（team_id/key_id/私钥缺失），降级 DevMock 日志推送")
        return DevMockAPNS()
    try:
        pem = Path(settings.apns_private_key_path).read_bytes()
        private_key = load_pem_private_key(pem, password=None)
    except (OSError, ValueError) as exc:
        # 私钥不可读：降级 DevMock，推送失败不阻塞消息主链路
        logger.error("APNs 私钥读取失败，降级 DevMock: %s", exc)
        return DevMockAPNS()
    host = _SANDBOX_HOST if settings.apns_use_sandbox else _PROD_HOST
    logger.info("APNs 已启用（host=%s, sandbox=%s）", host, settings.apns_use_sandbox)
    return RealAPNS(private_key, settings.apns_key_id, settings.apns_team_id, host)
