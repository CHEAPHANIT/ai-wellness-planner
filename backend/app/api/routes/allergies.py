from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.allergy import Allergy
from app.models.user import User
from app.schemas.allergy import AllergyCreate, AllergyRead

router = APIRouter(prefix="/allergies", tags=["allergies"])


@router.get("", response_model=list[AllergyRead])
def list_allergies(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[Allergy]:
    return db.query(Allergy).filter(Allergy.user_id == current_user.id).order_by(Allergy.ingredient.asc()).all()


@router.post("", response_model=AllergyRead, status_code=status.HTTP_201_CREATED)
def create_allergy(
    payload: AllergyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Allergy:
    allergy = Allergy(user_id=current_user.id, ingredient=payload.ingredient.lower(), severity=payload.severity)
    db.add(allergy)
    db.commit()
    db.refresh(allergy)
    return allergy


@router.delete("/{allergy_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_allergy(
    allergy_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> None:
    allergy = db.get(Allergy, allergy_id)
    if allergy is None or allergy.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Allergy was not found")
    db.delete(allergy)
    db.commit()
