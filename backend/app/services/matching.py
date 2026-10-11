#  matching.py
#  推荐/匹配服务：候选池 → 评分 → 推荐流水；like/skip/block → 双向匹配检测
#
#  评分（P5 简化版，P12 接入筛选条件后重写）：
#  - 同城 +10
#  - uuid5(我, 对方) 派生 0~3 的稳定伪随机小数打破平局
#    （同对用户分数恒定，避免每次刷新顺序抖动）
#
#  匹配判定：like 方向写入 likes 后，若对方此前已 like 我则建 matches
#  （user_a_id < user_b_id 归一化）。并发双向 like 由唯一约束兜底，
#  用 savepoint 包裹插入，撞约束时回滚 savepoint 后回读已有 match。

import uuid
from datetime import UTC, date, datetime

from fastapi import HTTPException, status
from sqlalchemy import or_, select, tuple_
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.chat import Conversation
from app.models.matching import (
    Like,
    LikeDirection,
    Match,
    Recommendation,
    RecommendationStatus,
)
from app.models.profile import Profile, UserPhoto
from app.models.user import User
from app.schemas.matching import (
    LikeActionResponse,
    MatchListOut,
    MatchOut,
    RecommendationItem,
    RecommendationListOut,
)
from app.services.projection import project_user_profile
from app.ws import events
from app.ws.hub import hub

# 每批推荐条数（iOS HomeView 单批展示量；真实召回/分页策略 P12 再做）
DEFAULT_RECOMMEND_LIMIT = 10
# 匹配列表单页条数
DEFAULT_MATCH_PAGE_SIZE = 20

_DIRECTION_TO_STATUS = {
    LikeDirection.like: RecommendationStatus.liked,
    LikeDirection.skip: RecommendationStatus.skipped,
    LikeDirection.block: RecommendationStatus.blocked,
}


# ── 推荐 ──────────────────────────────────────────────────────


def score_pair(me_id: uuid.UUID, me_city: str, target_id: uuid.UUID, target_city: str) -> float:
    """同城加分 + 稳定伪随机抖动（同对用户恒定）"""
    score = 10.0 if me_city and target_city and me_city == target_city else 0.0
    jitter = int(uuid.uuid5(uuid.NAMESPACE_URL, f"{me_id}:{target_id}").hex[:8], 16)
    return score + jitter / 0xFFFFFFFF * 3


async def list_recommendations(
    db: AsyncSession, user: User, limit: int = DEFAULT_RECOMMEND_LIMIT
) -> RecommendationListOut:
    """候选池：排除自己 / 已行动过（likes 任意方向）/ block 了我 / 已匹配的用户。

    join profiles 天然过滤未填资料的用户（city/nickname 全空无推荐意义）；
    取池后 Python 层评分排序（原型阶段池子小，P12 优化 SQL 侧排序）。
    """
    me_profile = await db.get(Profile, user.id)
    me_city = me_profile.city if me_profile else ""

    acted = select(Like.likee_id).where(Like.liker_id == user.id)
    blocked_me = select(Like.liker_id).where(
        Like.likee_id == user.id, Like.direction == LikeDirection.block
    )
    matched_ids = select(Match.user_b_id).where(Match.user_a_id == user.id).union(
        select(Match.user_a_id).where(Match.user_b_id == user.id)
    )
    rows = (
        await db.execute(
            select(User, Profile)
            .join(Profile, Profile.user_id == User.id)
            .where(
                User.id != user.id,
                User.id.not_in(acted),
                User.id.not_in(blocked_me),
                User.id.not_in(matched_ids),
            )
            .order_by(User.id)  # 稳定取池，真实召回策略 P12 再做
            .limit(limit)
        )
    ).all()

    scored = sorted(
        ((score_pair(user.id, me_city, u.id, p.city), u, p) for u, p in rows),
        key=lambda item: item[0],
        reverse=True,
    )

    # 推荐流水落库：同对用户唯一，重复推荐静默跳过
    if scored:
        today = date.today()
        stmt = pg_insert(Recommendation).values(
            [
                {
                    "user_id": user.id,
                    "target_id": target.id,
                    "batch_date": today,
                    "score": score,
                    "status": RecommendationStatus.shown,
                }
                for score, target, _ in scored
            ]
        ).on_conflict_do_nothing(constraint="uq_recommendations_user_target")
        await db.execute(stmt)
        await db.commit()

    users, profiles, photos_by_user = await _project_batch(
        db, [target.id for _, target, _ in scored]
    )
    items = [
        RecommendationItem(
            score=score,
            user=project_user_profile(
                users[target.id], profiles[target.id], photos_by_user.get(target.id, [])
            ),
        )
        for score, target, _ in scored
    ]
    return RecommendationListOut(items=items)


# ── like / skip / block ───────────────────────────────────────


async def react(
    db: AsyncSession, user: User, target_id: uuid.UUID, direction: LikeDirection
) -> LikeActionResponse:
    """对目标用户表态。重复操作幂等（改主意直接覆盖方向）；like 触发匹配检测。"""
    if target_id == user.id:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            {"code": "self_action", "message": "不能对自己操作"},
        )
    target = await db.get(User, target_id)
    if target is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, {"code": "target_not_found", "message": "目标用户不存在"}
        )

    stmt = pg_insert(Like).values(
        liker_id=user.id, likee_id=target_id, direction=direction
    ).on_conflict_do_update(
        constraint="uq_likes_liker_likee", set_={"direction": direction}
    )
    await db.execute(stmt)

    # 推荐流水状态同步；候选池之外 like 的用户没有流水行，跳过
    rec = await db.scalar(
        select(Recommendation).where(
            Recommendation.user_id == user.id, Recommendation.target_id == target_id
        )
    )
    if rec is not None:
        rec.status = _DIRECTION_TO_STATUS[direction]

    matched = False
    match_id: uuid.UUID | None = None
    new_match_created = False
    if direction == LikeDirection.like:
        other_like = await db.scalar(
            select(Like).where(
                Like.liker_id == target_id,
                Like.likee_id == user.id,
                Like.direction == LikeDirection.like,
            )
        )
        if other_like is not None:
            a_id, b_id = sorted((user.id, target_id))
            existing = await db.scalar(
                select(Match).where(Match.user_a_id == a_id, Match.user_b_id == b_id)
            )
            if existing is not None:
                matched, match_id = True, existing.id
            else:
                # 1 match 1 conversation：随匹配一并建立（唯一约束兜底并发）
                match = Match(user_a_id=a_id, user_b_id=b_id)
                conversation = Conversation(user_a_id=a_id, user_b_id=b_id)
                try:
                    async with db.begin_nested():
                        db.add(match)
                        await db.flush()  # 先取回 match.id（server 端生成）
                        conversation.match_id = match.id
                        db.add(conversation)
                        await db.flush()
                    matched, match_id = True, match.id
                    new_match_created = True
                except IntegrityError:
                    # 并发双向 like：对方请求已建 match；savepoint 已回滚
                    # （match 与 conversation 一起），外层事务不受影响
                    existing = await db.scalar(
                        select(Match).where(Match.user_a_id == a_id, Match.user_b_id == b_id)
                    )
                    if existing is None:
                        raise
                    matched, match_id = True, existing.id

    await db.commit()

    # 新匹配实时通知对方（仅新建时；重复 like 幂等不重发）
    if new_match_created and match_id is not None:
        await hub.send_to_user(
            target_id, {"type": events.MATCH, "match_id": str(match_id)}
        )

    return LikeActionResponse(matched=matched, match_id=match_id)


# ── 匹配列表 ──────────────────────────────────────────────────


async def list_matches(
    db: AsyncSession, user: User, cursor: str | None, limit: int = DEFAULT_MATCH_PAGE_SIZE
) -> MatchListOut:
    """按建立时间倒序 + (created_at, id) 复合游标分页。"""
    stmt = (
        select(Match)
        .where(or_(Match.user_a_id == user.id, Match.user_b_id == user.id))
        .order_by(Match.created_at.desc(), Match.id.desc())
    )
    if cursor:
        cursor_at, cursor_id = _decode_cursor(cursor)
        stmt = stmt.where(tuple_(Match.created_at, Match.id) < tuple_(cursor_at, cursor_id))
    matches = list((await db.scalars(stmt.limit(limit + 1))).all())
    has_more = len(matches) > limit
    matches = matches[:limit]

    other_ids = [m.user_b_id if m.user_a_id == user.id else m.user_a_id for m in matches]
    users, profiles, photos_by_user = await _project_batch(db, other_ids)
    items = [
        MatchOut(
            id=match.id,
            user=project_user_profile(
                users[other_id], profiles[other_id], photos_by_user.get(other_id, [])
            ),
            created_at=match.created_at,
        )
        for match, other_id in zip(matches, other_ids, strict=True)
    ]
    return MatchListOut(
        items=items, next_cursor=_encode_cursor(matches[-1]) if has_more and matches else None
    )


async def get_match(db: AsyncSession, user: User, match_id: uuid.UUID) -> MatchOut:
    match = await db.get(Match, match_id)
    if match is None or user.id not in (match.user_a_id, match.user_b_id):
        raise HTTPException(
            status.HTTP_404_NOT_FOUND, {"code": "match_not_found", "message": "匹配不存在"}
        )
    other_id = match.user_b_id if match.user_a_id == user.id else match.user_a_id
    users, profiles, photos_by_user = await _project_batch(db, [other_id])
    return MatchOut(
        id=match.id,
        user=project_user_profile(
            users[other_id], profiles[other_id], photos_by_user.get(other_id, [])
        ),
        created_at=match.created_at,
    )


# ── 内部辅助 ──────────────────────────────────────────────────


async def _project_batch(
    db: AsyncSession, target_ids: list[uuid.UUID]
) -> tuple[dict[uuid.UUID, User], dict[uuid.UUID, Profile], dict[uuid.UUID, list[UserPhoto]]]:
    """批量取投影三件套：users / profiles / photos（photos 按 sort_order）。

    注册后未碰过资料接口的用户没有 profiles 行，投影用空 Profile 兜底（不落库）。
    """
    if not target_ids:
        return {}, {}, {}
    users = {
        u.id: u for u in (await db.scalars(select(User).where(User.id.in_(target_ids)))).all()
    }
    profiles = {
        p.user_id: p
        for p in (await db.scalars(select(Profile).where(Profile.user_id.in_(target_ids)))).all()
    }
    photos_by_user: dict[uuid.UUID, list[UserPhoto]] = {}
    for photo in (
        await db.scalars(
            select(UserPhoto)
            .where(UserPhoto.user_id.in_(target_ids))
            .order_by(UserPhoto.sort_order)
        )
    ).all():
        photos_by_user.setdefault(photo.user_id, []).append(photo)
    return users, profiles, photos_by_user


def _encode_cursor(match: Match) -> str:
    """游标：created_at 的 epoch 微秒 + id（纯数字/竖线/连字符，URL 安全）"""
    return f"{int(match.created_at.timestamp() * 1_000_000)}|{match.id}"


def _decode_cursor(cursor: str) -> tuple[datetime, uuid.UUID]:
    us_str, _, id_str = cursor.partition("|")
    try:
        return datetime.fromtimestamp(int(us_str) / 1_000_000, tz=UTC), uuid.UUID(id_str)
    except (ValueError, OverflowError, OSError):
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY,
            {"code": "invalid_cursor", "message": "游标格式不正确"},
        ) from None
