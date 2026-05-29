from datetime import date, datetime

from pydantic import BaseModel

from app.schemas.ai import MealRecommendationRequest, MealRecommendationResponse


class MealPlanCreate(BaseModel):
    plan_date: date | None = None
    recommendation_request: MealRecommendationRequest


class MealPlanRead(BaseModel):
    id: int
    plan_date: date
    daily_calories: float
    plan_json: MealRecommendationResponse
    created_at: datetime

    model_config = {"from_attributes": True}

