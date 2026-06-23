from datetime import date, timedelta

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.models.user_profile import UserProfile
from app.models.water import WaterLog
from app.schemas.water import WaterLogCreate, WaterLogRead

router = APIRouter(prefix="/water", tags=["water"])


@router.get("", response_model=list[WaterLogRead])
def list_water_logs(
    days: int = 7,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[WaterLog]:
    days = max(1, min(days, 31))
    start_date = date.today() - timedelta(days=days - 1)
    return (
        db.query(WaterLog)
        .filter(WaterLog.user_id == current_user.id, WaterLog.log_date >= start_date)
        .order_by(WaterLog.log_date.asc())
        .all()
    )


@router.get("/{log_date}", response_model=WaterLogRead)
def get_water_log(
    log_date: date,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> WaterLog:
    log = db.query(WaterLog).filter(WaterLog.user_id == current_user.id, WaterLog.log_date == log_date).first()
    if log is None:
        log = WaterLog(user_id=current_user.id, log_date=log_date, recommended_ml=_recommended_water_ml(db, current_user.id))
        db.add(log)
        db.commit()
        db.refresh(log)
    return log


@router.post("", response_model=WaterLogRead, status_code=status.HTTP_201_CREATED)
def log_water(
    payload: WaterLogCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> WaterLog:
    log_date = payload.log_date or date.today()
    log = db.query(WaterLog).filter(WaterLog.user_id == current_user.id, WaterLog.log_date == log_date).first()
    if log is None:
        log = WaterLog(user_id=current_user.id, log_date=log_date)
        db.add(log)
    log.amount_ml = payload.amount_ml
    log.recommended_ml = _recommended_water_ml(db, current_user.id)
    db.commit()
    db.refresh(log)
    return log


def _recommended_water_ml(db: Session, user_id: int) -> float:
    profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    if profile and profile.weight_kg:
        return round(profile.weight_kg * 35)
    return 2500
