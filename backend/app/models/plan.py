from datetime import datetime

from sqlalchemy import JSON, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class TrainingPlan(Base):
    """Currently assigned plan; one per user, PUT replaces it."""

    __tablename__ = "training_plans"

    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    template_id: Mapped[str] = mapped_column(String(64))
    title: Mapped[str] = mapped_column(String(200))
    level: Mapped[str] = mapped_column(String(16))
    weeks: Mapped[int] = mapped_column(Integer)
    sessions_per_week: Mapped[int] = mapped_column(Integer)
    minutes_per_session: Mapped[int] = mapped_column(Integer)
    starting_exercises: Mapped[list[dict]] = mapped_column(JSON)
    assigned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
