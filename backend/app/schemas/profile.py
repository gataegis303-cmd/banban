#  profile.py
#  资料接口的请求/响应模型（Pydantic v2）
#
#  增量合并语义（对齐 iOS MyProfile.merge）：
#  - 文本标量：None / 空串 = 不修改；非空 = 覆盖
#  - 可选枚举标量：None = 不修改；非 None = 覆盖
#  - bool / int / 集合 / 字典：None = 不修改；传值（含 [] / {} / 0）= 整体覆盖
#  - birthday：None = 不修改；非 None 时写入 users 并由服务端派生 age

import uuid
from datetime import date
from typing import Literal

from pydantic import BaseModel, Field

# ── 枚举值域（对齐 iOS Enums.swift 的中文 rawValue）───────────────

Gender = Literal["男", "女"]
Marriage = Literal["未婚", "离异"]
Children = Literal["无子女", "有子女随我", "有子女不随我"]
YesNoSometimes = Literal["是", "否", "偶尔"]
Sleep = Literal["早睡早起", "晚睡晚起", "不规律"]
Direction = Literal["领证结婚", "协议搭伴", "自由式"]
PartnerStatus = Literal["未婚无伴侣", "有同性伴侣", "离异"]
Seeking = Literal["异性", "同性", "不限"]
LivingMode = Literal["同居同房", "同居分房", "同城分居"]
FinanceMode = Literal["AA", "按收入比例", "一事一议"]
FormalFinanceMode = Literal["AA", "按收入比例", "一事一议", "共同财富"]
ChildIntent = Literal["是", "否", "领养", "不确定"]
SocialBoundary = Literal["保持独立社交", "共同朋友圈", "可商量"]
ParentRelation = Literal["与其同住", "同城居住", "脱离关系", "父母双亡"]


class DeviceTokenIn(BaseModel):
    """APNs 设备令牌上报（PUT /me/device-token）"""

    token: str = Field(min_length=10, max_length=200, description="APNs device token（hex）")
    platform: str = Field(default="ios", max_length=10)


class PhotoOut(BaseModel):
    order: int = Field(ge=0, le=5, description="展示顺序 0-5")
    url: str = Field(description="图片访问 URL（未上传完成时为空串）")


class ProfileOut(BaseModel):
    """我的资料（对齐 iOS MyProfile 全字段）"""

    # 身份层（只读，来自 users）
    age: int | None = Field(default=None, description="服务端权威年龄（18 = 成年下限）")
    birthday: date | None = None

    # 基本信息
    nickname: str
    gender: Gender | None = None
    city: str
    height: str
    education: str
    occupation: str
    income: str
    marriage: Marriage | None = None
    children: Children | None = None
    living_situation: str

    # 生活方式
    pets: list[str]
    sleep: Sleep | None = None
    smoking: YesNoSometimes | None = None
    drinking: YesNoSometimes | None = None

    # 匹配意图
    match_type: str
    direction: Direction | None = None
    partner_status: PartnerStatus | None = None
    seeking: Seeking | None = None
    living_mode: LivingMode | None = None
    child_intent: ChildIntent | None = None
    social_boundary: SocialBoundary | None = None
    parent_relation: ParentRelation | None = None
    finance_trial: FinanceMode | None = None
    finance_formal: FormalFinanceMode | None = None
    intended_city: str

    # 标签 / 雷区
    no_accept: list[str]

    # 交通
    transport_none: bool
    transport_tools: list[str]
    transport_counts: dict[str, int]
    taxi_monthly_quota: str

    # 住房
    housing_situation: str | None = None
    spare_rooms: int
    housing_conditions: list[str]

    # 资源 / 其他标签
    resources: list[str]
    other_tags: list[str]

    # 自述
    headline: str
    about_me: str

    # 状态
    start_time: str
    completion: int = Field(ge=0, le=100, description="服务端计算的资料完成度")
    profile_submitted: bool

    # 照片（sort_order 升序）
    photos: list[PhotoOut]


class ProfileUpdate(BaseModel):
    """增量合并语义见文件头注释；所有字段缺省 = 不修改"""

    birthday: date | None = None

    nickname: str | None = Field(default=None, max_length=50)
    gender: Gender | None = None
    city: str | None = Field(default=None, max_length=50)
    height: str | None = Field(default=None, max_length=20)
    education: str | None = Field(default=None, max_length=50)
    occupation: str | None = Field(default=None, max_length=100)
    income: str | None = Field(default=None, max_length=50)
    marriage: Marriage | None = None
    children: Children | None = None
    living_situation: str | None = Field(default=None, max_length=100)

    pets: list[str] | None = None
    sleep: Sleep | None = None
    smoking: YesNoSometimes | None = None
    drinking: YesNoSometimes | None = None

    match_type: str | None = Field(default=None, max_length=50)
    direction: Direction | None = None
    partner_status: PartnerStatus | None = None
    seeking: Seeking | None = None
    living_mode: LivingMode | None = None
    child_intent: ChildIntent | None = None
    social_boundary: SocialBoundary | None = None
    parent_relation: ParentRelation | None = None
    finance_trial: FinanceMode | None = None
    finance_formal: FormalFinanceMode | None = None
    intended_city: str | None = Field(default=None, max_length=50)

    no_accept: list[str] | None = None

    transport_none: bool | None = None
    transport_tools: list[str] | None = None
    transport_counts: dict[str, int] | None = None
    taxi_monthly_quota: str | None = Field(default=None, max_length=50)

    housing_situation: str | None = Field(default=None, max_length=50)
    spare_rooms: int | None = Field(default=None, ge=0, le=99)
    housing_conditions: list[str] | None = None

    resources: list[str] | None = None
    other_tags: list[str] | None = None

    headline: str | None = Field(default=None, max_length=200)
    about_me: str | None = None

    start_time: str | None = Field(default=None, max_length=50)


class ProfileSubmittedResponse(BaseModel):
    profile_submitted: bool
    completion: int


class PhotoUploadRequest(BaseModel):
    order: int = Field(ge=0, le=5, description="展示顺序 0-5")
    content_type: Literal["image/jpeg", "image/png", "image/webp"]


class PhotoUploadResponse(BaseModel):
    photo_id: uuid.UUID
    upload_url: str = Field(description="PUT 上传目标（开发环境为本地端点，生产为 OSS 预签名 URL）")
    oss_key: str


class PhotoReorderRequest(BaseModel):
    """完整有序 photo_id 列表（未列出的照片保持原相对顺序排在后面）"""

    photo_ids: list[uuid.UUID] = Field(max_length=6)
