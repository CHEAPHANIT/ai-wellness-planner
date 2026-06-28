from datetime import date

from pydantic import BaseModel, Field


class WeightProgressCreate(BaseModel):
    recorded_date: date | None = None
    weight_kg: float = Field(gt=20, lt=400)


class WeightProgressRead(BaseModel):
    id: int
    recorded_date: date
    weight_kg: float

    model_config = {"from_attributes": True}


class WeightProgressSummary(BaseModel):
    current_weight: float | None
    start_weight: float | None
    target_weight: float | None
    progress_percentage: float
    history: list[WeightProgressRead]
