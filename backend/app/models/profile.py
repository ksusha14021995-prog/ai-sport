from datetime import datetime

from sqlalchemy import JSON, Boolean, DateTime, Float, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class OnboardingProfile(Base):
    __tablename__ = "onboarding_profiles"

    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    goals: Mapped[list[str]] = mapped_column(JSON)
    experience: Mapped[str] = mapped_column(String(32))
    days_per_week: Mapped[int] = mapped_column(Integer)
    minutes_per_session: Mapped[int] = mapped_column(Integer)
    sex: Mapped[str] = mapped_column(String(16))
    age: Mapped[int] = mapped_column(Integer)
    height_cm: Mapped[int] = mapped_column(Integer)
    weight_kg: Mapped[float | None] = mapped_column(Float, nullable=True)
    # Only the screening outcome is stored; individual answers never leave the phone.
    screening_passed: Mapped[bool] = mapped_column(Boolean)
    screening_passed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    calibration: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
