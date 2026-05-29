# AI Meal Planning Web Application

Full-stack AI meal planning project using Flutter Web, Python FastAPI, PostgreSQL, JWT authentication, and Python-based AI service modules.

## Stack

| Component | Technology |
| --- | --- |
| Web app | Flutter Web |
| Backend API | Python FastAPI |
| Database | PostgreSQL |
| Authentication | JWT |
| ORM | SQLAlchemy |
| AI / ML | Python, Scikit-Learn-ready services, TensorFlow/OpenCV image-recognition hook |
| Deployment | Docker Compose |

## Project Structure

```text
backend/
  app/
    api/routes/          FastAPI endpoints
    core/                config and security
    db/                  SQLAlchemy session and seed data
    models/              users, profiles, foods, meal_plans, food_logs, nutrition_logs, goals
    schemas/             Pydantic request/response models
    services/            calorie, meal recommendation, image, chatbot, risk services
frontend/
  lib/
    api_client.dart      REST client
    main.dart            app bootstrap
    screens.dart         web dashboard screens
docker-compose.yml
```

## Run With Docker

The frontend Docker image serves the prebuilt Flutter web output from `frontend/build/web`. Rebuild it after frontend code changes:

```powershell
cd frontend
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=http://localhost:8000
cd ..
```

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

## Run Locally

Start PostgreSQL, then run the backend:

```powershell
docker compose up -d postgres
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
uvicorn app.main:app --reload
```

Install TensorFlow when you are ready to replace the image-recognition fallback with a trained model:

```powershell
pip install -r requirements-ml.txt
```

Run the Flutter web app:

```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

## Implemented Features

- User registration and login with JWT.
- Profile and goal management.
- Seeded food database.
- Daily nutrition logging and summaries.
- Meal plan generation and saved meal plans.
- Calorie requirement prediction.
- Personalized meal recommendation.
- Food image recognition endpoint with a TensorFlow/OpenCV integration point and usable fallback.
- Nutrition chatbot endpoint with provider integration point.
- Health risk prediction.

## Notes

The AI services are production-shaped modules with deterministic local behavior. To replace the image-recognition fallback, add a trained TensorFlow/Keras or YOLO artifact in `backend/app/services/image_recognition.py`. To connect a hosted chatbot model, use `OPENAI_API_KEY` or add another provider in `backend/app/services/chatbot.py`.
