from pydantic import BaseModel, Field, field_validator


class CaloriePredictionRequest(BaseModel):
    age: int = Field(ge=1, le=120)
    gender: str = Field(min_length=1, max_length=40)
    height_cm: float = Field(gt=50, lt=260)
    weight_kg: float = Field(gt=20, lt=400)
    activity_level: str = Field(min_length=1, max_length=80)
    goal: str = Field(min_length=1, max_length=80)

    @field_validator("gender", "activity_level", "goal")
    @classmethod
    def normalize_calorie_inputs(cls, value: str) -> str:
        return value.strip().lower().replace(" ", "_").replace("-", "_")

    @field_validator("gender")
    @classmethod
    def validate_gender(cls, value: str) -> str:
        aliases = {"man": "male", "woman": "female"}
        value = aliases.get(value, value)
        if value not in {"male", "female"}:
            raise ValueError("gender must be male or female for the Mifflin-St Jeor calculation")
        return value

    @field_validator("activity_level")
    @classmethod
    def validate_activity_level(cls, value: str) -> str:
        aliases = {"veryactive": "very_active", "lightly_active": "light", "moderately_active": "moderate"}
        value = aliases.get(value, value)
        if value not in {"sedentary", "light", "moderate", "active", "very_active"}:
            raise ValueError("unsupported activity level")
        return value

    @field_validator("goal")
    @classmethod
    def validate_goal(cls, value: str) -> str:
        aliases = {"lose": "lose_weight", "loss": "lose_weight", "gain": "gain_weight"}
        value = aliases.get(value, value)
        if value not in {"lose_weight", "weight_loss", "maintain", "gain_muscle", "gain_weight"}:
            raise ValueError("unsupported calorie goal")
        return value


class CaloriePredictionResponse(BaseModel):
    recommended_daily_calories: int
    bmr: int
    bmi: float
    bmi_status: str
    maintenance_calories: int
    explanation: str


class MealRecommendationRequest(BaseModel):
    daily_calorie_target: int = Field(gt=800, lt=7000)
    health_goal: str = Field(default="maintain", min_length=1, max_length=80)
    food_preference: str | None = Field(default=None, max_length=120)
    allergies: list[str] = Field(default_factory=list, max_length=30)
    budget: float | None = Field(default=None, gt=0)
    days: int = Field(default=1, ge=1, le=7)
    protein_requirement_g: float | None = Field(default=None, ge=0, le=500)
    carbohydrate_requirement_g: float | None = Field(default=None, ge=0, le=1000)
    fat_requirement_g: float | None = Field(default=None, ge=0, le=500)

    @field_validator("health_goal")
    @classmethod
    def normalize_health_goal(cls, value: str) -> str:
        return value.strip().lower().replace(" ", "_").replace("-", "_")

    @field_validator("food_preference")
    @classmethod
    def normalize_food_preference(cls, value: str | None) -> str | None:
        if value is None:
            return None
        normalized = value.strip().lower()
        return normalized or None

    @field_validator("allergies")
    @classmethod
    def normalize_allergies(cls, values: list[str]) -> list[str]:
        return list(dict.fromkeys(value.strip().lower() for value in values if value.strip()))


class RecommendedFood(BaseModel):
    id: int
    name: str
    calories: float
    protein_g: float
    carbs_g: float
    fat_g: float
    serving_size: str
    image_url: str | None = None


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
    confidence: float = Field(ge=0, le=1)
    method: str


class ChatRequest(BaseModel):
    question: str = Field(min_length=3, max_length=800)


class ChatResponse(BaseModel):
    answer: str
    source: str


class HealthRiskRequest(BaseModel):
    bmi: float | None = Field(default=None, gt=5, lt=100)
    eating_habits: str = Field(min_length=1, max_length=240)
    exercise_frequency: str = Field(min_length=1, max_length=120)
    weight_kg: float = Field(gt=20, lt=400)
    height_cm: float = Field(gt=50, lt=260)
    goal: str = Field(min_length=1, max_length=80)

    @field_validator("eating_habits", "exercise_frequency", "goal")
    @classmethod
    def normalize_risk_inputs(cls, value: str) -> str:
        return value.strip().lower()


class HealthRiskResponse(BaseModel):
    risk_level: str
    bmi: float
    recommendations: list[str]
    disclaimer: str = "This is not a medical diagnosis. Consult a qualified health professional for personal medical advice."


class SubstituteResponse(BaseModel):
    food: str
    alternatives: list[str]
