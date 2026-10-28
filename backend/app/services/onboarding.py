from datetime import UTC, datetime

from sqlalchemy.ext.asyncio import AsyncSession

from app.models import OnboardingProfile, TrainingPlan
from app.schemas.plan import PlanUpsert
from app.schemas.profile import ProfileUpsert


async def get_profile(db: AsyncSession, user_id: int) -> OnboardingProfile | None:
    return await db.get(OnboardingProfile, user_id)


async def upsert_profile(db: AsyncSession, user_id: int, payload: ProfileUpsert) -> OnboardingProfile:
    profile = await db.get(OnboardingProfile, user_id)
    data = payload.model_dump(mode="json")
    if profile is None:
        profile = OnboardingProfile(user_id=user_id, screening_passed_at=datetime.now(UTC), **data)
        db.add(profile)
    else:
        for field, value in data.items():
            setattr(profile, field, value)
    await db.commit()
    await db.refresh(profile)
    return profile


async def get_plan(db: AsyncSession, user_id: int) -> TrainingPlan | None:
    return await db.get(TrainingPlan, user_id)


async def upsert_plan(db: AsyncSession, user_id: int, payload: PlanUpsert) -> TrainingPlan:
    plan = await db.get(TrainingPlan, user_id)
    data = payload.model_dump(mode="json")
    if plan is None:
        plan = TrainingPlan(user_id=user_id, **data)
        db.add(plan)
    else:
        for field, value in data.items():
            setattr(plan, field, value)
    await db.commit()
    await db.refresh(plan)
    return plan
