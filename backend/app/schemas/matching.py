#  matching.py
#  推荐/匹配 DTO：推荐流水、like/skip/block 响应、匹配列表
#
#  投影约定：user 字段直接承载 projection_service.project_user_profile 的输出
#  （键名手动对齐 iOS UserProfile 模型，见 services/projection.py 文件头）

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel


class RecommendationItem(BaseModel):
    """单条推荐：投影 + 评分（distance 预留，地理位置功能未接入恒为 None）"""

    score: float
    distance_km: float | None = None
    user: dict[str, Any]


class RecommendationListOut(BaseModel):
    items: list[RecommendationItem]


class LikeActionResponse(BaseModel):
    """like/skip/block 通用响应；仅 like 可能触发匹配"""

    matched: bool
    match_id: uuid.UUID | None = None


class MatchOut(BaseModel):
    """单条匹配：id + 对方投影 + 建立时间"""

    id: uuid.UUID
    user: dict[str, Any]
    created_at: datetime


class MatchListOut(BaseModel):
    """游标分页：next_cursor 透传给 GET /matches?cursor= 即可，None 表示取完"""

    items: list[MatchOut]
    next_cursor: str | None = None
