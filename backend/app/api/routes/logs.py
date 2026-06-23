from datetime import date, datetime, time, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.food import Food
from app.models.food_log import FoodLog
from app.models.goal import Goal
from app.models.nutrition_log import NutritionLog
from app.models.water import WaterLog
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

    logged_at = datetime.now(timezone.utc)
    if payload.log_date is not None:
        logged_at = datetime.combine(payload.log_date, time(hour=12), tzinfo=timezone.utc)
    log = FoodLog(
        user_id=current_user.id,
        food_id=payload.food_id,
        meal_type=payload.meal_type,
        quantity=payload.quantity,
        notes=payload.notes,
        logged_at=logged_at,
    )
    db.add(log)
    db.flush()
    _update_daily_nutrition(db, current_user.id, log.logged_at.date())
    db.commit()
    db.refresh(log)
    return log


@router.delete("/food/{log_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_food_log(
    log_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    log = (
        db.query(FoodLog)
        .filter(FoodLog.id == log_id, FoodLog.user_id == current_user.id)
        .first()
    )
    if log is None:
        raise HTTPException(status_code=404, detail="Food log was not found")

    log_date = log.logged_at.date()
    db.delete(log)
    db.flush()
    _update_daily_nutrition(db, current_user.id, log_date)
    db.commit()


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
    goal = db.query(Goal).filter(Goal.user_id == current_user.id).first()
    water = db.query(WaterLog).filter(WaterLog.user_id == current_user.id, WaterLog.log_date == log_date).first()
    target = goal.daily_calorie_target if goal and goal.daily_calorie_target else None
    return NutritionSummary(
        log_date=summary.log_date,
        calories=summary.calories_total,
        protein_g=summary.protein_total_g,
        carbs_g=summary.carbs_total_g,
        fat_g=summary.fat_total_g,
        remaining_calories=round(target - summary.calories_total, 2) if target else None,
        nutrition_score=_nutrition_score(summary, target, water.amount_ml if water else 0, water.recommended_ml if water else 0),
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


def _nutrition_score(summary: NutritionLog, calorie_target: float | None, water_ml: float, water_target_ml: float) -> int:
    score = 40
    if calorie_target:
        calorie_gap = abs(summary.calories_total - calorie_target) / calorie_target
        score += max(0, round(25 * (1 - calorie_gap)))
    if summary.protein_total_g >= 60:
        score += 15
    elif summary.protein_total_g >= 30:
        score += 8
    if water_target_ml and water_ml:
        score += max(0, round(15 * min(water_ml / water_target_ml, 1)))
    if summary.carbs_total_g > 0 and summary.fat_total_g > 0 and summary.protein_total_g > 0:
        score += 5
    return min(100, max(0, score))
