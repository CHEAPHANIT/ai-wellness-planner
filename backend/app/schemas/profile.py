from pydantic import BaseModel, Field


class ProfileBase(BaseModel):
    age: int | None = Field(default=None, ge=1, le=120)
    gender: str | None = None
    height_cm: float | None = Field(default=None, gt=50, lt=260)
    weight_kg: float | None = Field(default=None, gt=20, lt=400)
    activity_level: str | None = None
    food_preference: str | None = None
    exercise_frequency: str | None = None
    eating_habits: str | None = None


class GoalBase(BaseModel):
    goal_type: str | None = None
    target_weight_kg: float | None = None
    daily_calorie_target: float | None = None
    protein_target_g: float | None = None
    carbs_target_g: float | None = None
    fat_target_g: float | None = None


class ProfileUpsert(BaseModel):
    profile: ProfileBase
    goal: GoalBase | None = None


class UserProfileRead(ProfileBase):
    user_id: int

    model_config = {"from_attributes": True}


class GoalRead(GoalBase):
    user_id: int

    model_config = {"from_attributes": True}

