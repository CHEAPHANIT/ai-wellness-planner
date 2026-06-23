from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.models.food import Food
from app.models.grocery import GroceryItem, GroceryList
from app.models.meal_plan import MealPlan
from app.models.user import User
from app.schemas.grocery import GroceryItemUpdate, GroceryListGenerateRequest, GroceryListRead
from app.services.food_pricing import estimated_food_cost

router = APIRouter(prefix="/grocery-lists", tags=["grocery-lists"])

VALID_ITEM_STATUSES = {"need_to_buy", "have", "bought"}


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
    selected_ids = list(dict.fromkeys(payload.meal_plan_ids))
    if payload.meal_plan_id and payload.meal_plan_id not in selected_ids:
        selected_ids.append(payload.meal_plan_id)

    plan_query = db.query(MealPlan).filter(MealPlan.user_id == current_user.id)
    if selected_ids:
        plans = (
            plan_query.filter(MealPlan.id.in_(selected_ids))
            .order_by(MealPlan.plan_date.asc(), MealPlan.created_at.desc())
            .all()
        )
        if len(plans) != len(selected_ids):
            raise HTTPException(status_code=404, detail="One or more meal plans were not found")
    else:
        latest = plan_query.order_by(MealPlan.created_at.desc()).first()
        plans = [latest] if latest is not None else []

    if not plans:
        raise HTTPException(status_code=404, detail="Generate a meal plan first")

    food_categories = {
        food.name: food.category
        for food in db.query(Food).all()
    }
    item_counts: dict[str, dict[str, object]] = {}
    for plan in plans:
        for meal in plan.plan_json.get("meals", []):
            for food in meal.get("items", []):
                name = food["name"]
                existing = item_counts.setdefault(
                    name,
                    {
                        "quantity": 0,
                        "category": food_categories.get(name, "meal"),
                        "serving_size": food.get("serving_size", "1 serving"),
                    },
                )
                existing["quantity"] = int(existing["quantity"]) + 1

    grocery_list = GroceryList(
        user_id=current_user.id,
        name="AI weekly grocery list" if len(plans) > 1 else "AI grocery list",
    )
    db.add(grocery_list)
    db.flush()

    total = 0.0
    for food_name, item in item_counts.items():
        cost = estimated_food_cost(str(item["category"])) * int(item["quantity"])
        total += cost
        db.add(
            GroceryItem(
                grocery_list_id=grocery_list.id,
                food_item=food_name,
                quantity=f'{item["quantity"]} x {item["serving_size"]}',
                estimated_cost=round(cost, 2),
                status="need_to_buy",
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
    if payload.status is not None:
        if payload.status not in VALID_ITEM_STATUSES:
            raise HTTPException(status_code=422, detail="Invalid grocery item status")
        item.status = payload.status
        item.purchased = payload.status == "bought"
    if payload.purchased is not None:
        item.purchased = payload.purchased
        item.status = "bought" if payload.purchased else "need_to_buy"
    db.commit()
    db.refresh(item.grocery_list)
    return item.grocery_list
