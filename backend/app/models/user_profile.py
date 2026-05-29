from sqlalchemy import Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class UserProfile(Base):
    __tablename__ = "user_profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    age: Mapped[int | None] = mapped_column(Integer, nullable=True)
    gender: Mapped[str | None] = mapped_column(String(40), nullable=True)
    height_cm: Mapped[float | None] = mapped_column(Float, nullable=True)
    weight_kg: Mapped[float | None] = mapped_column(Float, nullable=True)
    activity_level: Mapped[str | None] = mapped_column(String(80), nullable=True)
    food_preference: Mapped[str | None] = mapped_column(String(120), nullable=True)
    exercise_frequency: Mapped[str | None] = mapped_column(String(80), nullable=True)
    eating_habits: Mapped[str | None] = mapped_column(String(120), nullable=True)

    user = relationship("User", back_populates="profile")

