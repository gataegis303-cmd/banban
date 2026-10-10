#  profile.py
#  资料服务：get_or_create / 增量合并 / 完成度计算 / 年龄派生 / 向导提交

import uuid
from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.profile import Profile, UserPhoto
from app.models.user import User
from app.schemas.profile import PhotoOut, ProfileOut, ProfileUpdate

PHOTO_LIMIT = 6  # 资料照片上限（与产品规格一致）


async def get_or_create_profile(db: AsyncSession, user_id: uuid.UUID) -> Profile:
    """profiles 与 users 1:1；登录后首次访问资料接口时惰性建行"""
    profile = await db.get(Profile, user_id)
    if profile is None:
        profile = Profile(user_id=user_id)
        db.add(profile)
        await db.flush()
    return profile


async def age_from_birthday(birthday: date) -> int:
    """周岁年龄，max(18, ...) 钳制成车下限（18 = 成年），与 iOS 端规则一致"""
    today = date.today()
    years = today.year - birthday.year - ((today.month, today.day) < (birthday.month, birthday.day))
    return max(18, years)


async def count_photos(db: AsyncSession, user_id: uuid.UUID) -> int:
    return await db.scalar(
        select(func.count()).select_from(UserPhoto).where(UserPhoto.user_id == user_id)
    ) or 0


async def list_photos(db: AsyncSession, user_id: uuid.UUID) -> list[UserPhoto]:
    result = await db.scalars(
        select(UserPhoto)
        .where(UserPhoto.user_id == user_id)
        .order_by(UserPhoto.sort_order)
    )
    return list(result)


def compute_completion(profile: Profile, photo_count: int) -> int:
    """完成度公式对齐 iOS ProfileDraft.myProfileCompletion"""
    score = 40
    if profile.nickname:
        score += 10
    if profile.gender:
        score += 5
    if profile.city:
        score += 5
    if profile.occupation:
        score += 5
    if profile.direction:
        score += 10
    if profile.no_accept:
        score += 5
    if photo_count >= 3:
        score += 15
    elif photo_count > 0:
        score += 5
    return min(score, 100)


async def apply_update(
    db: AsyncSession, user: User, profile: Profile, payload: ProfileUpdate
) -> None:
    """增量合并（语义见 schemas/profile.py 文件头注释）"""
    # birthday 特殊：写 users（服务端权威）并派生 age
    if payload.birthday is not None:
        user.birthday = payload.birthday
        user.age = await age_from_birthday(payload.birthday)

    # 文本标量：非空才覆盖
    _set_if_text(profile, "nickname", payload.nickname)
    _set_if_text(profile, "city", payload.city)
    _set_if_text(profile, "height", payload.height)
    _set_if_text(profile, "education", payload.education)
    _set_if_text(profile, "occupation", payload.occupation)
    _set_if_text(profile, "income", payload.income)
    _set_if_text(profile, "living_situation", payload.living_situation)
    _set_if_text(profile, "match_type", payload.match_type)
    _set_if_text(profile, "intended_city", payload.intended_city)
    _set_if_text(profile, "taxi_monthly_quota", payload.taxi_monthly_quota)
    _set_if_text(profile, "headline", payload.headline)
    _set_if_text(profile, "start_time", payload.start_time)
    # about_me 允许显式清空：非 None 即覆盖（长文本，iOS merge 未特殊处理）

    # 可选枚举标量：非 None 才覆盖
    for field in (
        "gender", "marriage", "children", "sleep", "smoking", "drinking",
        "direction", "partner_status", "seeking", "living_mode",
        "child_intent", "social_boundary", "parent_relation",
        "finance_trial", "finance_formal", "housing_situation",
    ):
        value = getattr(payload, field)
        if value is not None:
            setattr(profile, field, value)

    # 数值 / 开关 / 集合：非 None 即整体覆盖（清空即有意为之）
    for field in (
        "pets", "no_accept", "transport_none", "transport_tools",
        "transport_counts", "housing_conditions", "spare_rooms",
        "resources", "other_tags",
    ):
        value = getattr(payload, field)
        if value is not None:
            setattr(profile, field, value)

    profile.completion = compute_completion(profile, await count_photos(db, user.id))
    await db.flush()


def _set_if_text(obj: Profile, field: str, value: str | None) -> None:
    if value:  # None / 空串都不修改
        setattr(obj, field, value)


def to_profile_out(profile: Profile, user: User, photos: list[UserPhoto]) -> ProfileOut:
    return ProfileOut(
        age=user.age,
        birthday=user.birthday,
        nickname=profile.nickname,
        gender=profile.gender,
        city=profile.city,
        height=profile.height,
        education=profile.education,
        occupation=profile.occupation,
        income=profile.income,
        marriage=profile.marriage,
        children=profile.children,
        living_situation=profile.living_situation,
        pets=profile.pets,
        sleep=profile.sleep,
        smoking=profile.smoking,
        drinking=profile.drinking,
        match_type=profile.match_type,
        direction=profile.direction,
        partner_status=profile.partner_status,
        seeking=profile.seeking,
        living_mode=profile.living_mode,
        child_intent=profile.child_intent,
        social_boundary=profile.social_boundary,
        parent_relation=profile.parent_relation,
        finance_trial=profile.finance_trial,
        finance_formal=profile.finance_formal,
        intended_city=profile.intended_city,
        no_accept=profile.no_accept,
        transport_none=profile.transport_none,
        transport_tools=profile.transport_tools,
        transport_counts=profile.transport_counts,
        taxi_monthly_quota=profile.taxi_monthly_quota,
        housing_situation=profile.housing_situation,
        spare_rooms=profile.spare_rooms,
        housing_conditions=profile.housing_conditions,
        resources=profile.resources,
        other_tags=profile.other_tags,
        headline=profile.headline,
        about_me=profile.about_me,
        start_time=profile.start_time,
        completion=profile.completion,
        profile_submitted=profile.profile_submitted,
        photos=[PhotoOut(order=p.sort_order, url=p.url) for p in photos],
    )
