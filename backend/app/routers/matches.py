#  matches.py
#  匹配路由：列表（游标分页）+ 详情

import uuid

from fastapi import APIRouter, Query

from app.deps import CurrentUser, DBSession
from app.schemas.matching import MatchListOut, MatchOut
from app.services import matching

router = APIRouter(prefix="/matches", tags=["matches"])


@router.get("", response_model=MatchListOut)
async def list_matches(
    user: CurrentUser,
    db: DBSession,
    cursor: str | None = None,
    limit: int = Query(default=matching.DEFAULT_MATCH_PAGE_SIZE, ge=1, le=50),
) -> MatchListOut:
    """next_cursor 非 None 时带上传入 cursor 继续翻页"""
    return await matching.list_matches(db, user, cursor, limit)


@router.get("/{match_id}", response_model=MatchOut)
async def get_match(
    match_id: uuid.UUID, user: CurrentUser, db: DBSession
) -> MatchOut:
    return await matching.get_match(db, user, match_id)
