"""conversation for chat http

Revision ID: a3f8c2d91b47
Revises: 862e4eec12b9
Create Date: 2026-10-10 20:12:31.752204
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a3f8c2d91b47'
down_revision: Union[str, None] = '862e4eec12b9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """P7 会话/消息 HTTP 接口支持：

    1. messages 补 created_at（消息时间戳服务端权威，iOS ChatMessage.timestamp 消费）
    2. conversations.match_id 唯一约束（1 match 1 conversation）
    3. 回填存量 match 的 conversation（P5 建匹配时未建会话）
    """
    op.add_column(
        "messages",
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )
    op.create_unique_constraint(
        "uq_conversations_match_id", "conversations", ["match_id"]
    )
    op.execute(
        sa.text(
            """
            INSERT INTO conversations
                (id, match_id, user_a_id, user_b_id,
                 user_a_unread, user_b_unread, created_at, updated_at)
            SELECT gen_random_uuid(), m.id, m.user_a_id, m.user_b_id,
                   0, 0, m.created_at, m.created_at
            FROM matches m
            WHERE NOT EXISTS (SELECT 1 FROM conversations c WHERE c.match_id = m.id)
            """
        )
    )


def downgrade() -> None:
    op.drop_constraint("uq_conversations_match_id", "conversations", type_="unique")
    op.drop_column("messages", "created_at")
