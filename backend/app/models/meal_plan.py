from datetime import date, datetime

from sqlalchemy import JSON, Date, DateTime, Float, ForeignKey, Integer, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class MealPlan(Base):
    __tablename__ = "meal_plans"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    plan_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    daily_calories: Mapped[float] = mapped_column(Float, nullable=False)
    plan_json: Mapped[dict] = mapped_column(JSON, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="meal_plans")

