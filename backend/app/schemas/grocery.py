from datetime import datetime

from pydantic import BaseModel, Field


class GroceryItemRead(BaseModel):
    id: int
    food_item: str
    quantity: str
    estimated_cost: float
    purchased: bool

    model_config = {"from_attributes": True}


class GroceryListRead(BaseModel):
    id: int
    name: str
    estimated_total_cost: float
    created_at: datetime
    items: list[GroceryItemRead] = []

    model_config = {"from_attributes": True}


class GroceryListGenerateRequest(BaseModel):
    meal_plan_id: int | None = None
    budget: float | None = Field(default=None, ge=0)


class GroceryItemUpdate(BaseModel):
    purchased: bool
