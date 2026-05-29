from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.user import User
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
    _: User = Depends(get_current_user),
) -> ChatResponse:
    return NutritionChatbot().answer(payload)


@router.post("/health-risk", response_model=HealthRiskResponse)
def predict_health_risk(
    payload: HealthRiskRequest,
    _: User = Depends(get_current_user),
) -> HealthRiskResponse:
    return HealthRiskService().predict(payload)

