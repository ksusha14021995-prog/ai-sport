from datetime import datetime
from typing import Self

from pydantic import BaseModel, ConfigDict, Field, model_validator

from app.schemas.enums import PlanLevel


class PlanExercise(BaseModel):
    model_config = ConfigDict(extra="forbid")

    exercise_id: str = Field(min_length=1, max_length=64)
    title: str = Field(min_length=1, max_length=200)
    sets: int = Field(ge=1, le=20)
    reps: int | None = Field(default=None, ge=1, le=1000)
    hold_seconds: int | None = Field(default=None, ge=1, le=3600)

    @model_validator(mode="after")
    def reps_xor_hold(self) -> Self:
        if (self.reps is None) == (self.hold_seconds is None):
            raise ValueError("exactly one of reps / hold_seconds must be set")
        return self


class PlanUpsert(BaseModel):
    model_config = ConfigDict(extra="forbid")

    template_id: str = Field(min_length=1, max_length=64)
    title: str = Field(min_length=1, max_length=200)
    level: PlanLevel
    weeks: int = Field(ge=1, le=52)
    sessions_per_week: int = Field(ge=1, le=7)
    minutes_per_session: int = Field(ge=5, le=180)
    starting_exercises: list[PlanExercise] = Field(min_length=1, max_length=50)


class PlanRead(PlanUpsert):
    model_config = ConfigDict(from_attributes=True)

    assigned_at: datetime
