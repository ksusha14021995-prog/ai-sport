"""Wire values mirror Dart enum `.name` in app/lib/domain/models/."""
from enum import StrEnum


class Goal(StrEnum):
    lose_weight = "loseWeight"
    gain_mass = "gainMass"
    get_stronger = "getStronger"
    endurance = "endurance"
    tone = "tone"


class Experience(StrEnum):
    none = "none"
    under_6_months = "under6Months"
    from_6_to_24_months = "from6To24Months"
    over_2_years = "over2Years"


class Sex(StrEnum):
    female = "female"
    male = "male"


class PushupVariant(StrEnum):
    floor = "floor"
    knees = "knees"


class PlanLevel(StrEnum):
    beginner = "beginner"
    intermediate = "intermediate"
    advanced = "advanced"
