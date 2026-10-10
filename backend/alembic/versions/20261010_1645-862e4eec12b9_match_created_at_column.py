"""match created_at column

Revision ID: 862e4eec12b9
Revises: 77ec9d7b3c2a
Create Date: 2026-10-10 16:45:55.413531
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '862e4eec12b9'
down_revision: Union[str, None] = '77ec9d7b3c2a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """matches 增加匹配建立时间（列表倒序 + 游标分页；存量行回填 now()）"""
    op.add_column(
        "matches",
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )


def downgrade() -> None:
    op.drop_column("matches", "created_at")
