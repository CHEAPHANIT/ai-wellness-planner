from app.schemas.ai import CaloriePredictionRequest, HealthRiskRequest
from app.services.calorie_model import CaloriePredictionService
from app.services.health_risk import HealthRiskService


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

