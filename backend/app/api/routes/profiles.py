from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.goal import Goal
from app.models.user import User
from app.models.user_profile import UserProfile
from app.schemas.profile import GoalRead, ProfileUpsert, UserProfileRead

router = APIRouter(prefix="/profile", tags=["profile"])


@router.get("", response_model=UserProfileRead)
def get_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserProfileRead:
    profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
    if profile is None:
        return UserProfileRead(user_id=current_user.id)
    return profile


@router.put("", response_model=UserProfileRead)
def upsert_profile(
    payload: ProfileUpsert,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserProfileRead:
    profile = db.query(UserProfile).filter(UserProfile.user_id == current_user.id).first()
    if profile is None:
        profile = UserProfile(user_id=current_user.id)
        db.add(profile)

    for field, value in payload.profile.model_dump(exclude_unset=True).items():
        setattr(profile, field, value)

    if payload.goal is not None:
        goal = db.query(Goal).filter(Goal.user_id == current_user.id).first()
        if goal is None:
            goal = Goal(user_id=current_user.id)
            db.add(goal)
        for field, value in payload.goal.model_dump(exclude_unset=True).items():
            setattr(goal, field, value)

    db.commit()
    db.refresh(profile)
    return profile


@router.get("/goal", response_model=GoalRead | None)
def get_goal(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GoalRead | None:
    return db.query(Goal).filter(Goal.user_id == current_user.id).first()

