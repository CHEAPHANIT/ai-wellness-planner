from datetime import date

from pydantic import BaseModel, Field


class WaterLogCreate(BaseModel):
    log_date: date | None = None
    amount_ml: float = Field(ge=0, le=10000)


class WaterLogRead(BaseModel):
    id: int
    log_date: date
    amount_ml: float
    recommended_ml: float

    model_config = {"from_attributes": True}
