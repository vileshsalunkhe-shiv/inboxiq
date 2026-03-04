"""Add calendar OAuth tokens to users table

Revision ID: 004
Revises: 003
Create Date: 2026-03-02 22:05:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '004'
down_revision = '003'
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Add calendar token columns to users table."""
    op.add_column('users', sa.Column('calendar_access_token', sa.Text(), nullable=True))
    op.add_column('users', sa.Column('calendar_refresh_token', sa.Text(), nullable=True))
    op.add_column('users', sa.Column('calendar_token_expiry', sa.DateTime(), nullable=True))


def downgrade() -> None:
    """Remove calendar token columns from users table."""
    op.drop_column('users', 'calendar_token_expiry')
    op.drop_column('users', 'calendar_refresh_token')
    op.drop_column('users', 'calendar_access_token')
