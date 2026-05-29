from datetime import date

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.meal_plan import MealPlan
from app.models.user import User
from app.schemas.meal_plan import MealPlanCreate, MealPlanRead
from app.services.meal_recommender import MealRecommendationService

router = APIRouter(prefix="/meal-plans", tags=["meal-plans"])


@router.get("", response_model=list[MealPlanRead])
def list_meal_plans(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[MealPlanRead]:
    return (
        db.query(MealPlan)
        .filter(MealPlan.user_id == current_user.id)
        .order_by(MealPlan.plan_date.desc())
        .limit(30)
        .all()
    )


@router.post("/generate", response_model=MealPlanRead, status_code=status.HTTP_201_CREATED)
def generate_meal_plan(
    payload: MealPlanCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> MealPlanRead:
    recommendation = MealRecommendationService(db).recommend(payload.recommendation_request)
    plan = MealPlan(
        user_id=current_user.id,
        plan_date=payload.plan_date or date.today(),
        daily_calories=recommendation.daily_calorie_target,
        plan_json=recommendation.model_dump(),
    )
    db.add(plan)
    db.commit()
    db.refresh(plan)
    return plan

