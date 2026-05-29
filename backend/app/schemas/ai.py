from pydantic import BaseModel, Field


class CaloriePredictionRequest(BaseModel):
    age: int = Field(ge=1, le=120)
    gender: str
    height_cm: float = Field(gt=50, lt=260)
    weight_kg: float = Field(gt=20, lt=400)
    activity_level: str
    goal: str


class CaloriePredictionResponse(BaseModel):
    recommended_daily_calories: int
    bmr: int
    explanation: str


class MealRecommendationRequest(BaseModel):
    daily_calorie_target: int = Field(gt=800, lt=7000)
    health_goal: str = "maintain"
    food_preference: str | None = None
    protein_requirement_g: float | None = None
    carbohydrate_requirement_g: float | None = None
    fat_requirement_g: float | None = None


class RecommendedFood(BaseModel):
    id: int
    name: str
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float
    serving_size: str


class MealBlock(BaseModel):
    meal_type: str
    calories: float
    items: list[RecommendedFood]


class MealRecommendationResponse(BaseModel):
    daily_calorie_target: int
    meals: list[MealBlock]
    notes: list[str]


class FoodImageRecognitionResponse(BaseModel):
    food_name: str
    estimated_calories: float
    confidence: float
    method: str


class ChatRequest(BaseModel):
    question: str = Field(min_length=3, max_length=800)


class ChatResponse(BaseModel):
    answer: str
    source: str


class HealthRiskRequest(BaseModel):
    bmi: float | None = None
    eating_habits: str
    exercise_frequency: str
    weight_kg: float
    height_cm: float
    goal: str


class HealthRiskResponse(BaseModel):
    risk_level: str
    bmi: float
    recommendations: list[str]

