from sqlalchemy.orm import Session

from app.models.food import Food
from app.schemas.ai import FoodImageRecognitionResponse


class FoodImageRecognitionService:
    def __init__(self, db: Session) -> None:
        self.db = db

    def recognize(self, image_bytes: bytes, filename: str) -> FoodImageRecognitionResponse:
        # Production path: load a TensorFlow/Keras MobileNet or YOLO model and run
        # OpenCV preprocessing here. The fallback keeps the endpoint usable without
        # a trained model artifact.
        detected_name = self._guess_from_filename(filename)
        food = self.db.query(Food).filter(Food.name.ilike(f"%{detected_name}%")).first()
        if food is None:
            food = self.db.query(Food).order_by(Food.calories.desc()).first()

        return FoodImageRecognitionResponse(
            food_name=food.name if food else "Unknown Food",
            estimated_calories=food.calories if food else 0,
            confidence=0.55 if image_bytes else 0.0,
            method="filename-and-database-fallback",
        )

    def _guess_from_filename(self, filename: str) -> str:
        normalized = filename.lower().replace("_", " ").replace("-", " ")
        for keyword in ["chicken fried rice", "chicken", "rice", "fish", "salad", "banana", "oatmeal"]:
            if keyword in normalized:
                return keyword
        return "chicken fried rice"

