from datetime import date, datetime, time, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.food import Food
from app.models.food_log import FoodLog
from app.models.nutrition_log import NutritionLog
from app.models.user import User
from app.schemas.logs import FoodLogCreate, FoodLogRead, NutritionSummary

router = APIRouter(prefix="/logs", tags=["logs"])


@router.get("/food", response_model=list[FoodLogRead])
def list_food_logs(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[FoodLogRead]:
    return (
        db.query(FoodLog)
        .filter(FoodLog.user_id == current_user.id)
        .order_by(FoodLog.logged_at.desc())
        .limit(100)
        .all()
    )


@router.post("/food", response_model=FoodLogRead, status_code=status.HTTP_201_CREATED)
def create_food_log(
    payload: FoodLogCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FoodLogRead:
    food = db.get(Food, payload.food_id)
    if food is None:
        raise HTTPException(status_code=404, detail="Food was not found")

    log = FoodLog(
        user_id=current_user.id,
        food_id=payload.food_id,
        meal_type=payload.meal_type,
        quantity=payload.quantity,
        notes=payload.notes,
        logged_at=datetime.now(timezone.utc),
    )
    db.add(log)
    db.flush()
    _update_daily_nutrition(db, current_user.id, log.logged_at.date())
    db.commit()
    db.refresh(log)
    return log


@router.get("/nutrition/{log_date}", response_model=NutritionSummary)
def get_nutrition_summary(
    log_date: date,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> NutritionSummary:
    _update_daily_nutrition(db, current_user.id, log_date)
    db.commit()
    summary = (
        db.query(NutritionLog)
        .filter(NutritionLog.user_id == current_user.id, NutritionLog.log_date == log_date)
        .first()
    )
    if summary is None:
        return NutritionSummary(log_date=log_date, calories=0, protein_g=0, carbs_g=0, fat_g=0)
    return NutritionSummary(
        log_date=summary.log_date,
        calories=summary.calories_total,
        protein_g=summary.protein_total_g,
        carbs_g=summary.carbs_total_g,
        fat_g=summary.fat_total_g,
    )


def _update_daily_nutrition(db: Session, user_id: int, log_date: date) -> None:
    logs = (
        db.query(FoodLog)
        .join(Food)
        .filter(FoodLog.user_id == user_id)
        .filter(FoodLog.logged_at >= datetime.combine(log_date, time.min, tzinfo=timezone.utc))
        .filter(FoodLog.logged_at < datetime.combine(log_date + timedelta(days=1), time.min, tzinfo=timezone.utc))
        .all()
    )
    calories = sum(log.food.calories * log.quantity for log in logs)
    protein = sum(log.food.protein_g * log.quantity for log in logs)
    carbs = sum(log.food.carbs_g * log.quantity for log in logs)
    fat = sum(log.food.fat_g * log.quantity for log in logs)

    summary = (
        db.query(NutritionLog)
        .filter(NutritionLog.user_id == user_id, NutritionLog.log_date == log_date)
        .first()
    )
    if summary is None:
        summary = NutritionLog(user_id=user_id, log_date=log_date)
        db.add(summary)
    summary.calories_total = round(calories, 2)
    summary.protein_total_g = round(protein, 2)
    summary.carbs_total_g = round(carbs, 2)
    summary.fat_total_g = round(fat, 2)
