from datetime import datetime
from zoneinfo import ZoneInfo

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.core.config import settings
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
from app.services.food_substitute import FoodSubstitutionService
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
    if image.content_type and not image.content_type.startswith("image/"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Upload must be an image file")
    content = await image.read()
    if not content:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Uploaded image is empty")
    if len(content) > 10 * 1024 * 1024:
        raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail="Image must be 10 MB or smaller")
    return FoodImageRecognitionService(db).recognize(content, image.filename or "food-image")


@router.post("/chat", response_model=ChatResponse)
def nutrition_chat(
    payload: ChatRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> ChatResponse:
    summary = (
        db.query(NutritionLog)
        .filter(
            NutritionLog.user_id == current_user.id,
            NutritionLog.log_date == datetime.now(ZoneInfo(settings.app_timezone)).date(),
        )
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
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> SubstituteResponse:
    allergies = [allergy.ingredient.lower() for allergy in current_user.allergies]
    alternatives = FoodSubstitutionService(db).recommend(food_name, allergies)
    return SubstituteResponse(food=food_name, alternatives=alternatives)
