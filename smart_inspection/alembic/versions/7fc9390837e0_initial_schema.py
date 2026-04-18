"""initial_schema

Revision ID: 7fc9390837e0
Revises:
Create Date: 2026-04-18 17:45:33.706274

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = '7fc9390837e0'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

userrole = sa.Enum('admin', 'inspector', 'viewer', name='userrole')
sitestatus = sa.Enum('active', 'completed', 'paused', name='sitestatus')
inspectionstatus = sa.Enum('pass', 'fail', 'pending', name='inspectionstatus')
defectseverity = sa.Enum('critical', 'major', 'minor', name='defectseverity')


def upgrade() -> None:
    op.create_table(
        'users',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('email', sa.String(200), nullable=False, unique=True),
        sa.Column('hashed_password', sa.String(255), nullable=False),
        sa.Column('role', userrole, nullable=False, server_default='inspector'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    )
    op.create_index('ix_users_email', 'users', ['email'], unique=True)

    op.create_table(
        'sites',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('name', sa.String(200), nullable=False),
        sa.Column('address', sa.Text, nullable=False),
        sa.Column('lat', sa.DECIMAL(10, 8), nullable=True),
        sa.Column('lng', sa.DECIMAL(11, 8), nullable=True),
        sa.Column('status', sitestatus, nullable=False, server_default='active'),
        sa.Column('start_date', sa.DateTime(timezone=True), nullable=True),
        sa.Column('end_date', sa.DateTime(timezone=True), nullable=True),
        sa.Column('manager_id', sa.String(36), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    )

    op.create_table(
        'inspections',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('site_id', sa.String(36), sa.ForeignKey('sites.id'), nullable=False),
        sa.Column('inspector_id', sa.String(36), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('category', sa.String(100), nullable=False),
        sa.Column('status', inspectionstatus, nullable=False, server_default='pending'),
        sa.Column('memo', sa.Text, nullable=True),
        sa.Column('location_lat', sa.DECIMAL(10, 8), nullable=True),
        sa.Column('location_lng', sa.DECIMAL(11, 8), nullable=True),
        sa.Column('inspected_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
        sa.Column('is_synced', sa.Boolean, nullable=False, server_default=sa.text('true')),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    )
    op.create_index('ix_inspections_site_id', 'inspections', ['site_id'])
    op.create_index('idx_inspections_site_id', 'inspections', ['site_id', 'inspected_at'])

    op.create_table(
        'inspection_photos',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('inspection_id', sa.String(36), sa.ForeignKey('inspections.id'), nullable=False),
        sa.Column('s3_key', sa.String(500), nullable=False),
        sa.Column('ocr_result', sa.Text, nullable=True),
        sa.Column('taken_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    )

    op.create_table(
        'defects',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('inspection_id', sa.String(36), sa.ForeignKey('inspections.id'), nullable=False),
        sa.Column('severity', defectseverity, nullable=False),
        sa.Column('description', sa.Text, nullable=False),
        sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('resolved_by_id', sa.String(36), sa.ForeignKey('users.id'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()')),
    )
    op.create_index('ix_defects_inspection_id', 'defects', ['inspection_id'])


def downgrade() -> None:
    op.drop_table('defects')
    op.drop_table('inspection_photos')
    op.drop_table('inspections')
    op.drop_table('sites')
    op.drop_table('users')
    defectseverity.drop(op.get_bind())
    inspectionstatus.drop(op.get_bind())
    sitestatus.drop(op.get_bind())
    userrole.drop(op.get_bind())
