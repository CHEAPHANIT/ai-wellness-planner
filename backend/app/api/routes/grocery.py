from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.grocery import GroceryItem, GroceryList
from app.models.meal_plan import MealPlan
from app.models.user import User
from app.schemas.grocery import GroceryItemUpdate, GroceryListGenerateRequest, GroceryListRead

router = APIRouter(prefix="/grocery-lists", tags=["grocery-lists"])

PRICE_BY_CATEGORY = {
    "protein": 2.5,
    "meal": 2.0,
    "carbohydrate": 0.8,
    "vegetable": 0.7,
    "fruit": 0.6,
    "snack": 1.0,
    "breakfast": 1.0,
}


@router.get("", response_model=list[GroceryListRead])
def list_grocery_lists(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[GroceryList]:
    return (
        db.query(GroceryList)
        .filter(GroceryList.user_id == current_user.id)
        .order_by(GroceryList.created_at.desc())
        .limit(20)
        .all()
    )


@router.post("/generate", response_model=GroceryListRead, status_code=status.HTTP_201_CREATED)
def generate_grocery_list(
    payload: GroceryListGenerateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroceryList:
    plan_query = db.query(MealPlan).filter(MealPlan.user_id == current_user.id)
    if payload.meal_plan_id:
        plan_query = plan_query.filter(MealPlan.id == payload.meal_plan_id)
    plan = plan_query.order_by(MealPlan.created_at.desc()).first()
    if plan is None:
        raise HTTPException(status_code=404, detail="Generate a meal plan first")

    item_counts: dict[str, dict[str, object]] = {}
    for meal in plan.plan_json.get("meals", []):
        for food in meal.get("items", []):
            name = food["name"]
            existing = item_counts.setdefault(
                name,
                {
                    "quantity": 0,
                    "category": "meal",
                    "serving_size": food.get("serving_size", "1 serving"),
                },
            )
            existing["quantity"] = int(existing["quantity"]) + 1

    grocery_list = GroceryList(user_id=current_user.id, name="AI weekly grocery list")
    db.add(grocery_list)
    db.flush()

    total = 0.0
    for food_name, item in item_counts.items():
        cost = PRICE_BY_CATEGORY.get(str(item["category"]), 1.0) * int(item["quantity"])
        total += cost
        db.add(
            GroceryItem(
                grocery_list_id=grocery_list.id,
                food_item=food_name,
                quantity=f'{item["quantity"]} x {item["serving_size"]}',
                estimated_cost=round(cost, 2),
            )
        )

    grocery_list.estimated_total_cost = round(total, 2)
    if payload.budget and grocery_list.estimated_total_cost > payload.budget:
        grocery_list.name = "AI grocery list - over budget"
    db.commit()
    db.refresh(grocery_list)
    return grocery_list


@router.patch("/items/{item_id}", response_model=GroceryListRead)
def update_grocery_item(
    item_id: int,
    payload: GroceryItemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GroceryList:
    item = db.get(GroceryItem, item_id)
    if item is None or item.grocery_list.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Grocery item was not found")
    item.purchased = payload.purchased
    db.commit()
    db.refresh(item.grocery_list)
    return item.grocery_list
