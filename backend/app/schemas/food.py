from pydantic import BaseModel, Field


class FoodCreate(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    category: str = Field(min_length=2, max_length=80)
    serving_size: str = Field(min_length=1, max_length=80)
    calories: float = Field(ge=0)
    protein_g: float = Field(ge=0, default=0)
    carbs_g: float = Field(ge=0, default=0)
    fat_g: float = Field(ge=0, default=0)
    image_url: str | None = None
    tags: list[str] = []
    allergens: list[str] = []


class FoodRead(FoodCreate):
    id: int

    model_config = {"from_attributes": True}
