from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, Response, status

from app.api.deps import CurrentUser, DbSession
from app.schemas.auth import UserRead
from app.schemas.plan import PlanRead, PlanUpsert
from app.schemas.profile import ProfileRead, ProfileUpsert
from app.schemas.workout import ProgressRead, WorkoutCreate, WorkoutRead
from app.services import onboarding, users, workouts

router = APIRouter(prefix="/me", tags=["me"])


@router.get("", response_model=UserRead)
async def read_me(user: CurrentUser) -> UserRead:
    return UserRead.model_validate(user)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def delete_me(user: CurrentUser, db: DbSession) -> Response:
    await users.delete_user(db, user.id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/profile", response_model=ProfileRead)
async def read_profile(user: CurrentUser, db: DbSession):
    profile = await onboarding.get_profile(db, user.id)
    if profile is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="Profile not filled yet")
    return profile


@router.put("/profile", response_model=ProfileRead)
async def put_profile(payload: ProfileUpsert, user: CurrentUser, db: DbSession):
    return await onboarding.upsert_profile(db, user.id, payload)


@router.get("/plan", response_model=PlanRead)
async def read_plan(user: CurrentUser, db: DbSession):
    plan = await onboarding.get_plan(db, user.id)
    if plan is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, detail="No plan assigned")
    return plan


@router.put("/plan", response_model=PlanRead)
async def put_plan(payload: PlanUpsert, user: CurrentUser, db: DbSession):
    profile = await onboarding.get_profile(db, user.id)
    if profile is None or not profile.screening_passed:
        raise HTTPException(status.HTTP_409_CONFLICT, detail="Profile with passed screening is required")
    return await onboarding.upsert_plan(db, user.id, payload)


@router.post("/workouts", response_model=WorkoutRead, status_code=status.HTTP_201_CREATED)
async def create_workout(payload: WorkoutCreate, user: CurrentUser, db: DbSession, response: Response):
    workout, created = await workouts.create_workout(db, user.id, payload)
    if not created:
        response.status_code = status.HTTP_200_OK
    return workout


@router.get("/workouts", response_model=list[WorkoutRead])
async def list_workouts(
    user: CurrentUser, db: DbSession, limit: Annotated[int, Query(ge=1, le=100)] = 20
):
    return await workouts.list_workouts(db, user.id, limit)


@router.get("/progress", response_model=ProgressRead)
async def read_progress(
    user: CurrentUser, db: DbSession, weeks: Annotated[int, Query(ge=1, le=52)] = 12
) -> ProgressRead:
    items = await workouts.weekly_progress(db, user.id, weeks)
    return ProgressRead(weeks=weeks, items=items)
