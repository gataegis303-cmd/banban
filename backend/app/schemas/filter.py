#  filter.py
#  筛选条件 DTO：对齐 iOS FilterState / user_filters 表
#
#  语义约定：
#  - 单选枚举字段 None = 不限；多选集合空列表 = 不限
#  - 枚举值存 iOS rawValue（中文），与 profiles 枚举字段直接可比，免翻译层
#  - PUT 为全量覆盖语义（筛选是整体快照，不走资料的增量合并）

from pydantic import BaseModel, ConfigDict, Field, model_validator

# 与 users.age 的钳制下限对齐（FilterState.ageBounds = 18...80）
_AGE_LOWER, _AGE_UPPER = 18, 80


class FilterOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    city: str | None = Field(default=None, max_length=50)
    age_min: int = Field(ge=_AGE_LOWER, le=_AGE_UPPER)
    age_max: int = Field(ge=_AGE_LOWER, le=_AGE_UPPER)
    direction: str | None = Field(default=None, max_length=20)
    partner_status: str | None = Field(default=None, max_length=20)
    seeking: str | None = Field(default=None, max_length=10)
    living_mode: str | None = Field(default=None, max_length=20)
    parent_relation: str | None = Field(default=None, max_length=20)
    finance_trial: str | None = Field(default=None, max_length=20)
    finance_formal: str | None = Field(default=None, max_length=20)
    child_intent: str | None = Field(default=None, max_length=20)
    pets: list[str] = []
    no_accept: list[str] = []

    @model_validator(mode="after")
    def _check_range(self) -> "FilterOut":
        if self.age_min > self.age_max:
            raise ValueError("age_min 不能大于 age_max")
        return self


class FilterUpdate(FilterOut):
    """PUT /me/filter 请求体（与响应同构，全量覆盖）"""
