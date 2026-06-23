from itertools import combinations

from sqlalchemy.orm import Session

from app.models.food import Food
from app.schemas.ai import (
    MealBlock,
    MealRecommendationRequest,
    MealRecommendationResponse,
    RecommendedFood,
)
from app.services.food_pricing import estimated_food_cost


class MealRecommendationService:
    meal_shares = {
        "breakfast": 0.25,
        "lunch": 0.35,
        "dinner": 0.30,
        "snack": 0.10,
    }
    allergy_aliases = {
        "dairy": {"dairy", "milk", "cheese", "yogurt"},
        "nut": {"nut", "nuts", "peanut", "almond", "cashew"},
        "nuts": {"nut", "nuts", "peanut", "almond", "cashew"},
        "seafood": {"seafood", "fish", "shellfish", "shrimp", "prawn"},
    }

    def __init__(self, db: Session) -> None:
        self.db = db

    def recommend(
        self,
        payload: MealRecommendationRequest,
        rotation_offset: int = 0,
    ) -> MealRecommendationResponse:
        all_foods = self.db.query(Food).order_by(Food.name.asc()).all()
        foods = [food for food in all_foods if self._is_allergy_safe(food, payload.allergies)]
        notes = ["Recommendations use the foods currently available in the database."]

        preferred_foods = self._matching_preference(foods, payload.food_preference)
        strict_preferences = {"vegetarian", "vegan", "halal", "local", "cambodian"}
        if preferred_foods:
            foods = preferred_foods
            notes.append(f"Applied the {payload.food_preference} food preference.")
        elif payload.food_preference in strict_preferences:
            notes.append(
                f"No foods matched the {payload.food_preference} preference, so allergy-safe foods were used instead."
            )
        elif payload.food_preference == "high-protein":
            notes.append("Used protein targets to prioritize higher-protein combinations.")

        macro_targets = self._daily_macro_targets(payload)
        meals = [
            self._build_meal(
                meal_type,
                payload.daily_calorie_target * share,
                {name: value * share for name, value in macro_targets.items()},
                foods,
                rotation_offset + index,
                payload.health_goal,
                payload.budget * share if payload.budget is not None else None,
            )
            for index, (meal_type, share) in enumerate(self.meal_shares.items())
        ]

        if payload.allergies:
            notes.append(f"Excluded foods matching: {', '.join(payload.allergies)}.")
        if not foods:
            notes.append("No foods satisfy the current allergy and preference filters. Add safe foods before generating a plan.")
        if payload.budget is not None:
            notes.append("Budget influenced selection using simplified per-serving category prices.")

        planned_calories = sum(meal.calories for meal in meals)
        notes.append(
            f"Planned {round(planned_calories)} of {payload.daily_calorie_target} kcal; portions are database serving sizes."
        )
        return MealRecommendationResponse(
            daily_calorie_target=payload.daily_calorie_target,
            meals=meals,
            notes=notes,
        )

    def _daily_macro_targets(self, payload: MealRecommendationRequest) -> dict[str, float]:
        calories = payload.daily_calorie_target
        return {
            "protein": payload.protein_requirement_g if payload.protein_requirement_g is not None else calories * 0.20 / 4,
            "carbs": (
                payload.carbohydrate_requirement_g
                if payload.carbohydrate_requirement_g is not None
                else calories * 0.45 / 4
            ),
            "fat": payload.fat_requirement_g if payload.fat_requirement_g is not None else calories * 0.30 / 9,
        }

    def _build_meal(
        self,
        meal_type: str,
        calorie_target: float,
        macro_targets: dict[str, float],
        foods: list[Food],
        rotation_offset: int,
        health_goal: str,
        budget_target: float | None,
    ) -> MealBlock:
        if not foods:
            return MealBlock(meal_type=meal_type, calories=0, items=[])

        categories = self._preferred_categories(meal_type)
        ordered = sorted(
            foods,
            key=lambda food: (
                food.category.lower() not in categories,
                abs(food.calories - calorie_target),
                food.name,
            ),
        )[:30]
        shift = rotation_offset % len(ordered)
        ordered = ordered[shift:] + ordered[:shift]

        max_items = 1 if meal_type == "snack" else 3
        candidates = (
            combination
            for size in range(1, min(max_items, len(ordered)) + 1)
            for combination in combinations(ordered, size)
        )
        selected = min(
            candidates,
            key=lambda items: (
                round(
                    self._meal_score(
                        items,
                        meal_type,
                        calorie_target,
                        macro_targets,
                        health_goal,
                        categories,
                        budget_target,
                    ),
                    1,
                ),
                sum(ordered.index(food) for food in items),
            ),
        )
        calories = sum(food.calories for food in selected)
        return MealBlock(
            meal_type=meal_type,
            calories=round(calories, 2),
            items=[self._to_recommended_food(food) for food in selected],
        )

    def _meal_score(
        self,
        items: tuple[Food, ...],
        meal_type: str,
        calorie_target: float,
        macro_targets: dict[str, float],
        health_goal: str,
        preferred_categories: set[str],
        budget_target: float | None,
    ) -> float:
        calories = sum(food.calories for food in items)
        protein = sum(food.protein_g for food in items)
        carbs = sum(food.carbs_g for food in items)
        fat = sum(food.fat_g for food in items)
        score = 5 * abs(calories - calorie_target) / max(calorie_target, 1)
        score += abs(protein - macro_targets["protein"]) / max(macro_targets["protein"], 10)
        score += 0.45 * abs(carbs - macro_targets["carbs"]) / max(macro_targets["carbs"], 20)
        score += 0.45 * abs(fat - macro_targets["fat"]) / max(macro_targets["fat"], 8)

        category_names = {food.category.lower() for food in items}
        if not category_names.intersection(preferred_categories):
            score += 1.5
        if meal_type != "snack" and "meal" not in category_names:
            if "protein" not in category_names:
                score += 0.8
            if not category_names.intersection({"carbohydrate", "vegetable", "breakfast"}):
                score += 0.5
        if health_goal in {"lose_weight", "weight_loss", "fat_loss"}:
            score -= min(protein / max(calories, 1), 0.2)
        if budget_target is not None:
            estimated_cost = sum(estimated_food_cost(food.category) for food in items)
            if estimated_cost > budget_target:
                score += 3 * (estimated_cost - budget_target) / max(budget_target, 1)
        return score

    def _is_allergy_safe(self, food: Food, allergies: list[str]) -> bool:
        searchable = " ".join(
            [food.name, food.category, *(food.tags or []), *(food.allergens or [])]
        ).lower()
        for allergy in allergies:
            terms = self.allergy_aliases.get(allergy, {allergy})
            if any(term in searchable for term in terms):
                return False
        return True

    def _matching_preference(self, foods: list[Food], preference: str | None) -> list[Food]:
        if not preference or preference in {"balanced", "all", "none", "high-protein", "low-carb"}:
            return []
        aliases = {
            "local": {"local", "cambodian"},
            "cambodian": {"local", "cambodian"},
            "vegetarian": {"vegetarian", "vegan"},
            "vegan": {"vegan"},
            "halal": {"halal"},
        }
        terms = aliases.get(preference, {preference})
        return [
            food
            for food in foods
            if any(
                term in " ".join([food.category, *(food.tags or [])]).lower()
                for term in terms
            )
        ]

    def _to_recommended_food(self, food: Food) -> RecommendedFood:
        return RecommendedFood(
            id=food.id,
            name=food.name,
            calories=food.calories,
            protein_g=food.protein_g,
            carbs_g=food.carbs_g,
            fat_g=food.fat_g,
            serving_size=food.serving_size,
            image_url=food.image_url,
        )

    def _preferred_categories(self, meal_type: str) -> set[str]:
        return {
            "breakfast": {"breakfast", "fruit", "meal"},
            "lunch": {"protein", "carbohydrate", "vegetable", "meal"},
            "dinner": {"protein", "vegetable", "carbohydrate", "meal"},
            "snack": {"snack", "fruit"},
        }[meal_type]
