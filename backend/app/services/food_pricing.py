PRICE_BY_CATEGORY = {
    "protein": 2.5,
    "meal": 2.0,
    "carbohydrate": 0.8,
    "vegetable": 0.7,
    "fruit": 0.6,
    "snack": 1.0,
    "breakfast": 1.0,
}


def estimated_food_cost(category: str) -> float:
    return PRICE_BY_CATEGORY.get(category.lower(), 1.0)
