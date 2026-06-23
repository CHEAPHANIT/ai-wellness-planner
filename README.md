# NutriAI: AI Nutrition and Meal Planner

NutriAI is a web and mobile-ready application that helps people plan meals, understand daily nutrition, avoid allergy conflicts, prepare grocery lists, track water and weight, and ask nutrition-related questions.

This README is written for both non-technical readers who want to understand the idea and technical readers who want to install, test, or extend the project.

> **Health notice:** NutriAI is an educational university project. Its calorie estimates, health-risk screening, and chatbot responses are not medical diagnoses or replacements for advice from a qualified healthcare professional.

## Table of Contents

- [Why this system exists](#why-this-system-exists)
- [Main goal](#main-goal)
- [What users can do](#what-users-can-do)
- [How the complete process works](#how-the-complete-process-works)
- [How AI is used](#how-ai-is-used)
- [System architecture](#system-architecture)
- [Quick setup with Docker](#quick-setup-with-docker)
- [Run without Docker](#run-without-docker)
- [How to test the complete system](#how-to-test-the-complete-system)
- [Automated tests](#automated-tests)
- [Configuration](#configuration)
- [Project structure](#project-structure)
- [API overview](#api-overview)
- [Database overview](#database-overview)
- [Troubleshooting](#troubleshooting)

## Why This System Exists

Planning healthy meals can be difficult because a person must consider many things at the same time:

- How many calories they need
- Whether they want to lose, gain, or maintain weight
- How much protein, carbohydrate, and fat they need
- Allergies and dietary preferences
- Food availability and budget
- Whether their actual daily intake matches the plan

NutriAI brings these tasks into one application. It is particularly designed to support familiar Cambodian foods rather than only generic Western meal examples.

## Main Goal

The main goal is to build an intelligent meal-planning system that searches the available food database and recommends meal combinations that best match a user's personal requirements.

In simple terms:

```text
User profile and health goal
             +
Allergies, preference, and budget
             +
Available foods and nutrition data
             ↓
Meal recommendation and scoring process
             ↓
Personalized breakfast, lunch, dinner, and snack
```

The system is intended to reduce the time and difficulty involved in deciding what to eat while making the result more personal, explainable, and allergy-aware.

## What Users Can Do

- Register, log in, log out, reset a password with a demonstration OTP, and update account details.
- Create a health profile containing age, gender, height, weight, activity, goal, preferences, health notes, eating habits, and exercise frequency.
- Calculate BMI, BMI status, BMR, maintenance calories, and target daily calories.
- Browse, search, add, and favorite foods, including seeded Cambodian foods.
- Save allergies and exclude conflicting foods from recommendations.
- Generate and save daily or weekly meal plans.
- Generate grocery lists, estimate cost, and track purchased items.
- Log food and view daily calories, protein, carbohydrates, fat, remaining calories, and nutrition score.
- Record water intake and weight progress.
- Find nutritionally similar food substitutes.
- Ask a nutrition chatbot questions.
- Run a basic educational health-risk screening.
- Upload a food photo for conservative recognition assistance.

## How the Complete Process Works

### User journey

1. **Create an account:** The user registers and signs in securely.
2. **Complete the profile:** The user enters body measurements, activity, goal, and food preferences.
3. **Calculate targets:** The backend calculates BMI, BMR, maintenance calories, and a daily calorie recommendation.
4. **Add restrictions:** The user records allergies and optional dietary preferences or budget.
5. **Generate a plan:** The recommendation service evaluates food combinations for breakfast, lunch, dinner, and snack.
6. **Review groceries:** The user converts one or more saved meal plans into a priced grocery list.
7. **Track reality:** Food, water, and weight records show how actual behavior compares with the plan.
8. **Get guidance:** The chatbot, substitute finder, and health-risk feature provide additional educational support.
9. **Repeat:** The user updates their plan as their weight, activity, preferences, or goals change.

### What happens during one request

```text
Flutter screen
    ↓ REST/JSON request
FastAPI route
    ↓ authentication and input validation
Business or AI service
    ↓ read/write
PostgreSQL database
    ↓ JSON response
Flutter displays the result
```

For example, when a user generates a meal plan, Flutter sends the calorie target, macro targets, preference, allergies, health goal, and budget to FastAPI. The backend removes unsafe foods, evaluates valid combinations, saves the selected plan in PostgreSQL, and returns it to the screen.

## How AI Is Used

NutriAI combines several forms of practical AI-assisted logic. It does not depend on a single AI model.

### 1. Meal recommendation: heuristic combinational search

The meal recommender is the central intelligent component. It currently:

1. Loads available foods.
2. removes foods that conflict with recorded allergies;
3. applies food-preference rules;
4. creates candidate combinations of one to three foods;
5. scores every candidate against calorie, protein, carbohydrate, fat, meal-category, health-goal, and budget requirements; and
6. selects the candidate with the lowest score.

A simplified scoring idea is:

```text
meal score =
    calorie difference
  + protein difference
  + carbohydrate difference
  + fat difference
  + unsuitable-category penalty
  + over-budget penalty
```

A lower score means the meal is a closer match.

The technically accurate name for the current approach is **exhaustive combinational search with heuristic scoring**. It is not currently Breadth-First Search (BFS) or priority-queue Best-First Search. The scoring function provides a clear extension path to Best-First Search if that algorithm becomes a formal project requirement.

### 2. Calorie recommendation

The system uses the Mifflin-St Jeor equation to estimate BMR, applies an activity multiplier, and adjusts the result for weight loss, maintenance, muscle gain, or weight gain. This is deterministic formula-based prediction, not a trained machine-learning model.

### 3. Nutrition chatbot

The chatbot can use:

- **Ollama** for a locally hosted language model;
- **OpenAI** when a valid API key is configured; or
- a deterministic local rule-based fallback when an AI provider is unavailable.

The chatbot receives relevant profile context such as the user's goal, calorie and protein targets, allergies, and today's logged calories. Provider failure should not prevent the rest of the application from working.

### 4. Food substitution

The substitute service compares calories and macronutrients, prefers similar food categories, removes allergy conflicts, and returns the closest safe alternatives.

### 5. Health-risk screening

The system assigns an educational risk level using BMI, eating-habit keywords, and exercise frequency. This is transparent rule-based scoring and always requires a medical disclaimer.

### 6. Food-photo assistance

There is no trained computer-vision classifier in the current version. The safe fallback compares a descriptive filename with food names in the database and reports only low-confidence matches. Unknown images return `Unknown Food` instead of a fabricated prediction.

## System Architecture

| Layer | Technology | Responsibility |
| --- | --- | --- |
| Frontend | Flutter | Screens, forms, navigation, charts, and API calls |
| Backend | Python FastAPI | Validation, authentication, business rules, and AI services |
| Database | PostgreSQL | Persistent users, profiles, foods, plans, logs, and progress |
| ORM | SQLAlchemy | Maps Python models to database tables |
| Authentication | JWT bearer tokens | Protects user-specific API endpoints |
| AI providers | Ollama/OpenAI/local rules | Optional conversational nutrition guidance |
| Deployment | Docker Compose | Starts the database, backend, and web frontend together |

## Quick Setup With Docker

This is the recommended setup because it avoids local Python, Flutter, and PostgreSQL version conflicts.

### Requirements

- Git
- Docker Desktop with Docker Compose
- At least ports `8000`, `8080`, and `5433` available

### 1. Open the project folder

```powershell
cd C:\path\to\AIMealPlanning
```

Run all following Docker commands from the folder containing `docker-compose.yml`.

### 2. Create the backend environment file

```powershell
Copy-Item backend\.env.example backend\.env
```

For a first demonstration, set `AI_PROVIDER=local` in `backend/.env`. This avoids requiring Ollama or an OpenAI API key.

### 3. Build and start the system

```powershell
docker compose up --build -d
docker compose ps
```

The expected status is:

```text
postgres   healthy
backend    Up
frontend   Up
```

### 4. Verify each part

| Check | Address | Expected result |
| --- | --- | --- |
| Application | http://localhost:8080 | NutriAI registration/login screen |
| Backend health | http://localhost:8000/health | `{"status":"ok"}` |
| Interactive API docs | http://localhost:8000/docs | FastAPI Swagger UI |

### 5. Stop the system

```powershell
docker compose down
```

This keeps the database volume. Use `docker compose down -v` only when you intentionally want to erase all PostgreSQL data and start from an empty database.

## Run Without Docker

### Requirements

- Python 3.12 recommended
- Flutter SDK compatible with Dart 3.12
- Docker Desktop or another PostgreSQL 16 installation

### 1. Start only PostgreSQL

From the project root:

```powershell
docker compose up -d postgres
```

### 2. Start the backend

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
Copy-Item .env.example .env
uvicorn app.main:app --reload
```

If PostgreSQL is running from this project's Docker Compose configuration, the local backend database URL should use port `5433`:

```text
DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5433/ai_meal_planning
```

Keep this terminal open. The backend runs at http://localhost:8000.

### 3. Start Flutter

Open a second terminal:

```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

For Android, `localhost` refers to the emulator/device itself. Use the host address reachable by the device, commonly `http://10.0.2.2:8000` for the Android emulator.

## How to Test the Complete System

Start with one complete **happy-path** journey. Use a unique test email so existing data does not affect the result.

| Order | Action | Pass criteria |
| --- | --- | --- |
| 1 | Open `/health` and the web app | Health returns `ok`; login screen loads |
| 2 | Register and sign in | Account is created and dashboard opens |
| 3 | Complete the profile and goal | Values remain after refreshing the browser |
| 4 | Check the dashboard | BMI and calorie values are present and reasonable |
| 5 | Add a `milk` allergy | Allergy remains after refresh |
| 6 | Browse/search foods and favorite one | Search and favorite state work |
| 7 | Generate a daily meal plan | Four meal sections appear with foods and nutrition |
| 8 | Inspect the generated foods | No milk, cheese, or yogurt appears |
| 9 | Generate a weekly plan | Seven dated plans are available |
| 10 | Generate a grocery list | Items and positive estimated costs appear |
| 11 | Mark an item purchased | Status remains after refresh |
| 12 | Log a food | Daily calories and macros increase correctly |
| 13 | Delete that food log | Totals decrease again |
| 14 | Record water and weight | Progress updates and persists |
| 15 | Ask the assistant a nutrition question | A relevant answer returns without freezing |
| 16 | Run health-risk screening | A risk level and medical disclaimer appear |
| 17 | Upload an unknown image | The result is low-confidence or `Unknown Food` |
| 18 | Log out and sign in again | Protected screens close; saved data returns after login |

Also test important failure cases:

- Duplicate email registration is rejected.
- A password shorter than eight characters is rejected.
- Protected APIs reject requests without a valid token.
- Invalid food IDs return a clear error.
- Negative or zero quantities are rejected.
- One user cannot access another user's private records.
- Impossible allergy/preference combinations return an explanation rather than crashing.
- An unavailable Ollama or OpenAI server falls back safely.

## Automated Tests

### Frontend checks

```powershell
cd frontend
flutter analyze
flutter test
```

Expected results are `No issues found` and `All tests passed`.

### Backend with a local Python environment

```powershell
cd backend
python -m pytest app/tests -q
```

### Backend through Docker

The production backend image excludes tests. From the project root, mount the test folder read-only into a one-off container:

```powershell
docker compose run --rm --no-deps `
  -v "${PWD}/backend/app/tests:/app/app/tests:ro" `
  backend python -m pytest app/tests -q
```

At the time this guide was written, the project baseline was eight passing backend tests and four passing Flutter widget tests.

The current automated suite covers core service logic and a few important widgets. A future improvement should add FastAPI integration tests for the complete register-to-meal-plan workflow and more Flutter interaction tests.

## Configuration

The backend reads `backend/.env`. Important options include:

| Variable | Example | Meaning |
| --- | --- | --- |
| `DATABASE_URL` | `postgresql+psycopg://...` | PostgreSQL connection |
| `SECRET_KEY` | long random text | Signs authentication tokens |
| `APP_TIMEZONE` | `Asia/Bangkok` | Application date/time zone |
| `AI_PROVIDER` | `local`, `ollama`, `openai`, `auto` | Chatbot provider strategy |
| `OLLAMA_BASE_URL` | `http://host.docker.internal:11434` | Ollama server reachable from Docker |
| `OLLAMA_MODEL` | `gemma2:2b` | Local model name |
| `OPENAI_API_KEY` | API key | Required only for OpenAI mode |
| `OPENAI_MODEL` | configured model name | OpenAI chat model |
| `AI_CONNECT_TIMEOUT_SECONDS` | `2` | Provider connection timeout |
| `AI_RESPONSE_TIMEOUT_SECONDS` | `45` | Maximum provider response wait |

Never commit real API keys or production secrets. Use a long random `SECRET_KEY` outside local development.

Provider behavior:

- `local`: always uses built-in deterministic guidance.
- `ollama`: tries Ollama, then uses the local fallback on failure.
- `openai`: uses OpenAI when a key exists, then falls back locally on failure.
- `auto`: tries Ollama, then configured OpenAI, then local rules.

## Project Structure

```text
backend/
  app/
    main.py                 FastAPI application and startup
    api/routes/             HTTP endpoints
    core/                   configuration and security
    db/                     database connection and seed data
    models/                 SQLAlchemy database models
    schemas/                request and response validation
    services/               recommendation and AI-assisted logic
    tests/                  backend automated tests
  requirements.txt
  Dockerfile

frontend/
  lib/
    main.dart               application bootstrap and session handling
    api_client.dart         communication with the backend
    screens.dart            application screens and interactions
  test/                     Flutter widget tests
  Dockerfile

docker-compose.yml          PostgreSQL, backend, and frontend services
PROJECT_PROPOSAL.md         longer academic project description
README.md                   setup and usage guide
```

## API Overview

All user-specific endpoints require the JWT bearer token returned during login. The interactive and always-current endpoint documentation is available at http://localhost:8000/docs.

| Area | Main endpoints |
| --- | --- |
| Authentication | `/api/auth/register`, `/login`, `/logout`, `/me`, password reset routes |
| Profile and goal | `/api/profile`, `/api/profile/goal` |
| Foods and favorites | `/api/foods`, `/api/foods/favorites`, favorite routes |
| Allergies | `/api/allergies` |
| Meal planning | `/api/meal-plans/generate`, `/generate-weekly`, `/api/meal-plans` |
| Food tracking | `/api/logs/food`, `/api/logs/nutrition/{date}` |
| Groceries | `/api/grocery-lists`, `/generate`, item update route |
| Progress | `/api/progress/weight` |
| Water | `/api/water`, `/api/water/{date}` |
| AI services | `/api/ai/calories`, `/meals`, `/chat`, `/health-risk`, `/image-recognition`, `/substitutes/{food_name}` |

## Database Overview

The backend creates tables automatically during startup and seeds the initial food list.

```text
users                       accounts and password-reset state
user_profiles               body profile and preferences
goals                       calorie, macro, and weight targets
foods                       food nutrition and metadata
food_favorites              user favorite foods
allergies                   user allergy restrictions
meal_plans                  saved daily plans and plan JSON
food_logs                   foods actually eaten
nutrition_logs              calculated daily totals
grocery_lists/items         generated shopping data and item status
weight_progress             weight history
water_logs                  daily hydration records
chatbot_messages            assistant conversation records
health_risk_predictions     saved educational screening results
```

Meal details are stored in `meal_plans.plan_json`, allowing breakfast, lunch, dinner, snack, calories, protein, carbohydrates, and fat to be returned as one structured plan.

## Troubleshooting

### A container is not running

```powershell
docker compose ps -a
docker compose logs --tail=100 backend frontend postgres
```

### Port already in use

Stop the program using port `8000`, `8080`, or `5433`, or change the left side of the relevant port mapping in `docker-compose.yml`.

### Backend cannot connect to PostgreSQL

- In Docker, use host `postgres` and port `5432`.
- From Windows, use host `localhost` and mapped port `5433`.
- Confirm PostgreSQL shows `healthy` with `docker compose ps`.

### The local virtual environment references an old Python installation

Virtual environments are machine-specific and should not be copied between computers. Delete and recreate only the local `.venv` directory, then reinstall requirements:

```powershell
cd backend
Remove-Item -Recurse -Force .venv
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Database schema changed

For development data that can safely be erased:

```powershell
docker compose down -v
docker compose up --build -d
```

This permanently removes the project database volume. Do not use it when the existing data must be preserved.

### Chatbot is slow or unavailable

Set this in `backend/.env`, then rebuild/restart the backend:

```text
AI_PROVIDER=local
```

```powershell
docker compose up --build -d backend
```

The rest of NutriAI works without an external AI provider.
