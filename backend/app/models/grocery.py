from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class GroceryList(Base):
    __tablename__ = "grocery_lists"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(160), default="Weekly grocery list")
    estimated_total_cost: Mapped[float] = mapped_column(Float, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="grocery_lists")
    items = relationship("GroceryItem", back_populates="grocery_list", cascade="all, delete")


class GroceryItem(Base):
    __tablename__ = "grocery_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    grocery_list_id: Mapped[int] = mapped_column(ForeignKey("grocery_lists.id", ondelete="CASCADE"), index=True)
    food_item: Mapped[str] = mapped_column(String(160), nullable=False)
    quantity: Mapped[str] = mapped_column(String(80), nullable=False)
    estimated_cost: Mapped[float] = mapped_column(Float, default=0)
    purchased: Mapped[bool] = mapped_column(Boolean, default=False)

    grocery_list = relationship("GroceryList", back_populates="items")
