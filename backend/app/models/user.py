from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String(160), nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    reset_otp: Mapped[str | None] = mapped_column(String(12), nullable=True)
    otp_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    profile = relationship("UserProfile", back_populates="user", uselist=False, cascade="all, delete")
    goal = relationship("Goal", back_populates="user", uselist=False, cascade="all, delete")
    meal_plans = relationship("MealPlan", back_populates="user", cascade="all, delete")
    food_logs = relationship("FoodLog", back_populates="user", cascade="all, delete")
    nutrition_logs = relationship("NutritionLog", back_populates="user", cascade="all, delete")
    grocery_lists = relationship("GroceryList", back_populates="user", cascade="all, delete")
    weight_progress = relationship("WeightProgress", back_populates="user", cascade="all, delete")
    water_logs = relationship("WaterLog", back_populates="user", cascade="all, delete")
    chatbot_messages = relationship("ChatbotMessage", back_populates="user", cascade="all, delete")
    allergies = relationship("Allergy", back_populates="user", cascade="all, delete")
    health_risk_predictions = relationship("HealthRiskPrediction", back_populates="user", cascade="all, delete")
    food_favorites = relationship("FoodFavorite", back_populates="user", cascade="all, delete")
