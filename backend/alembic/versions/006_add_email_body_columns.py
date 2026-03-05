"""Add email body cache columns

Revision ID: 006_add_email_body_columns
Revises: 005_add_email_categories
Create Date: 2026-03-05 19:20:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "006_add_email_body_columns"
down_revision: Union[str, None] = "005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("emails", sa.Column("body_text", sa.Text(), nullable=True))
    op.add_column("emails", sa.Column("body_html", sa.Text(), nullable=True))
    op.add_column("emails", sa.Column("body_fetched_at", sa.DateTime(), nullable=True))
    op.add_column(
        "emails",
        sa.Column("has_attachments", sa.Boolean(), nullable=False, server_default=sa.text("false")),
    )


def downgrade() -> None:
    op.drop_column("emails", "has_attachments")
    op.drop_column("emails", "body_fetched_at")
    op.drop_column("emails", "body_html")
    op.drop_column("emails", "body_text")
