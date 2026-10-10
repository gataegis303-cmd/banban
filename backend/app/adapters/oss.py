#  oss.py
#  照片存储适配器：开发环境本地文件实现，生产替换为阿里云 OSS 预签名直传
#
#  接口契约（两条路径）：
#  - presign_put(...): 返回 (upload_url, oss_key)；客户端 PUT 二进制到 upload_url
#  - save / public_url: 接收端落盘并给出访问 URL
#
#  生产替换点：presign_put 返回 OSS 预签名 URL，接收端变为 OSS 回调/客户端确认，
#  public_url 走 CDN 域名（oss_cdn_domain）。当前 P3 阶段仅本地实现保证闭环。

import uuid
from pathlib import Path

from app.config import settings

_EXT = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}

# 路由层用于 content-type 白名单校验
SUPPORTED_CONTENT_TYPES = tuple(_EXT)

# 本地存储根目录（backend/data/photos，gitignore），main.py 挂载 /static 用
PHOTOS_DIR = Path(__file__).resolve().parents[2] / "data" / "photos"

MAX_PHOTO_BYTES = 10 * 1024 * 1024  # 10MB 上限


def build_oss_key(user_id: uuid.UUID, photo_id: uuid.UUID, content_type: str) -> str:
    """对象键：photos/{user_id}/{photo_id}.{ext}"""
    return f"photos/{user_id}/{photo_id}.{_EXT[content_type]}"


def presign_put(photo_id: uuid.UUID) -> tuple[str, int]:
    """开发环境：上传端点为内部路由；返回 (upload_url, expires_in 秒)"""
    return f"/api/v1/me/photos/{photo_id}/content", 3600


def save(oss_key: str, data: bytes) -> None:
    """本地落盘（生产：OSS SDK put_object 或信任直传）"""
    path = PHOTOS_DIR / oss_key.removeprefix("photos/")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def public_url(oss_key: str) -> str:
    """访问 URL：生产走 CDN 域名；开发环境走本地静态挂载"""
    if settings.oss_cdn_domain:
        return f"https://{settings.oss_cdn_domain}/{oss_key}"
    return f"/static/{oss_key.removeprefix('photos/')}"
