from sqlalchemy.orm import Session

from app.models.food import Food
from app.schemas.ai import (
    MealBlock,
    MealRecommendationRequest,
    MealRecommendationResponse,
    RecommendedFood,
)


class MealRecommendationService:
    def __init__(self, db: Session) -> None:
        self.db = db

    def recommend(self, payload: MealRecommendationRequest) -> MealRecommendationResponse:
        foods = self.db.query(Food).order_by(Food.calories.asc()).all()
        allergies = {item.strip().lower() for item in payload.allergies if item.strip()}
        if allergies:
            foods = [
                food
                for food in foods
                if not allergies.intersection({tag.lower() for tag in (food.tags or [])})
                and not allergies.intersection({item.lower() for item in (food.allergens or [])})
                and all(allergy not in food.name.lower() for allergy in allergies)
            ]
        if payload.food_preference:
            preferred = [
                food
                for food in foods
                if payload.food_preference.lower() in " ".join(food.tags or []).lower()
                or payload.food_preference.lower() in food.category.lower()
            ]
            if preferred:
                foods = preferred

        meal_targets = {
            "breakfast": payload.daily_calorie_target * 0.25,
            "lunch": payload.daily_calorie_target * 0.35,
            "dinner": payload.daily_calorie_target * 0.30,
            "snack": payload.daily_calorie_target * 0.10,
        }
        meals = [self._build_meal(meal_type, target, foods) for meal_type, target in meal_targets.items()]
        notes = [
            "Recommendations are generated from available foods and macro targets.",
            "Adjust portions based on hunger, training schedule, and medical guidance.",
        ]
        if allergies:
            notes.append(f"Avoided foods matching allergies: {', '.join(sorted(allergies))}.")
        if payload.budget:
            notes.append(f"Budget target considered: {payload.budget:.2f}. Estimated prices are simplified for this project.")
        if payload.health_goal.lower() in {"lose_weight", "weight_loss"}:
            notes.append("Weight-loss plans prioritize lower-calorie, high-protein foods.")
        return MealRecommendationResponse(
            daily_calorie_target=payload.daily_calorie_target,
            meals=meals,
            notes=notes,
        )

    def _build_meal(self, meal_type: str, target: float, foods: list[Food]) -> MealBlock:
        selected: list[Food] = []
        total = 0.0
        categories = self._preferred_categories(meal_type)
        candidates = sorted(
            foods,
            key=lambda food: (food.category not in categories, abs(food.calories - target / 2)),
        )
        for food in candidates:
            if len(selected) >= 3:
                break
            if total + food.calories <= target * 1.25 or not selected:
                selected.append(food)
                total += food.calories

        return MealBlock(
            meal_type=meal_type,
            calories=round(total, 2),
            items=[
                RecommendedFood(
                    id=food.id,
                    name=food.name,
                    calories=food.calories,
                    protein_g=food.protein_g,
                    carbs_g=food.carbs_g,
                    fat_g=food.fat_g,
                    serving_size=food.serving_size,
                    image_url=food.image_url,
                )
                for food in selected
            ],
        )

    def _preferred_categories(self, meal_type: str) -> set[str]:
        return {
            "breakfast": {"breakfast", "fruit", "snack"},
            "lunch": {"protein", "carbohydrate", "vegetable", "meal"},
            "dinner": {"protein", "vegetable", "carbohydrate"},
            "snack": {"snack", "fruit"},
        }[meal_type]
