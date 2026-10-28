import uuid
from datetime import date, datetime
from typing import Self

from pydantic import AwareDatetime, BaseModel, ConfigDict, Field, model_validator


class SetResultIn(BaseModel):
    # No video, no landmarks: unknown fields are rejected rather than silently dropped.
    model_config = ConfigDict(extra="forbid")

    exercise_id: str = Field(min_length=1, max_length=64)
    reps: int | None = Field(default=None, ge=0, le=1000)
    clean_reps: int | None = Field(default=None, ge=0, le=1000)
    hold_seconds: int | None = Field(default=None, ge=0, le=3600)
    errors: dict[str, int] = Field(default_factory=dict, max_length=50)
    duration_seconds: int = Field(ge=0, le=3600)

    @model_validator(mode="after")
    def check_counts(self) -> Self:
        if self.clean_reps is not None and (self.reps is None or self.clean_reps > self.reps):
            raise ValueError("clean_reps must not exceed reps")
        for code, count in self.errors.items():
            if not code or len(code) > 64 or count < 0:
                raise ValueError("errors must map non-empty codes to non-negative counts")
        return self


class WorkoutCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    client_id: uuid.UUID | None = None
    plan_template_id: str | None = Field(default=None, max_length=64)
    started_at: AwareDatetime
    duration_seconds: int = Field(ge=0, le=6 * 3600)
    perceived_difficulty: int | None = Field(default=None, ge=1, le=10)
    sets: list[SetResultIn] = Field(min_length=1, max_length=200)


class SetResultRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    exercise_id: str
    reps: int | None
    clean_reps: int | None
    hold_seconds: int | None
    errors: dict[str, int]
    duration_seconds: int


class WorkoutRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    client_id: uuid.UUID | None
    plan_template_id: str | None
    started_at: datetime
    duration_seconds: int
    perceived_difficulty: int | None
    sets: list[SetResultRead]


class ExerciseWeekProgress(BaseModel):
    exercise_id: str
    week_start: date
    sessions: int
    sets: int
    total_reps: int
    clean_reps: int
    clean_ratio: float | None
    total_hold_seconds: int
    total_errors: int
    errors: dict[str, int]


class ProgressRead(BaseModel):
    weeks: int
    items: list[ExerciseWeekProgress]
