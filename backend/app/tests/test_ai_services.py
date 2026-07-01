from types import SimpleNamespace

import pytest
from pydantic import ValidationError
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool

import app.main  # noqa: F401 - registers every SQLAlchemy model
from app.api.routes.grocery import generate_grocery_list
from app.api.routes.meal_plans import generate_meal_plan
from app.core.config import settings
from app.db.base import Base
from app.db.init_db import seed_foods
from app.models.grocery import GroceryList
from app.models.meal_plan import MealPlan
from app.models.user import User
from app.schemas.ai import (
    CaloriePredictionRequest,
    ChatRequest,
    HealthRiskRequest,
    MealRecommendationRequest,
)
from app.schemas.grocery import GroceryListGenerateRequest
from app.schemas.meal_plan import MealPlanCreate
from app.services.calorie_model import CaloriePredictionService
from app.services.chatbot import NutritionChatbot
from app.services.health_risk import HealthRiskService
from app.services.image_recognition import FoodImageRecognitionService
from app.services.meal_recommender import MealRecommendationService


class _FoodQuery:
    def __init__(self, foods: list[SimpleNamespace]) -> None:
        self.foods = foods

    def order_by(self, *_: object) -> "_FoodQuery":
        return self

    def all(self) -> list[SimpleNamespace]:
        return self.foods


class _FoodDb:
    def __init__(self, foods: list[SimpleNamespace]) -> None:
        self.foods = foods

    def query(self, _: object) -> _FoodQuery:
        return _FoodQuery(self.foods)


def _food(
    food_id: int,
    name: str,
    category: str,
    calories: float,
    protein: float,
    carbs: float,
    fat: float,
    *,
    tags: list[str] | None = None,
    allergens: list[str] | None = None,
) -> SimpleNamespace:
    return SimpleNamespace(
        id=food_id,
        name=name,
        category=category,
        serving_size="1 serving",
        calories=calories,
        protein_g=protein,
        carbs_g=carbs,
        fat_g=fat,
        image_url=None,
        tags=tags or [],
        allergens=allergens or [],
    )


def test_calorie_prediction_returns_reasonable_value() -> None:
    response = CaloriePredictionService().predict(
        CaloriePredictionRequest(
            age=25,
            gender="male",
            height_cm=178,
            weight_kg=78,
            activity_level="moderate",
            goal="maintain",
        )
    )
    assert response.recommended_daily_calories > 2000
    assert response.bmr > 1500


def test_calorie_prediction_rejects_unknown_activity() -> None:
    with pytest.raises(ValidationError):
        CaloriePredictionRequest(
            age=25,
            gender="male",
            height_cm=178,
            weight_kg=78,
            activity_level="sometimes",
            goal="maintain",
        )


def test_health_risk_classifies_high_risk_inputs() -> None:
    response = HealthRiskService().predict(
        HealthRiskRequest(
            eating_habits="fast food and high sugar",
            exercise_frequency="none",
            weight_kg=95,
            height_cm=165,
            goal="lose_weight",
        )
    )
    assert response.risk_level == "High Health Risk"
    assert response.bmi > 30


def test_meal_recommendation_excludes_allergens_and_uses_macro_targets() -> None:
    foods = [
        _food(1, "Chicken Breast", "protein", 165, 31, 0, 3.6, tags=["high-protein"]),
        _food(2, "Brown Rice", "carbohydrate", 216, 5, 45, 1.8),
        _food(3, "Vegetables", "vegetable", 80, 3, 16, 0.5),
        _food(4, "Greek Yogurt", "snack", 100, 17, 6, 0.7, allergens=["milk"]),
        _food(5, "Banana", "fruit", 105, 1.3, 27, 0.4),
    ]
    response = MealRecommendationService(_FoodDb(foods)).recommend(
        MealRecommendationRequest(
            daily_calorie_target=2000,
            allergies=["dairy"],
            protein_requirement_g=160,
            carbohydrate_requirement_g=210,
            fat_requirement_g=60,
        )
    )

    selected_names = {item.name for meal in response.meals for item in meal.items}
    assert "Greek Yogurt" not in selected_names
    assert len(response.meals) == 4
    assert all(meal.items for meal in response.meals)


def test_image_fallback_does_not_claim_unknown_photo() -> None:
    foods = [_food(1, "Chicken Fried Rice", "meal", 520, 24, 64, 18)]
    response = FoodImageRecognitionService(_FoodDb(foods)).recognize(b"image bytes", "IMG_1234.jpg")

    assert response.food_name == "Unknown Food"
    assert response.confidence == 0


def test_chatbot_local_mode_avoids_network_and_uses_daily_context(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "ai_provider", "local")
    response = NutritionChatbot().answer(ChatRequest(question="Analyze my diet today"), today_calories=1450)

    assert response.source == "local-rule-based"
    assert "1,450" in response.answer or "1450" in response.answer


def test_chatbot_weight_gain_food_question_does_not_return_weight_loss_advice(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(settings, "ai_provider", "local")
    response = NutritionChatbot().answer(ChatRequest(question="i want to gainst weight so what food i need ot to eat?"))

    assert response.source == "local-rule-based"
    assert "weight gain" in response.answer.lower()
    assert "weight loss" not in response.answer.lower()


def test_chatbot_food_question_avoids_chicken_allergy(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "ai_provider", "local")
    user = SimpleNamespace(
        profile=None,
        goal=None,
        allergies=[SimpleNamespace(ingredient="chicken")],
    )
    response = NutritionChatbot().answer(
        ChatRequest(question="i have allergies with chicken so what are the food that I should eat?"),
        user=user,
    )

    assert response.source == "local-rule-based"
    assert "avoid chicken" in response.answer.lower()
    assert "chicken" not in response.answer.lower().replace("avoid chicken", "")


def test_chatbot_uses_saved_weight_gain_goal_for_food_question(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "ai_provider", "local")
    user = SimpleNamespace(
        profile=None,
        goal=SimpleNamespace(goal_type="gain_weight"),
        allergies=[],
    )
    response = NutritionChatbot().answer(ChatRequest(question="what should I eat for lunch?"), user=user)

    assert response.source == "local-rule-based"
    assert "weight gain" in response.answer.lower()
    assert "extra snack" in response.answer.lower() or "increase portions" in response.answer.lower()


def test_chatbot_parses_non_configured_allergy_from_question(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "ai_provider", "local")
    response = NutritionChatbot().answer(ChatRequest(question="I am allergic to shrimp, what protein should I eat?"))

    assert response.source == "local-rule-based"
    assert "avoid shrimp" in response.answer.lower()
    assert "shrimp" not in response.answer.lower().replace("avoid shrimp", "")


def test_saved_plan_is_updated_instead_of_duplicated() -> None:
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        user = User(email="flow@example.com", full_name="Flow User", hashed_password="test")
        db.add(user)
        db.commit()
        db.refresh(user)
        seed_foods(db)
        payload = MealPlanCreate(
            plan_date="2026-06-22",
            recommendation_request=MealRecommendationRequest(daily_calorie_target=2000),
        )

        first = generate_meal_plan(payload, db, user)
        second = generate_meal_plan(payload, db, user)

        assert first.id == second.id
        assert db.query(MealPlan).filter(MealPlan.user_id == user.id).count() == 1


def test_grocery_cost_uses_food_category() -> None:
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        user = User(email="grocery@example.com", full_name="Grocery User", hashed_password="test")
        db.add(user)
        db.commit()
        db.refresh(user)
        seed_foods(db)
        plan = generate_meal_plan(
            MealPlanCreate(
                plan_date="2026-06-22",
                recommendation_request=MealRecommendationRequest(daily_calorie_target=2000),
            ),
            db,
            user,
        )

        result = generate_grocery_list(
            GroceryListGenerateRequest(meal_plan_id=plan.id),
            db,
            user,
        )

        assert isinstance(result, GroceryList)
        assert result.estimated_total_cost > 0
        assert all(item.estimated_cost > 0 for item in result.items)
