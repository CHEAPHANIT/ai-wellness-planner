from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class FoodFavorite(Base):
    __tablename__ = "food_favorites"
    __table_args__ = (UniqueConstraint("user_id", "food_id", name="uq_user_food_favorite"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    food_id: Mapped[int] = mapped_column(ForeignKey("foods.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="food_favorites")
    food = relationship("Food", back_populates="favorites")
