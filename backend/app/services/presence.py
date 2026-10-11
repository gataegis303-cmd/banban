#  presence.py
#  在线态服务：Redis 热数据（短 TTL 心跳续期）+ user_presence 表冷备
#
#  在线判定以 Hub 连接表为实时真源；Redis/DB 用于跨请求查询与离线兜底
#  （APNs 判断是否需要推送，P13 接入）。

import uuid

from sqlalchemy import select, union
from sqlalchemy.ext.asyncio import AsyncSession

from app.deps import redis_client
from app.models.base import utcnow
from app.models.matching import Match
from app.models.user import UserPresence

PRESENCE_KEY_PREFIX = "presence:"
# TTL 略大于客户端 30s 心跳间隔，一跳未达不掉线，两跳才判离线
PRESENCE_TTL_SECONDS = 60


def _redis_key(user_id: uuid.UUID) -> str:
    return f"{PRESENCE_KEY_PREFIX}{user_id}"


async def set_online(db: AsyncSession, user_id: uuid.UUID) -> None:
    await redis_client.set(_redis_key(user_id), "1", ex=PRESENCE_TTL_SECONDS)
    await _upsert(db, user_id, is_online=True)


async def set_offline(db: AsyncSession, user_id: uuid.UUID) -> None:
    await redis_client.delete(_redis_key(user_id))
    await _upsert(db, user_id, is_online=False)


async def touch(user_id: uuid.UUID) -> None:
    """心跳续期（仅 Redis，不落库）"""
    await redis_client.expire(_redis_key(user_id), PRESENCE_TTL_SECONDS)


async def match_partner_ids(db: AsyncSession, user_id: uuid.UUID) -> list[uuid.UUID]:
    """我在 matches 里的全部对方 id（上下线广播的目标集合）"""
    stmt = union(
        select(Match.user_b_id).where(Match.user_a_id == user_id),
        select(Match.user_a_id).where(Match.user_b_id == user_id),
    )
    return list((await db.scalars(stmt)).all())


async def _upsert(db: AsyncSession, user_id: uuid.UUID, is_online: bool) -> None:
    """user_presence 表冷备 upsert：last_seen_at 上下线都刷新为当前时刻"""
    row = await db.get(UserPresence, user_id)
    if row is None:
        db.add(UserPresence(user_id=user_id, is_online=is_online, last_seen_at=utcnow()))
    else:
        row.is_online = is_online
        row.last_seen_at = utcnow()
    await db.commit()
