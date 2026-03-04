"""Create action_tokens table

Revision ID: 003
Revises: 002
Create Date: 2026-02-28 12:45:00
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "003"
down_revision = "002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "action_tokens",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("token_hash", sa.String(length=255), nullable=False, unique=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("email_id", sa.Integer(), sa.ForeignKey("emails.id"), nullable=False),
        sa.Column("action", sa.String(length=50), nullable=False),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("used_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("NOW()"), nullable=False),
    )
    op.create_index("ix_action_tokens_token_hash", "action_tokens", ["token_hash"], unique=True)
    op.create_index("ix_action_tokens_user_id", "action_tokens", ["user_id"], unique=False)
    op.create_index("ix_action_tokens_email_id", "action_tokens", ["email_id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_action_tokens_email_id", table_name="action_tokens")
    op.drop_index("ix_action_tokens_user_id", table_name="action_tokens")
    op.drop_index("ix_action_tokens_token_hash", table_name="action_tokens")
    op.drop_table("action_tokens")
