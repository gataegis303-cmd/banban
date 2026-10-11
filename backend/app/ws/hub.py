#  hub.py
#  WebSocket 连接注册表（Hub）：user_id → 活跃连接集合
#
#  单进程实现（原型阶段 uvicorn 单 worker）；同一用户多设备同时在线，
#  广播遍历其所有连接。生产多实例部署时广播改走 Redis pub/sub（P13）。

import asyncio
import json
import uuid

from fastapi import WebSocket


class ConnectionHub:
    def __init__(self) -> None:
        self._connections: dict[uuid.UUID, set[WebSocket]] = {}
        self._lock = asyncio.Lock()

    async def connect(self, user_id: uuid.UUID, ws: WebSocket) -> None:
        async with self._lock:
            self._connections.setdefault(user_id, set()).add(ws)

    async def disconnect(self, user_id: uuid.UUID, ws: WebSocket) -> None:
        async with self._lock:
            conns = self._connections.get(user_id)
            if conns is not None:
                conns.discard(ws)
                if not conns:
                    del self._connections[user_id]

    def is_online(self, user_id: uuid.UUID) -> bool:
        return bool(self._connections.get(user_id))

    async def send_to_user(self, user_id: uuid.UUID, payload: dict) -> None:
        """向该用户所有活跃连接推送事件；发送失败的死连接顺带清理。"""
        text = json.dumps(payload, ensure_ascii=False)
        dead: list[WebSocket] = []
        for ws in list(self._connections.get(user_id, ())):
            try:
                await ws.send_text(text)
            except Exception:
                dead.append(ws)
        for ws in dead:
            await self.disconnect(user_id, ws)


# 模块级单例：handler / services 共享同一注册表
hub = ConnectionHub()
