#  projection.py
#  UserProfile 投影服务：把 profiles 行序列化为 iOS UserProfile 模型
#
#  iOS 端 UserProfile 零改动（Models.swift），键名手动对齐：
#  id/name/age/city/occupation/avatarURL/verified/headline/cardTags/
#  intentionTags/noAccept/lifestyle[{icon,label}]/aboutMe/photos[url...]
#
#  标签拼接规则按 MockData.swift 样本归纳（mock 为手工演示数据，个别样本
#  存在不一致；以下规则为服务端权威定义）：

from typing import Any

from app.models.profile import Profile, UserPhoto
from app.models.user import User, VerificationLevel

# verified：实名任一环节通过即视为已认证
_VERIFIED_LEVELS = {
    VerificationLevel.id_verified,
    VerificationLevel.face_verified,
    VerificationLevel.complete,
}

# 首页卡片 4 槽：居住方式 → 财务（试婚期优先）→ 子女意向 → 宠物摘要；
# 槽位值为空则该位不出（不向后补位）


def _pet_summary(pets: list[str]) -> str | None:
    """宠物摘要：恰好一种动物 → 有猫/有狗/养宠；多种 → 养宠；["无"] → 无"""
    animals = [p for p in pets if p in ("猫", "狗", "其他")]
    if pets == ["无"]:
        return "无"
    if len(animals) == 1:
        return {"猫": "有猫", "狗": "有狗"}.get(animals[0], "养宠")
    if len(animals) > 1:
        return "养宠"
    return None


def build_card_tags(profile: Profile) -> list[str]:
    tags: list[str | None] = [
        profile.living_mode,
        profile.finance_trial or profile.finance_formal,
        profile.child_intent,
        _pet_summary(profile.pets),
    ]
    return [t for t in tags if t]


def _pet_acceptance(pets: list[str]) -> str | None:
    """宠物接受度：含猫 → 接受宠物猫；否则含狗 → 接受宠物狗；否则含其他 → 接受宠物"""
    if "猫" in pets:
        return "接受宠物猫"
    if "狗" in pets:
        return "接受宠物狗"
    if "其他" in pets:
        return "接受宠物"
    return None


def build_intention_tags(profile: Profile) -> list[str]:
    """搭伴意向标签：固定槽位顺序，取非空 rawValue"""
    tags: list[str | None] = [
        profile.direction,
        profile.partner_status,
        profile.seeking,
        profile.living_mode,
        profile.finance_trial,
        profile.finance_formal,
        profile.child_intent,
        _pet_acceptance(profile.pets),
        profile.social_boundary,
        profile.parent_relation,
    ]
    return [t for t in tags if t]


def build_lifestyle(profile: Profile) -> list[dict[str, str]]:
    """生活方式三件套（icon 为 iOS SF Symbol 名，对齐 MockData 用法）"""
    items: list[dict[str, str]] = []
    if profile.smoking:
        label = {"是": "吸烟", "否": "不吸烟", "偶尔": "偶尔吸烟"}[profile.smoking]
        items.append({"icon": "ban" if profile.smoking != "是" else "cigarette", "label": label})
    if profile.drinking:
        label = {"是": "饮酒", "否": "不饮酒", "偶尔": "偶尔饮酒"}[profile.drinking]
        items.append({"icon": "wineglass", "label": label})
    if profile.sleep:
        icon = {"早睡早起": "moon.zzz", "晚睡晚起": "sun.horizon", "不规律": "clock"}[profile.sleep]
        items.append({"icon": icon, "label": profile.sleep})
    return items


def project_user_profile(
    user: User, profile: Profile, photos: list[UserPhoto]
) -> dict[str, Any]:
    """单用户投影（推荐流水 / 会话列表共用）"""
    urls = [p.url for p in photos if p.url]
    return {
        "id": str(user.id),
        "name": profile.nickname or "搭伴用户",
        "age": user.age or 18,
        "city": profile.city,
        "occupation": profile.occupation,
        "avatarURL": urls[0] if urls else None,
        "verified": user.verification in _VERIFIED_LEVELS,
        "headline": profile.headline,
        "cardTags": build_card_tags(profile),
        "intentionTags": build_intention_tags(profile),
        "noAccept": list(profile.no_accept),
        "lifestyle": build_lifestyle(profile),
        "aboutMe": profile.about_me,
        "photos": urls,
    }
