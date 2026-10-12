#  filter.py
#  筛选条件服务：GET 惰性建行（默认 20-40 岁、其余不限）/ PUT 全量覆盖

from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.profile import UserFilter
from app.schemas.filter import FilterUpdate

# PUT 请求体字段 → UserFilter 列（同名字段整体覆盖）
_FILTER_FIELDS: tuple[str, ...] = (
    "city", "age_min", "age_max", "direction", "partner_status", "seeking",
    "living_mode", "parent_relation", "finance_trial", "finance_formal",
    "child_intent", "pets", "no_accept",
)


async def get_or_create_filter(db: AsyncSession, user_id: Any) -> UserFilter:
    row = await db.get(UserFilter, user_id)
    if row is None:
        row = UserFilter(user_id=user_id)
        db.add(row)
    return row


def apply_update(row: UserFilter, body: FilterUpdate) -> None:
    for field in _FILTER_FIELDS:
        setattr(row, field, getattr(body, field))
