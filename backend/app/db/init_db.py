from sqlalchemy.orm import Session

from app.models.food import Food


SEED_FOODS = [
    {
        "name": "Oatmeal",
        "category": "breakfast",
        "serving_size": "1 bowl",
        "calories": 154,
        "protein_g": 6,
        "carbs_g": 27,
        "fat_g": 3,
        "tags": ["vegetarian", "high-fiber"],
    },
    {
        "name": "Banana",
        "category": "fruit",
        "serving_size": "1 medium",
        "calories": 105,
        "protein_g": 1.3,
        "carbs_g": 27,
        "fat_g": 0.4,
        "tags": ["vegetarian", "snack"],
    },
    {
        "name": "Chicken Breast",
        "category": "protein",
        "serving_size": "100 g",
        "calories": 165,
        "protein_g": 31,
        "carbs_g": 0,
        "fat_g": 3.6,
        "tags": ["high-protein", "low-carb"],
    },
    {
        "name": "Brown Rice",
        "category": "carbohydrate",
        "serving_size": "1 cup cooked",
        "calories": 216,
        "protein_g": 5,
        "carbs_g": 45,
        "fat_g": 1.8,
        "tags": ["vegetarian", "whole-grain"],
    },
    {
        "name": "Mixed Vegetables",
        "category": "vegetable",
        "serving_size": "1 cup",
        "calories": 80,
        "protein_g": 3,
        "carbs_g": 16,
        "fat_g": 0.5,
        "tags": ["vegetarian", "high-fiber"],
    },
    {
        "name": "Grilled Fish",
        "category": "protein",
        "serving_size": "120 g",
        "calories": 220,
        "protein_g": 34,
        "carbs_g": 0,
        "fat_g": 8,
        "tags": ["high-protein", "omega-3"],
    },
    {
        "name": "Garden Salad",
        "category": "vegetable",
        "serving_size": "1 bowl",
        "calories": 90,
        "protein_g": 4,
        "carbs_g": 12,
        "fat_g": 3,
        "tags": ["vegetarian", "low-calorie"],
    },
    {
        "name": "Greek Yogurt",
        "category": "snack",
        "serving_size": "170 g",
        "calories": 100,
        "protein_g": 17,
        "carbs_g": 6,
        "fat_g": 0.7,
        "tags": ["high-protein", "vegetarian"],
    },
    {
        "name": "Chicken Fried Rice",
        "category": "meal",
        "serving_size": "1 plate",
        "calories": 520,
        "protein_g": 24,
        "carbs_g": 64,
        "fat_g": 18,
        "tags": ["asian", "rice"],
    },
]


def seed_foods(db: Session) -> None:
    for item in SEED_FOODS:
        exists = db.query(Food).filter(Food.name == item["name"]).first()
        if not exists:
            db.add(Food(**item))
    db.commit()

