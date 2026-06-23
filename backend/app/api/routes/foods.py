from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.food import Food
from app.models.food_favorite import FoodFavorite
from app.models.user import User
from app.schemas.food import FoodCreate, FoodFavoriteIds, FoodRead

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


@router.get("/favorites", response_model=FoodFavoriteIds)
def list_favorite_foods(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FoodFavoriteIds:
    rows = (
        db.query(FoodFavorite.food_id)
        .filter(FoodFavorite.user_id == current_user.id)
        .order_by(FoodFavorite.created_at.desc())
        .all()
    )
    return FoodFavoriteIds(food_ids=[row[0] for row in rows])


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


@router.post("/{food_id}/favorite", response_model=FoodFavoriteIds, status_code=status.HTTP_201_CREATED)
def add_favorite_food(
    food_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FoodFavoriteIds:
    if db.get(Food, food_id) is None:
        raise HTTPException(status_code=404, detail="Food was not found")

    existing = (
        db.query(FoodFavorite)
        .filter(FoodFavorite.user_id == current_user.id, FoodFavorite.food_id == food_id)
        .first()
    )
    if existing is None:
        db.add(FoodFavorite(user_id=current_user.id, food_id=food_id))
        db.commit()
    return list_favorite_foods(db, current_user)


@router.delete("/{food_id}/favorite", response_model=FoodFavoriteIds)
def remove_favorite_food(
    food_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> FoodFavoriteIds:
    favorite = (
        db.query(FoodFavorite)
        .filter(FoodFavorite.user_id == current_user.id, FoodFavorite.food_id == food_id)
        .first()
    )
    if favorite is not None:
        db.delete(favorite)
        db.commit()
    return list_favorite_foods(db, current_user)
