"""device tokens for apns push

Revision ID: c7a1e9f04b52
Revises: a3f8c2d91b47
Create Date: 2026-10-12 16:23:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c7a1e9f04b52'
down_revision: Union[str, None] = 'a3f8c2d91b47'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """P13 APNs 离线推送：新增 device_tokens 表。

    token 全局唯一（同一设备换账号登录时 upsert 改绑 user_id，
    保证推送只发给当前持有该设备的一方）。
    """
    op.create_table(
        'device_tokens',
        sa.Column('id', sa.Uuid(), server_default=sa.text('gen_random_uuid()'), nullable=False),
        sa.Column('user_id', sa.Uuid(), nullable=False),
        sa.Column('token', sa.String(length=200), nullable=False),
        sa.Column('platform', sa.String(length=10), server_default='ios', nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], name=op.f('fk_device_tokens_user_id_users'), ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id', name=op.f('pk_device_tokens')),
    )
    op.create_index(op.f('ix_device_tokens_user_id'), 'device_tokens', ['user_id'])
    op.create_index(op.f('ix_device_tokens_token'), 'device_tokens', ['token'], unique=True)


def downgrade() -> None:
    op.drop_index(op.f('ix_device_tokens_token'), table_name='device_tokens')
    op.drop_index(op.f('ix_device_tokens_user_id'), table_name='device_tokens')
    op.drop_table('device_tokens')
