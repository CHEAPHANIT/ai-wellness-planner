from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Goal(Base):
    __tablename__ = "goals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    goal_type: Mapped[str] = mapped_column(String(60), default="maintain")
    target_weight_kg: Mapped[float | None] = mapped_column(Float, nullable=True)
    daily_calorie_target: Mapped[float | None] = mapped_column(Float, nullable=True)
    protein_target_g: Mapped[float | None] = mapped_column(Float, nullable=True)
    carbs_target_g: Mapped[float | None] = mapped_column(Float, nullable=True)
    fat_target_g: Mapped[float | None] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="goal")

