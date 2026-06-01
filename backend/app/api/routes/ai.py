from datetime import date

from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.models.chatbot import ChatbotMessage
from app.models.health_risk_prediction import HealthRiskPrediction
from app.models.nutrition_log import NutritionLog
from app.schemas.ai import (
    CaloriePredictionRequest,
    CaloriePredictionResponse,
    ChatRequest,
    ChatResponse,
    FoodImageRecognitionResponse,
    HealthRiskRequest,
    HealthRiskResponse,
    MealRecommendationRequest,
    MealRecommendationResponse,
    SubstituteResponse,
)
from app.services.calorie_model import CaloriePredictionService
from app.services.chatbot import NutritionChatbot
from app.services.health_risk import HealthRiskService
from app.services.image_recognition import FoodImageRecognitionService
from app.services.meal_recommender import MealRecommendationService

router = APIRouter(prefix="/ai", tags=["ai"])


@router.post("/calories", response_model=CaloriePredictionResponse)
def predict_calories(
    payload: CaloriePredictionRequest,
    _: User = Depends(get_current_user),
) -> CaloriePredictionResponse:
    return CaloriePredictionService().predict(payload)


@router.post("/meals", response_model=MealRecommendationResponse)
def recommend_meals(
    payload: MealRecommendationRequest,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
) -> MealRecommendationResponse:
    return MealRecommendationService(db).recommend(payload)


@router.post("/image-recognition", response_model=FoodImageRecognitionResponse)
async def recognize_food_image(
    image: UploadFile = File(...),
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
) -> FoodImageRecognitionResponse:
    content = await image.read()
    return FoodImageRecognitionService(db).recognize(content, image.filename or "food-image")


@router.post("/chat", response_model=ChatResponse)
def nutrition_chat(
    payload: ChatRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ChatResponse:
    summary = (
        db.query(NutritionLog)
        .filter(NutritionLog.user_id == current_user.id, NutritionLog.log_date == date.today())
        .first()
    )
    response = NutritionChatbot().answer(payload, current_user, summary.calories_total if summary else None)
    db.add(
        ChatbotMessage(
            user_id=current_user.id,
            question=payload.question,
            answer=response.answer,
            source=response.source,
        )
    )
    db.commit()
    return response


@router.post("/health-risk", response_model=HealthRiskResponse)
def predict_health_risk(
    payload: HealthRiskRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> HealthRiskResponse:
    response = HealthRiskService().predict(payload)
    db.add(
        HealthRiskPrediction(
            user_id=current_user.id,
            bmi=response.bmi,
            risk_level=response.risk_level,
            recommendations=response.recommendations,
            disclaimer=response.disclaimer,
        )
    )
    db.commit()
    return response


@router.get("/substitutes/{food_name}", response_model=SubstituteResponse)
def recommend_substitutes(
    food_name: str,
    _: User = Depends(get_current_user),
) -> SubstituteResponse:
    substitutions = {
        "milk": ["Soy milk", "Almond milk", "Oat milk"],
        "beef": ["Chicken", "Fish", "Tofu"],
        "rice": ["Brown rice", "Sweet potato", "Quinoa"],
        "peanut": ["Sunflower seeds", "Pumpkin seeds", "Roasted chickpeas"],
        "pizza": ["Chicken rice bowl", "Vegetable wrap", "Grilled fish with rice"],
    }
    alternatives = substitutions.get(food_name.lower(), ["Grilled fish", "Chicken", "Vegetables", "Rice"])
    return SubstituteResponse(food=food_name, alternatives=alternatives)
