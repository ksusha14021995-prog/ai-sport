from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.enums import Experience, Goal, PushupVariant, Sex


class Calibration(BaseModel):
    model_config = ConfigDict(extra="forbid")

    squat_reps: int = Field(ge=0, le=1000)
    squat_errors: int = Field(ge=0, le=1000)
    pushup_reps: int = Field(ge=0, le=1000)
    pushup_variant: PushupVariant
    plank_seconds: int = Field(ge=0, le=3600)
    plank_errors: int = Field(ge=0, le=1000)
    perceived_difficulty: int = Field(ge=1, le=10)


class ProfileUpsert(BaseModel):
    # extra="forbid" is what keeps raw screening answers (special-category health data)
    # out of the server: a client that sends them gets 422 and nothing is stored.
    model_config = ConfigDict(extra="forbid")

    goals: list[Goal] = Field(min_length=1)
    experience: Experience
    days_per_week: Literal[2, 3, 4, 5]
    minutes_per_session: Literal[15, 30, 45, 60]
    sex: Sex
    age: int = Field(ge=18, le=100)
    height_cm: int = Field(ge=100, le=250)
    weight_kg: float | None = Field(default=None, ge=30, le=300)
    # A failed screening means no plan and no account data in MVP, so only `true` is accepted.
    screening_passed: Literal[True]
    calibration: Calibration | None = None


class ProfileRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    goals: list[Goal]
    experience: Experience
    days_per_week: int
    minutes_per_session: int
    sex: Sex
    age: int
    height_cm: int
    weight_kg: float | None
    screening_passed: bool
    screening_passed_at: datetime
    calibration: Calibration | None
    updated_at: datetime
