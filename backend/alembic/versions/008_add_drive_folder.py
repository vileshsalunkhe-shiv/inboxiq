"""Add drive default folder id to users

Revision ID: 008_add_drive_folder
Revises: 007_add_digest_preferences
Create Date: 2026-03-05 18:40:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = "008_add_drive_folder"
down_revision: Union[str, None] = "007_add_digest_preferences"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("drive_default_folder_id", sa.String(length=255), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "drive_default_folder_id")
