"""initial schema

Revision ID: 0001
Revises:
Create Date: 2026-10-28 12:32:02.351463
"""
from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op


revision: str = '0001'
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table('users',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('email', sa.String(length=320), nullable=False),
    sa.Column('password_hash', sa.String(length=255), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    sa.Column('consent_version', sa.String(length=32), nullable=False),
    sa.Column('consent_accepted_at', sa.DateTime(timezone=True), nullable=False),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_users_email'), ['email'], unique=True)

    op.create_table('onboarding_profiles',
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('goals', sa.JSON(), nullable=False),
    sa.Column('experience', sa.String(length=32), nullable=False),
    sa.Column('days_per_week', sa.Integer(), nullable=False),
    sa.Column('minutes_per_session', sa.Integer(), nullable=False),
    sa.Column('sex', sa.String(length=16), nullable=False),
    sa.Column('age', sa.Integer(), nullable=False),
    sa.Column('height_cm', sa.Integer(), nullable=False),
    sa.Column('weight_kg', sa.Float(), nullable=True),
    sa.Column('screening_passed', sa.Boolean(), nullable=False),
    sa.Column('screening_passed_at', sa.DateTime(timezone=True), nullable=False),
    sa.Column('calibration', sa.JSON(), nullable=True),
    sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('user_id')
    )
    op.create_table('training_plans',
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('template_id', sa.String(length=64), nullable=False),
    sa.Column('title', sa.String(length=200), nullable=False),
    sa.Column('level', sa.String(length=16), nullable=False),
    sa.Column('weeks', sa.Integer(), nullable=False),
    sa.Column('sessions_per_week', sa.Integer(), nullable=False),
    sa.Column('minutes_per_session', sa.Integer(), nullable=False),
    sa.Column('starting_exercises', sa.JSON(), nullable=False),
    sa.Column('assigned_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('user_id')
    )
    op.create_table('workout_sessions',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('user_id', sa.Integer(), nullable=False),
    sa.Column('client_id', sa.Uuid(), nullable=True),
    sa.Column('plan_template_id', sa.String(length=64), nullable=True),
    sa.Column('started_at', sa.DateTime(timezone=True), nullable=False),
    sa.Column('duration_seconds', sa.Integer(), nullable=False),
    sa.Column('perceived_difficulty', sa.Integer(), nullable=True),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id'),
    sa.UniqueConstraint('user_id', 'client_id', name='uq_workout_user_client')
    )
    with op.batch_alter_table('workout_sessions', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_workout_sessions_started_at'), ['started_at'], unique=False)
        batch_op.create_index(batch_op.f('ix_workout_sessions_user_id'), ['user_id'], unique=False)

    op.create_table('set_results',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('session_id', sa.Integer(), nullable=False),
    sa.Column('position', sa.Integer(), nullable=False),
    sa.Column('exercise_id', sa.String(length=64), nullable=False),
    sa.Column('reps', sa.Integer(), nullable=True),
    sa.Column('clean_reps', sa.Integer(), nullable=True),
    sa.Column('hold_seconds', sa.Integer(), nullable=True),
    sa.Column('errors', sa.JSON(), nullable=False),
    sa.Column('duration_seconds', sa.Integer(), nullable=False),
    sa.ForeignKeyConstraint(['session_id'], ['workout_sessions.id'], ondelete='CASCADE'),
    sa.PrimaryKeyConstraint('id')
    )
    with op.batch_alter_table('set_results', schema=None) as batch_op:
        batch_op.create_index(batch_op.f('ix_set_results_exercise_id'), ['exercise_id'], unique=False)
        batch_op.create_index(batch_op.f('ix_set_results_session_id'), ['session_id'], unique=False)



def downgrade() -> None:
    with op.batch_alter_table('set_results', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_set_results_session_id'))
        batch_op.drop_index(batch_op.f('ix_set_results_exercise_id'))

    op.drop_table('set_results')
    with op.batch_alter_table('workout_sessions', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_workout_sessions_user_id'))
        batch_op.drop_index(batch_op.f('ix_workout_sessions_started_at'))

    op.drop_table('workout_sessions')
    op.drop_table('training_plans')
    op.drop_table('onboarding_profiles')
    with op.batch_alter_table('users', schema=None) as batch_op:
        batch_op.drop_index(batch_op.f('ix_users_email'))

    op.drop_table('users')
