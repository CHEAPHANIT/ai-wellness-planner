from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import ai, auth, foods, logs, meal_plans, profiles
from app.core.config import settings
from app.db.base import Base
from app.db.init_db import seed_foods
from app.db.session import SessionLocal, engine

# Import models so SQLAlchemy registers every table before create_all.
from app.models import food, food_log, goal, meal_plan, nutrition_log, user, user_profile  # noqa: F401


def create_app() -> FastAPI:
    app = FastAPI(title=settings.app_name)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(auth.router, prefix="/api")
    app.include_router(profiles.router, prefix="/api")
    app.include_router(foods.router, prefix="/api")
    app.include_router(meal_plans.router, prefix="/api")
    app.include_router(logs.router, prefix="/api")
    app.include_router(ai.router, prefix="/api")

    @app.on_event("startup")
    def on_startup() -> None:
        Base.metadata.create_all(bind=engine)
        db = SessionLocal()
        try:
            seed_foods(db)
        finally:
            db.close()

    @app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    return app


app = create_app()

