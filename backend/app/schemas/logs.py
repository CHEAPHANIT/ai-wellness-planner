from datetime import date, datetime

from pydantic import BaseModel, Field

from app.schemas.food import FoodRead


class FoodLogCreate(BaseModel):
    food_id: int
    meal_type: str = Field(default="meal", max_length=40)
    quantity: float = Field(default=1, gt=0, le=20)
    notes: str | None = Field(default=None, max_length=255)


class FoodLogRead(BaseModel):
    id: int
    meal_type: str
    quantity: float
    notes: str | None
    logged_at: datetime
    food: FoodRead

    model_config = {"from_attributes": True}


class NutritionSummary(BaseModel):
    log_date: date
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float
    remaining_calories: float | None = None
    nutrition_score: int | None = None
