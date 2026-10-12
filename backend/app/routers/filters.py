#  filters.py
#  筛选条件路由：GET /me/filter（惰性建行）/ PUT /me/filter（全量覆盖）

from fastapi import APIRouter

from app.deps import CurrentUser, DBSession
from app.schemas.filter import FilterOut, FilterUpdate
from app.services import filter as filter_service

router = APIRouter(prefix="/me", tags=["filter"])


@router.get("/filter", response_model=FilterOut)
async def get_filter(user: CurrentUser, db: DBSession) -> FilterOut:
    row = await filter_service.get_or_create_filter(db, user.id)
    await db.commit()  # 惰性建行落库
    return FilterOut.model_validate(row)


@router.put("/filter", response_model=FilterOut)
async def update_filter(
    body: FilterUpdate, user: CurrentUser, db: DBSession
) -> FilterOut:
    row = await filter_service.get_or_create_filter(db, user.id)
    filter_service.apply_update(row, body)
    await db.commit()
    return FilterOut.model_validate(row)
