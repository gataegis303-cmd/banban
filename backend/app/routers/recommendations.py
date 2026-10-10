#  recommendations.py
#  推荐路由：拉取推荐流 + like/skip/block 表态（like 触发双向匹配检测）

import uuid

from fastapi import APIRouter, Query

from app.deps import CurrentUser, DBSession
from app.models.matching import LikeDirection
from app.schemas.matching import LikeActionResponse, RecommendationListOut
from app.services import matching

router = APIRouter(prefix="/recommendations", tags=["recommendations"])


@router.get("", response_model=RecommendationListOut)
async def get_recommendations(
    user: CurrentUser,
    db: DBSession,
    limit: int = Query(default=matching.DEFAULT_RECOMMEND_LIMIT, ge=1, le=50),
) -> RecommendationListOut:
    return await matching.list_recommendations(db, user, limit)


async def _react(
    user: CurrentUser, db: DBSession, target_id: uuid.UUID, direction: LikeDirection
) -> LikeActionResponse:
    return await matching.react(db, user, target_id, direction)


@router.post("/{target_id}/like", response_model=LikeActionResponse)
async def like_target(
    target_id: uuid.UUID, user: CurrentUser, db: DBSession
) -> LikeActionResponse:
    """对方此前已 like 我则立即建立 match（响应 matched=true + match_id）"""
    return await _react(user, db, target_id, LikeDirection.like)


@router.post("/{target_id}/skip", response_model=LikeActionResponse)
async def skip_target(
    target_id: uuid.UUID, user: CurrentUser, db: DBSession
) -> LikeActionResponse:
    """跳过：不再推荐对方（matched 恒 false）"""
    return await _react(user, db, target_id, LikeDirection.skip)


@router.post("/{target_id}/block", response_model=LikeActionResponse)
async def block_target(
    target_id: uuid.UUID, user: CurrentUser, db: DBSession
) -> LikeActionResponse:
    """拉黑：双方互相不可见（对方推荐池排除我）"""
    return await _react(user, db, target_id, LikeDirection.block)
