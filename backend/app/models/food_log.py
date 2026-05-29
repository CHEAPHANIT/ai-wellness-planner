from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class FoodLog(Base):
    __tablename__ = "food_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    food_id: Mapped[int] = mapped_column(ForeignKey("foods.id"), index=True)
    meal_type: Mapped[str] = mapped_column(String(40), default="meal")
    quantity: Mapped[float] = mapped_column(Float, default=1)
    notes: Mapped[str | None] = mapped_column(String(255), nullable=True)
    logged_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="food_logs")
    food = relationship("Food", back_populates="logs")

