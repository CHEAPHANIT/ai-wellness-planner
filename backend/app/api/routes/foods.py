from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.food import Food
from app.models.user import User
from app.schemas.food import FoodCreate, FoodRead

router = APIRouter(prefix="/foods", tags=["foods"])


@router.get("", response_model=list[FoodRead])
def list_foods(
    search: str | None = Query(default=None),
    category: str | None = Query(default=None),
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
) -> list[FoodRead]:
    query = db.query(Food)
    if search:
        term = f"%{search.lower()}%"
        query = query.filter(or_(Food.name.ilike(term), Food.category.ilike(term)))
    if category:
        query = query.filter(Food.category == category)
    return query.order_by(Food.name.asc()).limit(100).all()


@router.post("", response_model=FoodRead, status_code=status.HTTP_201_CREATED)
def create_food(
    payload: FoodCreate,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
) -> FoodRead:
    food = Food(**payload.model_dump())
    db.add(food)
    db.commit()
    db.refresh(food)
    return food

