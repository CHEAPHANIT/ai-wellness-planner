import re
from pathlib import Path

from sqlalchemy.orm import Session

from app.models.food import Food
from app.schemas.ai import FoodImageRecognitionResponse


class FoodImageRecognitionService:
    """Conservative fallback until a trained vision model is installed.

    A filename match can prefill the food form, but it is deliberately reported
    as low confidence because image pixels are not classified by this service.
    """

    def __init__(self, db: Session) -> None:
        self.db = db

    def recognize(self, image_bytes: bytes, filename: str) -> FoodImageRecognitionResponse:
        if not image_bytes:
            return self._unknown("empty-image")

        filename_tokens = self._tokens(Path(filename).stem)
        if not filename_tokens:
            return self._unknown("no-filename-match")

        foods = self.db.query(Food).order_by(Food.name.asc()).all()
        ranked = sorted(
            ((self._filename_score(filename_tokens, food.name), food) for food in foods),
            key=lambda item: item[0],
            reverse=True,
        )
        if not ranked or ranked[0][0] < 0.5:
            return self._unknown("no-filename-match")

        score, food = ranked[0]
        return FoodImageRecognitionResponse(
            food_name=food.name,
            estimated_calories=food.calories,
            confidence=round(min(0.45, 0.2 + score * 0.25), 2),
            method="filename-database-match",
        )

    def _filename_score(self, filename_tokens: set[str], food_name: str) -> float:
        food_tokens = self._tokens(food_name)
        if not food_tokens:
            return 0
        overlap = len(filename_tokens.intersection(food_tokens))
        return overlap / len(food_tokens)

    def _tokens(self, value: str) -> set[str]:
        ignored = {"img", "image", "photo", "food", "meal", "picture", "upload"}
        return {
            token
            for token in re.findall(r"[a-z]+", value.lower())
            if len(token) > 1 and token not in ignored
        }

    def _unknown(self, method: str) -> FoodImageRecognitionResponse:
        return FoodImageRecognitionResponse(
            food_name="Unknown Food",
            estimated_calories=0,
            confidence=0,
            method=method,
        )
