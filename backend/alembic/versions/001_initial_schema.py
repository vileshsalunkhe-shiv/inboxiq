"""Initial schema

Revision ID: 001
Revises: 
Create Date: 2026-02-27 18:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '001'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create users table
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('email', sa.String(255), unique=True, nullable=False, index=True),
        sa.Column('google_refresh_token', sa.Text(), nullable=True),
        sa.Column('last_history_id', sa.String(255), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
        sa.Column('last_sync', sa.DateTime(), nullable=True),
    )

    # Create categories table
    op.create_table(
        'categories',
        sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column('name', sa.String(50), unique=True, nullable=False),
        sa.Column('color', sa.String(7), nullable=True),
        sa.Column('icon', sa.String(50), nullable=True),
        sa.Column('description', sa.String(255), nullable=True),
    )

    # Create emails table
    op.create_table(
        'emails',
        sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('gmail_id', sa.String(255), unique=True, nullable=False, index=True),
        sa.Column('subject', sa.String(500), nullable=True),
        sa.Column('sender', sa.String(255), nullable=True, index=True),
        sa.Column('snippet', sa.Text(), nullable=True),
        sa.Column('body', sa.Text(), nullable=True),
        sa.Column('received_at', sa.DateTime(), nullable=False, index=True),
        sa.Column('category', sa.String(50), nullable=True, index=True),
        sa.Column('is_unread', sa.Boolean(), default=True, nullable=False),
        sa.Column('is_archived', sa.Boolean(), default=False, nullable=False),
        sa.Column('synced_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    )

    # Create ai_queue table
    op.create_table(
        'ai_queue',
        sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column('email_id', sa.Integer(), sa.ForeignKey('emails.id', ondelete='CASCADE'), nullable=False, unique=True, index=True),
        sa.Column('status', sa.String(20), default='pending', nullable=False, index=True),
        sa.Column('attempts', sa.Integer(), default=0, nullable=False),
        sa.Column('error_message', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
        sa.Column('processed_at', sa.DateTime(), nullable=True),
    )

    # Create refresh_tokens table
    op.create_table(
        'refresh_tokens',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('token_hash', sa.String(255), unique=True, nullable=False, index=True),
        sa.Column('expires_at', sa.DateTime(), nullable=False, index=True),
        sa.Column('revoked', sa.Boolean(), default=False, nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    )

    # Create digest_settings table
    op.create_table(
        'digest_settings',
        sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), unique=True, nullable=False, index=True),
        sa.Column('enabled', sa.Boolean(), default=False, nullable=False),
        sa.Column('frequency_hours', sa.Integer(), default=12, nullable=False),
        sa.Column('last_sent_at', sa.DateTime(), nullable=True),
    )

    # Create default categories
    op.execute("""
        INSERT INTO categories (name, color, icon, description) VALUES
        ('Primary', '#1a73e8', 'inbox', 'Important personal emails'),
        ('Social', '#ea4335', 'people', 'Social network notifications'),
        ('Promotions', '#34a853', 'local_offer', 'Deals and marketing'),
        ('Updates', '#fbbc04', 'info', 'Confirmations and receipts'),
        ('Forums', '#9334e6', 'forum', 'Mailing lists and groups')
    """)


def downgrade() -> None:
    op.drop_table('digest_settings')
    op.drop_table('refresh_tokens')
    op.drop_table('ai_queue')
    op.drop_table('emails')
    op.drop_table('categories')
    op.drop_table('users')
