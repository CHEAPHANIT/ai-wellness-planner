# NutriAI: AI Nutrition & Meal Planner

NutriAI is a full-stack final-year university project for personalized meal planning, nutrition tracking, Cambodian food recommendations, grocery planning, water tracking, weight progress, and basic AI-assisted nutrition guidance.

## Technology Stack

| Layer | Technology |
| --- | --- |
| Mobile/Web frontend | Flutter |
| Backend API | Python FastAPI |
| Database | PostgreSQL |
| ORM | SQLAlchemy |
| Auth | JWT bearer tokens |
| AI/ML services | Python, Scikit-Learn-ready logic, TensorFlow/OpenCV hook, OpenAI/Gemini chatbot hook |
| Deployment | Docker Compose |

## Project Structure

```text
backend/
  app/
    main.py
    api/routes/          auth, profile, food, meal planner, logs, grocery, progress, water, allergies, AI
    core/                settings and security
    db/                  SQLAlchemy session and seed data
    models/              database tables
    schemas/             Pydantic request/response models
    services/            calories, meal recommendation, chatbot, image recognition, health risk
frontend/
  lib/
    main.dart            NutriAI app bootstrap
    api_client.dart      REST API client
    screens.dart         auth, dashboard, profile, planner, food log, assistant, progress screens
docker-compose.yml
```

## PostgreSQL Tables

The backend creates these tables on startup with SQLAlchemy:

```text
users
user_profiles
foods
meal_plans
food_logs
nutrition_logs
goals
grocery_lists
grocery_items
weight_progress
water_logs
chatbot_messages
allergies
health_risk_predictions
```

Meal plan details are stored in `meal_plans.plan_json`. This keeps the beginner-friendly project small while still returning breakfast, lunch, dinner, snack, calories, protein, carbs, and fat for each meal.

## Implemented Features

- Register, login, logout, forgot password, OTP verification, change password, JWT authentication.
- User health profile with age, gender, height, weight, activity, goal, dietary preference, health conditions, eating habits, and exercise frequency.
- BMI, BMI status, BMR, maintenance calories, and target daily calories.
- Daily and weekly AI meal plan generation.
- Allergy-aware meal recommendations and food substitute suggestions.
- Seeded food database with Cambodian foods: Bai Sach Chrouk, Kuy Teav, Num Banh Chok, Grilled Fish, Rice, Chicken, and vegetables.
- Food logging with daily calories, protein, carbs, fat, remaining calories, and nutrition score.
- AI nutrition chatbot with local rule-based fallback and OpenAI/Gemini integration point.
- AI grocery list generation from the latest meal plan.
- Basic health risk prediction with a medical disclaimer.
- Weekly weight progress tracking.
- Water intake recommendation and logging.
- Flutter UI flow for authentication, dashboard, profile, planner, food log, assistant, and progress.

## Main API Modules

```text
POST /api/auth/register
POST /api/auth/login
POST /api/auth/logout
POST /api/auth/forgot-password
POST /api/auth/verify-otp
POST /api/auth/change-password
GET  /api/auth/me

GET  /api/profile
PUT  /api/profile
GET  /api/profile/goal

GET  /api/foods
POST /api/foods

POST /api/meal-plans/generate
POST /api/meal-plans/generate-weekly
GET  /api/meal-plans

POST /api/logs/food
GET  /api/logs/food
GET  /api/logs/nutrition/{date}

POST /api/grocery-lists/generate
GET  /api/grocery-lists

POST /api/progress/weight
GET  /api/progress/weight

POST /api/water
GET  /api/water/{date}

GET  /api/allergies
POST /api/allergies
DELETE /api/allergies/{id}

POST /api/ai/calories
POST /api/ai/meals
POST /api/ai/chat
POST /api/ai/health-risk
POST /api/ai/image-recognition
GET  /api/ai/substitutes/{food_name}
```

## Run With Docker

Start Docker Desktop first. Then run from the project root:

```powershell
docker compose up --build
```

Open:

```text
http://localhost:8080
```

API docs:

```text
http://localhost:8000/docs
```

If you changed database columns and already have an old Docker volume, recreate the database:

```powershell
docker compose down -v
docker compose up --build
```

## Run Locally

Start PostgreSQL:

```powershell
docker compose up -d postgres
```

Run the backend:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
uvicorn app.main:app --reload
```

Run Flutter:

```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

For Android/iOS, use the same Flutter project and set `API_BASE_URL` to the backend URL reachable from the device or emulator.

## Testing

Frontend:

```powershell
cd frontend
flutter analyze
flutter test
```

Backend with a working local Python environment:

```powershell
cd backend
python -m pytest app/tests
```

Backend import check through Docker:

```powershell
docker compose build backend
docker compose run --rm backend python -c "from app.main import app; print(app.title)"
```

## AI Integration Notes

The chatbot currently uses a deterministic local fallback so the project works without paid API keys. Add `OPENAI_API_KEY` to `backend/.env` or Docker environment variables to connect a hosted model. The image recognition service has a TensorFlow/OpenCV hook and a fallback suitable for demonstration.

Health risk prediction is educational only. The API returns a disclaimer because the output is not a medical diagnosis.
