"""Add digest preferences to users

Revision ID: 007_add_digest_preferences
Revises: 006_add_email_body_columns
Create Date: 2026-03-05 21:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "007_add_digest_preferences"
down_revision: Union[str, None] = "006_add_email_body_columns"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("digest_enabled", sa.Boolean(), nullable=False, server_default=sa.text("true")),
    )
    op.add_column(
        "users",
        sa.Column("digest_time", sa.Time(), nullable=False, server_default=sa.text("'07:00:00'")),
    )
    op.add_column("users", sa.Column("last_digest_sent_at", sa.DateTime(), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "last_digest_sent_at")
    op.drop_column("users", "digest_time")
    op.drop_column("users", "digest_enabled")
