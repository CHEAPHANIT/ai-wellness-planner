from datetime import date

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.goal import Goal
from app.models.progress import WeightProgress
from app.models.user import User
from app.models.user_profile import UserProfile
from app.schemas.progress import WeightProgressCreate, WeightProgressRead, WeightProgressSummary

router = APIRouter(prefix="/progress", tags=["progress"])


@router.get("/weight", response_model=WeightProgressSummary)
def get_weight_progress(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> WeightProgressSummary:
    history = (
        db.query(WeightProgress)
        .filter(WeightProgress.user_id == current_user.id)
        .order_by(WeightProgress.recorded_date.asc())
        .all()
    )
    profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
    goal = db.query(Goal).filter(Goal.user_id == current_user.id).first()
    current_weight = history[-1].weight_kg if history else (profile.weight_kg if profile else None)
    start_weight = profile.weight_kg if profile and profile.weight_kg else (history[0].weight_kg if history else None)
    target_weight = goal.target_weight_kg if goal else None
    progress = 0.0
    if start_weight and current_weight and target_weight and start_weight != target_weight:
        progress = ((start_weight - current_weight) / (start_weight - target_weight)) * 100
    return WeightProgressSummary(
        current_weight=current_weight,
        start_weight=start_weight,
        target_weight=target_weight,
        progress_percentage=round(max(0, min(progress, 100)), 2),
        history=history,
    )


@router.post("/weight", response_model=WeightProgressRead, status_code=status.HTTP_201_CREATED)
def record_weight(
    payload: WeightProgressCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> WeightProgress:
    recorded_date = payload.recorded_date or date.today()
    entry = (
        db.query(WeightProgress)
        .filter(WeightProgress.user_id == current_user.id, WeightProgress.recorded_date == recorded_date)
        .first()
    )
    if entry is None:
        entry = WeightProgress(user_id=current_user.id, recorded_date=recorded_date)
        db.add(entry)
    entry.weight_kg = payload.weight_kg
    db.commit()
    db.refresh(entry)
    return entry
