from pydantic import BaseModel, Field


class AllergyCreate(BaseModel):
    ingredient: str = Field(min_length=2, max_length=120)
    severity: str | None = Field(default=None, max_length=40)


class AllergyRead(AllergyCreate):
    id: int

    model_config = {"from_attributes": True}
