"""Update digest_settings table with missing columns

Revision ID: 002
Revises: 001
Create Date: 2026-02-28 12:25:00
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add missing columns to digest_settings
    op.add_column('digest_settings', sa.Column('preferred_time', sa.Time(), nullable=True))
    op.add_column('digest_settings', sa.Column('timezone', sa.String(50), server_default='America/Chicago', nullable=False))
    op.add_column('digest_settings', sa.Column('include_action_items', sa.Boolean(), server_default='true', nullable=False))
    op.add_column('digest_settings', sa.Column('include_summaries', sa.Boolean(), server_default='true', nullable=False))
    op.add_column('digest_settings', sa.Column('created_at', sa.DateTime(), server_default=sa.text('NOW()'), nullable=False))
    op.add_column('digest_settings', sa.Column('updated_at', sa.DateTime(), server_default=sa.text('NOW()'), nullable=False))
    
    # Drop id column (user_id should be primary key)
    op.drop_column('digest_settings', 'id')
    
    # Make user_id the primary key
    op.create_primary_key('digest_settings_pkey', 'digest_settings', ['user_id'])


def downgrade() -> None:
    # Reverse changes
    op.drop_constraint('digest_settings_pkey', 'digest_settings', type_='primary')
    op.add_column('digest_settings', sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True))
    op.drop_column('digest_settings', 'updated_at')
    op.drop_column('digest_settings', 'created_at')
    op.drop_column('digest_settings', 'include_summaries')
    op.drop_column('digest_settings', 'include_action_items')
    op.drop_column('digest_settings', 'timezone')
    op.drop_column('digest_settings', 'preferred_time')
