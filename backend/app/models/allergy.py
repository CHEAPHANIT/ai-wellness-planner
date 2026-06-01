from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Allergy(Base):
    __tablename__ = "allergies"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    ingredient: Mapped[str] = mapped_column(String(120), nullable=False, index=True)
    severity: Mapped[str | None] = mapped_column(String(40), nullable=True)

    user = relationship("User", back_populates="allergies")
