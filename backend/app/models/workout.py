import uuid
from datetime import datetime

from sqlalchemy import JSON, DateTime, ForeignKey, Integer, String, UniqueConstraint, Uuid, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


class WorkoutSession(Base):
    __tablename__ = "workout_sessions"
    # Lets the phone retry an offline upload without creating duplicates.
    __table_args__ = (UniqueConstraint("user_id", "client_id", name="uq_workout_user_client"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    client_id: Mapped[uuid.UUID | None] = mapped_column(Uuid, nullable=True)
    plan_template_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    duration_seconds: Mapped[int] = mapped_column(Integer)
    perceived_difficulty: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    sets: Mapped[list["SetResult"]] = relationship(
        back_populates="session",
        cascade="all, delete-orphan",
        passive_deletes=True,
        order_by="SetResult.position",
        lazy="selectin",
    )


class SetResult(Base):
    __tablename__ = "set_results"

    id: Mapped[int] = mapped_column(primary_key=True)
    session_id: Mapped[int] = mapped_column(
        ForeignKey("workout_sessions.id", ondelete="CASCADE"), index=True
    )
    position: Mapped[int] = mapped_column(Integer)
    exercise_id: Mapped[str] = mapped_column(String(64), index=True)
    reps: Mapped[int | None] = mapped_column(Integer, nullable=True)
    clean_reps: Mapped[int | None] = mapped_column(Integer, nullable=True)
    hold_seconds: Mapped[int | None] = mapped_column(Integer, nullable=True)
    errors: Mapped[dict[str, int]] = mapped_column(JSON, default=dict)
    duration_seconds: Mapped[int] = mapped_column(Integer)

    session: Mapped[WorkoutSession] = relationship(back_populates="sets")
