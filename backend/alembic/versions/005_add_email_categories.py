"""Add AI email categorization fields

Revision ID: 005
Revises: 004
Create Date: 2026-03-03 21:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "005"
down_revision: Union[str, None] = "004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # category column already exists, only add AI fields
    op.add_column("emails", sa.Column("ai_summary", sa.Text(), nullable=True))
    op.add_column("emails", sa.Column("ai_confidence", sa.Float(), nullable=True))


def downgrade() -> None:
    op.drop_column("emails", "ai_confidence")
    op.drop_column("emails", "ai_summary")
