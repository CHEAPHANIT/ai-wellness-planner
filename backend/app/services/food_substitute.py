from sqlalchemy.orm import Session

from app.models.food import Food


class FoodSubstitutionService:
    curated = {
        "milk": ["Soy milk", "Oat milk", "Coconut milk"],
        "beef": ["Chicken", "Fish", "Tofu"],
        "rice": ["Brown rice", "Sweet potato", "Quinoa"],
        "peanut": ["Sunflower seeds", "Pumpkin seeds", "Roasted chickpeas"],
        "pizza": ["Chicken rice bowl", "Vegetable wrap", "Grilled fish with rice"],
    }

    def __init__(self, db: Session) -> None:
        self.db = db

    def recommend(self, food_name: str, allergies: list[str], limit: int = 4) -> list[str]:
        normalized_name = food_name.strip().lower()
        source = self.db.query(Food).filter(Food.name.ilike(normalized_name)).first()
        suggestions: list[str] = []

        if source is not None:
            candidates = self.db.query(Food).filter(Food.id != source.id).all()
            candidates = [food for food in candidates if self._safe(food.name, food.allergens or [], allergies)]
            candidates.sort(key=lambda food: self._nutrition_distance(source, food))
            suggestions.extend(food.name for food in candidates[:limit])

        for key, alternatives in self.curated.items():
            if key in normalized_name:
                suggestions.extend(
                    alternative for alternative in alternatives if self._safe(alternative, [], allergies)
                )

        if not suggestions:
            fallback = self.db.query(Food).order_by(Food.protein_g.desc()).all()
            suggestions.extend(
                food.name for food in fallback if self._safe(food.name, food.allergens or [], allergies)
            )
        return list(dict.fromkeys(suggestions))[:limit]

    def _nutrition_distance(self, source: Food, candidate: Food) -> float:
        category_penalty = 0 if source.category.lower() == candidate.category.lower() else 1.5
        return category_penalty + (
            abs(source.calories - candidate.calories) / max(source.calories, 100)
            + abs(source.protein_g - candidate.protein_g) / max(source.protein_g, 10)
            + 0.35 * abs(source.carbs_g - candidate.carbs_g) / max(source.carbs_g, 20)
            + 0.35 * abs(source.fat_g - candidate.fat_g) / max(source.fat_g, 8)
        )

    def _safe(self, name: str, listed_allergens: list[str], allergies: list[str]) -> bool:
        searchable = " ".join([name, *listed_allergens]).lower()
        aliases = {
            "dairy": {"dairy", "milk", "cheese", "yogurt"},
            "nut": {"nut", "peanut", "almond", "cashew"},
            "nuts": {"nut", "peanut", "almond", "cashew"},
            "seafood": {"seafood", "fish", "shellfish", "shrimp", "prawn"},
        }
        return all(
            not any(term in searchable for term in aliases.get(allergy, {allergy}))
            for allergy in allergies
        )
