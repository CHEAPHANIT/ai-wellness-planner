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
        .order_by(MealPlan.plan_date.desc(), MealPlan.created_at.desc())
        .limit(30)
        .all()
    )


@router.post("/generate", response_model=MealPlanRead, status_code=status.HTTP_201_CREATED)
def generate_meal_plan(
    payload: MealPlanCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> MealPlanRead:
    plan_date = payload.plan_date or date.today()
    recommendation = MealRecommendationService(db).recommend(
        payload.recommendation_request,
        rotation_offset=plan_date.toordinal(),
    )
    plan = (
        db.query(MealPlan)
        .filter(MealPlan.user_id == current_user.id, MealPlan.plan_date == plan_date)
        .order_by(MealPlan.created_at.desc())
        .first()
    )
    if plan is None:
        plan = MealPlan(user_id=current_user.id, plan_date=plan_date)
        db.add(plan)
    plan.daily_calories = recommendation.daily_calorie_target
    plan.plan_json = recommendation.model_dump()
    db.commit()
    db.refresh(plan)
    return plan


@router.post("/generate-weekly", response_model=list[MealPlanRead], status_code=status.HTTP_201_CREATED)
def generate_weekly_meal_plan(
    payload: MealPlanCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[MealPlan]:
    start_date = payload.plan_date or date.today()
    created: list[MealPlan] = []
    for offset in range(7):
        request = payload.recommendation_request.model_copy(update={"days": 1})
        plan_date = start_date.fromordinal(start_date.toordinal() + offset)
        recommendation = MealRecommendationService(db).recommend(
            request,
            rotation_offset=plan_date.toordinal(),
        )
        plan = (
            db.query(MealPlan)
            .filter(MealPlan.user_id == current_user.id, MealPlan.plan_date == plan_date)
            .order_by(MealPlan.created_at.desc())
            .first()
        )
        if plan is None:
            plan = MealPlan(user_id=current_user.id, plan_date=plan_date)
            db.add(plan)
        plan.daily_calories = recommendation.daily_calorie_target
        plan.plan_json = recommendation.model_dump()
        created.append(plan)
    db.commit()
    for plan in created:
        db.refresh(plan)
    return created
