from datetime import date, datetime

from sqlalchemy import Date, DateTime, Float, ForeignKey, Integer, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class NutritionLog(Base):
    __tablename__ = "nutrition_logs"
    __table_args__ = (UniqueConstraint("user_id", "log_date", name="uq_nutrition_user_date"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    log_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    calories_total: Mapped[float] = mapped_column(Float, default=0)
    protein_total_g: Mapped[float] = mapped_column(Float, default=0)
    carbs_total_g: Mapped[float] = mapped_column(Float, default=0)
    fat_total_g: Mapped[float] = mapped_column(Float, default=0)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    user = relationship("User", back_populates="nutrition_logs")

