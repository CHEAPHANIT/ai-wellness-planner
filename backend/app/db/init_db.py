from sqlalchemy import inspect, text
from sqlalchemy.engine import Engine
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
        "image_url": "https://images.unsplash.com/photo-1517673132405-a56a62b18caf",
        "tags": ["vegetarian", "high-fiber"],
        "allergens": [],
    },
    {
        "name": "Banana",
        "category": "fruit",
        "serving_size": "1 medium",
        "calories": 105,
        "protein_g": 1.3,
        "carbs_g": 27,
        "fat_g": 0.4,
        "image_url": "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e",
        "tags": ["vegetarian", "snack"],
        "allergens": [],
    },
    {
        "name": "Chicken Breast",
        "category": "protein",
        "serving_size": "100 g",
        "calories": 165,
        "protein_g": 31,
        "carbs_g": 0,
        "fat_g": 3.6,
        "image_url": "https://images.unsplash.com/photo-1532550907401-a500c9a57435",
        "tags": ["high-protein", "low-carb", "halal"],
        "allergens": [],
    },
    {
        "name": "Brown Rice",
        "category": "carbohydrate",
        "serving_size": "1 cup cooked",
        "calories": 216,
        "protein_g": 5,
        "carbs_g": 45,
        "fat_g": 1.8,
        "image_url": "https://images.unsplash.com/photo-1536304993881-ff6e9eefa2a6",
        "tags": ["vegetarian", "vegan", "whole-grain"],
        "allergens": [],
    },
    {
        "name": "Mixed Vegetables",
        "category": "vegetable",
        "serving_size": "1 cup",
        "calories": 80,
        "protein_g": 3,
        "carbs_g": 16,
        "fat_g": 0.5,
        "image_url": "https://images.unsplash.com/photo-1540420773420-3366772f4999",
        "tags": ["vegetarian", "vegan", "high-fiber"],
        "allergens": [],
    },
    {
        "name": "Grilled Fish",
        "category": "protein",
        "serving_size": "120 g",
        "calories": 220,
        "protein_g": 34,
        "carbs_g": 0,
        "fat_g": 8,
        "image_url": "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2",
        "tags": ["high-protein", "omega-3", "cambodian", "halal"],
        "allergens": ["fish"],
    },
    {
        "name": "Garden Salad",
        "category": "vegetable",
        "serving_size": "1 bowl",
        "calories": 90,
        "protein_g": 4,
        "carbs_g": 12,
        "fat_g": 3,
        "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd",
        "tags": ["vegetarian", "vegan", "low-calorie"],
        "allergens": [],
    },
    {
        "name": "Greek Yogurt",
        "category": "snack",
        "serving_size": "170 g",
        "calories": 100,
        "protein_g": 17,
        "carbs_g": 6,
        "fat_g": 0.7,
        "image_url": "https://images.unsplash.com/photo-1488477181946-6428a0291777",
        "tags": ["high-protein", "vegetarian"],
        "allergens": ["milk"],
    },
    {
        "name": "Chicken Fried Rice",
        "category": "meal",
        "serving_size": "1 plate",
        "calories": 520,
        "protein_g": 24,
        "carbs_g": 64,
        "fat_g": 18,
        "image_url": "https://images.unsplash.com/photo-1603133872878-684f208fb84b",
        "tags": ["asian", "rice"],
        "allergens": ["egg"],
    },
    {
        "name": "Bai Sach Chrouk",
        "category": "meal",
        "serving_size": "1 plate",
        "calories": 620,
        "protein_g": 28,
        "carbs_g": 78,
        "fat_g": 22,
        "image_url": "https://images.unsplash.com/photo-1544025162-d76694265947",
        "tags": ["cambodian", "rice", "pork", "local"],
        "allergens": [],
    },
    {
        "name": "Kuy Teav",
        "category": "meal",
        "serving_size": "1 bowl",
        "calories": 430,
        "protein_g": 22,
        "carbs_g": 58,
        "fat_g": 12,
        "image_url": "https://images.unsplash.com/photo-1569718212165-3a8278d5f624",
        "tags": ["cambodian", "noodle", "local"],
        "allergens": ["shellfish"],
    },
    {
        "name": "Num Banh Chok",
        "category": "meal",
        "serving_size": "1 bowl",
        "calories": 360,
        "protein_g": 14,
        "carbs_g": 62,
        "fat_g": 8,
        "image_url": "https://images.unsplash.com/photo-1553621042-f6e147245754",
        "tags": ["cambodian", "fish", "noodle", "local"],
        "allergens": ["fish"],
    },
    {
        "name": "Steamed Rice",
        "category": "carbohydrate",
        "serving_size": "1 cup",
        "calories": 205,
        "protein_g": 4,
        "carbs_g": 45,
        "fat_g": 0.4,
        "image_url": "https://images.unsplash.com/photo-1516684732162-798a0062be99",
        "tags": ["cambodian", "rice", "vegetarian", "vegan", "halal"],
        "allergens": [],
    },
    {
        "name": "Tofu Vegetable Stir Fry",
        "category": "meal",
        "serving_size": "1 plate",
        "calories": 390,
        "protein_g": 20,
        "carbs_g": 35,
        "fat_g": 18,
        "image_url": "https://images.unsplash.com/photo-1512058564366-18510be2db19",
        "tags": ["vegetarian", "vegan", "high-protein"],
        "allergens": ["soy"],
    },
]


def ensure_schema_compatibility(engine: Engine) -> None:
    """Add beginner-project columns that may be missing in an existing Docker volume."""
    inspector = inspect(engine)
    existing_tables = set(inspector.get_table_names())
    migrations = {
        "users": {
            "reset_otp": "VARCHAR(12)",
            "otp_verified": "BOOLEAN DEFAULT FALSE",
        },
        "user_profiles": {
            "dietary_preference": "VARCHAR(80)",
            "health_conditions": "VARCHAR(255)",
        },
        "foods": {
            "image_url": "VARCHAR(500)",
            "allergens": "JSON DEFAULT '[]'",
        },
    }
    with engine.begin() as connection:
        for table_name, columns in migrations.items():
            if table_name not in existing_tables:
                continue
            existing_columns = {column["name"] for column in inspector.get_columns(table_name)}
            for column_name, column_type in columns.items():
                if column_name not in existing_columns:
                    connection.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {column_name} {column_type}"))


def seed_foods(db: Session) -> None:
    for item in SEED_FOODS:
        exists = db.query(Food).filter(Food.name == item["name"]).first()
        if not exists:
            db.add(Food(**item))
    db.commit()
