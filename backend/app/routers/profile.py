#  profile.py
#  资料路由：我的资料 CRUD（增量合并）+ 向导提交 + 照片登记/上传/删除/重排

import uuid

from fastapi import APIRouter, HTTPException, Query, Request, Response, status
from sqlalchemy import delete, func, select
from sqlalchemy.dialects.postgresql import insert as pg_insert

from app.adapters import oss
from app.deps import CurrentUser, DBSession
from app.models.profile import UserPhoto
from app.models.user import DeviceToken
from app.schemas.profile import (
    DeviceTokenIn,
    PhotoOut,
    PhotoReorderRequest,
    PhotoUploadRequest,
    PhotoUploadResponse,
    ProfileOut,
    ProfileSubmittedResponse,
    ProfileUpdate,
)
from app.services import profile as profile_service

router = APIRouter(prefix="/me", tags=["profile"])


async def _respond(db, user, profile) -> ProfileOut:
    """统一组装响应；完成度读取时重算（照片增删等旁路改动由此收敛）"""
    photo_count = await profile_service.count_photos(db, user.id)
    profile.completion = profile_service.compute_completion(profile, photo_count)
    photos = await profile_service.list_photos(db, user.id)
    return profile_service.to_profile_out(profile, user, photos)


@router.get("/profile", response_model=ProfileOut)
async def get_profile(user: CurrentUser, db: DBSession) -> ProfileOut:
    profile = await profile_service.get_or_create_profile(db, user.id)
    await db.commit()  # 惰性建行落库
    return await _respond(db, user, profile)


@router.put("/profile", response_model=ProfileOut)
async def update_profile(
    body: ProfileUpdate, user: CurrentUser, db: DBSession
) -> ProfileOut:
    """增量合并语义（schemas/profile.py 文件头），返回合并后的完整资料"""
    profile = await profile_service.get_or_create_profile(db, user.id)
    await profile_service.apply_update(db, user, profile, body)
    await db.commit()
    return await _respond(db, user, profile)


@router.post("/profile/submit", response_model=ProfileSubmittedResponse)
async def submit_profile(user: CurrentUser, db: DBSession) -> ProfileSubmittedResponse:
    """注册向导完成标记。必填校验由 iOS 向导 UI 保证，服务端后续按产品规格补。"""
    profile = await profile_service.get_or_create_profile(db, user.id)
    photo_count = await profile_service.count_photos(db, user.id)
    profile.completion = profile_service.compute_completion(profile, photo_count)
    profile.profile_submitted = True
    await db.commit()
    return ProfileSubmittedResponse(profile_submitted=True, completion=profile.completion)


# ── 照片（上限 6，sort_order 0-5）──────────────────────────────


@router.post("/photos", response_model=PhotoUploadResponse)
async def create_photo(
    body: PhotoUploadRequest, user: CurrentUser, db: DBSession
) -> PhotoUploadResponse:
    """登记照片位并返回上传地址（开发环境为本地端点，生产为 OSS 预签名 URL）"""
    existing = await profile_service.list_photos(db, user.id)
    if len(existing) >= profile_service.PHOTO_LIMIT:
        raise HTTPException(
            status.HTTP_409_CONFLICT, {"code": "photo_limit", "message": "照片最多 6 张"}
        )
    if any(p.sort_order == body.order for p in existing):
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            {"code": "photo_order_taken", "message": "该展示位已有照片，请先删除或重排"},
        )

    photo_id = uuid.uuid4()
    oss_key = oss.build_oss_key(user.id, photo_id, body.content_type)
    # 显式指定主键：先有 photo_id 才能拼 oss_key，不能依赖 DB server_default
    db.add(
        UserPhoto(
            id=photo_id, user_id=user.id, sort_order=body.order, url="", oss_key=oss_key
        )
    )
    await db.commit()

    upload_url, expires_in = oss.presign_put(photo_id)
    return PhotoUploadResponse(photo_id=photo_id, upload_url=upload_url, oss_key=oss_key)


@router.put("/photos/{photo_id}/content")
async def upload_photo_content(
    photo_id: uuid.UUID, request: Request, user: CurrentUser, db: DBSession
) -> Response:
    """开发环境上传端点（生产由 OSS 直传替代）：校验归属与类型/大小后落盘并回填 url"""
    photo = await db.get(UserPhoto, photo_id)
    if photo is None or photo.user_id != user.id:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, {"code": "photo_not_found", "message": "照片不存在"}
        )

    content_type = request.headers.get("content-type", "").split(";")[0]
    if content_type not in oss.SUPPORTED_CONTENT_TYPES:
        raise HTTPException(
            status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            {"code": "photo_bad_type", "message": "仅支持 jpeg/png/webp"},
        )

    data = await request.body()
    if not data:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_CONTENT, {"code": "photo_empty", "message": "文件为空"}
        )
    if len(data) > oss.MAX_PHOTO_BYTES:
        raise HTTPException(
            status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            {"code": "photo_too_large", "message": "文件超过 10MB"},
        )

    oss.save(photo.oss_key, data)
    photo.url = oss.public_url(photo.oss_key)
    await db.commit()
    return Response(status_code=status.HTTP_200_OK, content=b"")


@router.delete("/photos/{order}", response_model=PhotoOut)
async def delete_photo(order: int, user: CurrentUser, db: DBSession) -> PhotoOut:
    if not 0 <= order <= 5:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            {"code": "invalid_order", "message": "展示位取值 0-5"},
        )
    photo = await db.scalar(
        select(UserPhoto).where(UserPhoto.user_id == user.id, UserPhoto.sort_order == order)
    )
    if photo is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, {"code": "photo_not_found", "message": "照片不存在"}
        )
    deleted = PhotoOut(order=photo.sort_order, url=photo.url)
    await db.delete(photo)
    await db.commit()
    return deleted


@router.put("/photos/reorder", response_model=list[PhotoOut])
async def reorder_photos(
    body: PhotoReorderRequest, user: CurrentUser, db: DBSession
) -> list[PhotoOut]:
    """按完整 photo_id 列表重排 sort_order；未列出的照片保持原相对顺序排在后面"""
    photos = await profile_service.list_photos(db, user.id)
    by_id = {p.id: p for p in photos}
    if any(pid not in by_id for pid in body.photo_ids):
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            {"code": "invalid_photo_ids", "message": "包含不属于当前用户的照片"},
        )

    ordered_ids = list(dict.fromkeys(body.photo_ids))  # 去重保序
    rest = [p for p in photos if p.id not in set(ordered_ids)]
    final = [by_id[pid] for pid in ordered_ids] + rest
    # 两阶段写入：交换等重排会产生中间态撞 (user_id, sort_order) 唯一约束，
    # 先挪到临时高位（对旧顺序单射，不会自撞）flush 释放槽位，再写最终顺序
    for photo in final:
        photo.sort_order += 100
    await db.flush()
    for index, photo in enumerate(final):
        photo.sort_order = index
    await db.commit()

    photos = await profile_service.list_photos(db, user.id)
    return [PhotoOut(order=p.sort_order, url=p.url) for p in photos]


# ── APNs 设备令牌（离线推送）──────────────────────────────────


@router.put("/device-token", status_code=204)
async def register_device_token(
    body: DeviceTokenIn, user: CurrentUser, db: DBSession
) -> Response:
    """上报 APNs 设备令牌（幂等）。

    token 全局唯一：同一设备换账号登录时改绑新账号，
    保证离线推送只发给当前持有该设备的一方。
    """
    stmt = pg_insert(DeviceToken).values(
        user_id=user.id, token=body.token, platform=body.platform,
    ).on_conflict_do_update(
        index_elements=["token"],
        set_={"user_id": user.id, "platform": body.platform, "updated_at": func.now()},
    )
    await db.execute(stmt)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/device-token", status_code=204)
async def delete_device_token(
    db: DBSession,
    token: str = Query(description="要注销的 APNs device token"),
) -> Response:
    """注销设备令牌（登出时调用）。

    凭 token 值删除而不要求 Bearer：登出流程先清 Keychain 再发注销请求，
    若要求鉴权必然 401。token 本身即设备凭据（仅持有设备的 App 可知），
    未知 token 同样返回 204，不泄露存在性。
    """
    await db.execute(delete(DeviceToken).where(DeviceToken.token == token))
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
