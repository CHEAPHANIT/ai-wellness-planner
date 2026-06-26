# NutriAI: AI Nutrition and Meal Planner

NutriAI is a web and mobile-ready application that helps people plan meals, understand daily nutrition, avoid allergy conflicts, prepare grocery lists, track water and weight, and ask nutrition-related questions.

This README is written for both non-technical readers who want to understand the idea and technical readers who want to install, test, or extend the project.

> **Health notice:** NutriAI is an educational university project. Its calorie estimates, health-risk screening, and chatbot responses are not medical diagnoses or replacements for advice from a qualified healthcare professional.

## Submission Quick Reference

| Item | Prepared file or location |
| --- | --- |
| Source code | `backend/`, `frontend/`, `tools/`, `docker-compose.yml`, and project documentation |
| Main README | `README.md` |
| Presentation | `NutriAI_Class_Presentation.pptx` |
| Presentation source notes | `NutriAI_Class_Presentation.md` |
| Deployment/test URL | `Deployment_Link.txt` |
| Test login details | `Test_Credentials.txt` |
| Optional video demo | Not included, per submission request |

Team name: **NutriAI**

Test account for evaluator:

```text
Email: nutriai.test.01@example.com
Password: Password123
```

The application creates accounts through the registration screen. If the submitted database is empty, register the test account above first, then sign in with the same credentials.

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
- [Deployment link](#deployment-link)
- [Team member contributions](#team-member-contributions)
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

This section is a user acceptance test: follow it from top to bottom as if you are a new user. It provides example values for every visible input. Use a new email each time, such as `nutriai.test.01@example.com`, so older records do not change the result.

Record each step as **Pass** or **Fail**. If a step fails, save a screenshot, the displayed error, and the output of `docker compose logs --tail=100 backend`.

### Step 0: Confirm that the system is ready

1. Run `docker compose ps` in the project root.
2. Open http://localhost:8000/health.
3. Open http://localhost:8080.

Expected result:

- PostgreSQL is `healthy`, while the backend and frontend are `Up`.
- The health page displays `{"status":"ok"}`.
- The NutriAI **Sign In** screen opens without an error.

### Step 1: Create a test account

1. On the **Sign In** screen, choose the option to create an account.
2. Enter the following values.

| Input field | Test value |
| --- | --- |
| Full Name | `NutriAI Test User` |
| Email Address | `nutriai.test.01@example.com` |
| Password | `Password123` |
| Confirm Password | `Password123` |

3. Click **Create Account**.
4. After the dashboard opens, go to **Settings** and click **Sign Out**.
5. On **Sign In**, enter the same email and password, select **Remember me**, and click **Sign In**. This makes the later refresh checks meaningful.

Expected result:

- No validation error appears.
- The account is created, the user is signed in automatically, and the dashboard opens.
- Signing out and signing back in with **Remember me** succeeds.
- If the email already exists, change `01` to another number and try again.

### Step 2: Complete the health profile

1. Open **Profile** or **Health Profile** from the navigation menu.
2. Enter or select these values.

| Input field | Test value |
| --- | --- |
| Age | `25` |
| Gender | `Male` |
| Height (cm) | `175` |
| Weight (kg) | `75` |
| Activity Level | `Moderate (3-5 days/week)` |
| Exercise Frequency | `3-5 times/week` |
| Goal | `Lose Weight` |
| Dietary Preference | `High Protein` |
| Eating Habits | `Regular (3 meals/day)` |
| Health Conditions (Optional) | leave empty |

3. Confirm that the BMI, BMR, and calorie cards update.
4. Click **Save Profile**.
5. Refresh the browser, return to the profile, and check the fields again.

Expected result:

- A successful-save message appears.
- The BMI is approximately `24.49` and has a normal classification.
- BMR and target calories are positive and reasonable, not blank, negative, or `NaN`.
- Every entered value remains after refresh.

### Step 3: Check the dashboard

1. Open **Dashboard**.
2. Review the calorie, nutrition, water, weight, and quick-action sections.

Expected result:

- The dashboard loads without a red error banner.
- The profile-derived calorie target is displayed.
- New-user food totals can be zero, but they must not be negative or `NaN`.
- Selecting the **Meal Plan** quick action opens the Meal Planner.

### Step 4: Add an allergy

1. Open **Allergies**.
2. Enter the following values.

| Input field | Test value |
| --- | --- |
| Ingredient | `milk` |
| Severity | `High` |

3. Click **Add Allergy**.
4. Refresh the browser and return to **Allergies**.

Expected result:

- `milk` appears under **Tracked Allergies** with high severity.
- The allergy remains after refresh.
- This allergy will later be used to test whether the AI recommendation avoids milk, cheese, and yogurt.

### Step 5: Browse and search the food database

1. Open **Foods**.
2. In **Search foods...**, enter `rice`.
3. Confirm that only relevant foods are displayed.
4. Clear the search, choose one food, and click its favorite/heart control.
5. If available, open the substitute action for a food such as rice.
6. Leave the page and return.

Expected result:

- Seeded foods load and the search reacts to `rice`.
- The selected favorite remains marked after returning.
- The substitute dialog returns safe alternative foods and does not return an allergy-conflicting item.

### Step 6: Generate a daily AI meal plan

1. Open **Meal Planner**.
2. Select **Daily Plan**.
3. Choose today's date.
4. In **Plan settings**, enter the values below. These fixed inputs make the AI result easier to evaluate.

| Input field | Test value |
| --- | --- |
| Daily calories | `2200` |
| Protein (g) | `130` |
| Carbohydrates (g) | `240` |
| Fat (g) | `70` |
| Daily grocery budget estimate | `20` |
| Allergies (comma separated) | `milk` |
| Goal | `lose_weight` |
| Preference | `high-protein` |

5. Click **Generate Plan** and wait for the result.
6. Inspect every food in breakfast, lunch, dinner, and snack.

Expected result:

- Four sections appear: breakfast, lunch, dinner, and snack.
- Every section contains at least one food with calorie and macro information.
- The total is reasonably close to the `2200` kcal target; an exact match is not required because the system uses fixed database servings.
- No food name or allergen contains milk, cheese, or yogurt.
- The page does not freeze or return a server error.

This is the main AI acceptance test. A generated dairy item is a **Fail**, even if the rest of the plan looks correct.

### Step 7: Generate a weekly AI meal plan

1. Stay on **Meal Planner** and select **Weekly Plan**.
2. Keep the same plan settings.
3. Select a start date and click **Generate Plan**.

Expected result:

- Seven dated plans are displayed.
- Each day contains breakfast, lunch, dinner, and snack data.
- The plans contain some rotation instead of being accidentally stored as one duplicated database record.
- The `milk` restriction applies to all seven days.

### Step 8: Create and use a grocery list

1. In **Meal Planner**, click **Export to Grocery**.
2. Select the daily or weekly plans that were just generated.
3. Confirm the export.
4. Open **Grocery** from the navigation menu.
5. Select the generated grocery list.
6. Mark one item as purchased.
7. Refresh the page.

Expected result:

- A grocery list is generated from the selected meal plan or plans.
- It contains item names, quantities, and positive estimated costs.
- The total estimated cost is positive.
- The purchased item remains purchased after refresh.
- If the estimate exceeds the test budget, the interface clearly shows the budget comparison rather than crashing.

### Step 9: Log food and verify nutrition totals

1. Open **Log Food**.
2. Enter or select the values below.

| Input field | Test value |
| --- | --- |
| Meal Type | `Lunch` |
| Food Item | `Grilled Fish` or another available food |
| Quantity | `1` |
| Notes (Optional) | `Acceptance test meal` |

3. Note the current calorie and macro totals.
4. Click **Add to Log**.
5. Find the new entry in today's food log.

Expected result:

- The entry appears with the selected food, meal type, quantity, and notes.
- Today's calories, protein, carbohydrates, and fat increase according to the selected food.
- After refreshing, the entry and updated totals remain.

Now delete the same test entry.

Expected result:

- The entry disappears.
- The daily totals return to their previous values.
- Deleting it a second time is not possible through the interface.

### Step 10: Record weight and water

1. Open **Progress**.
2. Under **Log Weight**, enter:

| Input field | Test value |
| --- | --- |
| Weight (kg) | `74.5` |
| Date | today's date in `YYYY-MM-DD` format |

3. Click **Log Weight**.
4. Under **Log Water Intake**, enter `500` in **Amount (ml)** or click the `500ml` preset.
5. Click **Add Water**.
6. Refresh the page.

Expected result:

- Current weight becomes `74.5 kg` and a history entry appears for the selected date.
- Today's water increases by exactly `500 ml`.
- The progress cards and charts update.
- Weight and water values remain after refresh.

### Step 11: Test the AI nutrition assistant

1. Open **AI Assistant**.
2. Enter this question in the message field:

```text
Suggest a high-protein breakfast for my weight-loss goal. Remember that I am allergic to milk.
```

3. Send the message.

Expected result:

- A nutrition-related answer appears without the page freezing.
- The answer considers weight loss and the milk allergy.
- It must not recommend milk, cheese, yogurt, or another dairy food. If it does, record this step as **Fail**.
- A provider name or local-rule-based source may appear; either is acceptable.

To test provider fallback, stop Ollama or use `AI_PROVIDER=local`, restart the backend, and ask again. The assistant should still return a local response.

### Step 12: Test health-risk and image assistance

1. In **AI Assistant**, click **Check health risk**.

Expected result:

- A risk level and BMI appear.
- The result is presented as educational guidance, not a diagnosis.
- A medical disclaimer is included in the result area or response.

Next, click **Upload Food Photo** and choose an image with a generic filename such as `IMG_1234.jpg`.

Expected result:

- The system returns `Unknown Food` or explains that it cannot identify the image reliably.
- It does not pretend that filename matching is trained visual recognition.
- The upload does not crash the application.

### Step 13: Test session and logout behavior

1. Refresh the browser while signed in.
2. Confirm that the account and saved records remain available.
3. Open **Settings** and click **Sign Out**.
4. Confirm that refreshing after logout does not reopen private screens.
5. Sign in again with:

| Input field | Test value |
| --- | --- |
| Email | `nutriai.test.01@example.com` |
| Password | `Password123` |

Expected result:

- Signing out returns the user to the Sign In screen.
- Private screens are no longer visible after logout.
- **Remember me** preserves the valid session before logout, but logout removes it.
- Signing in again succeeds and restores the profile, allergy, plans, grocery data, weight, and water records.

### Negative-input checklist

Run these after the complete happy path so deliberate failures do not interrupt the main test.

| Test | Input or action | Expected result |
| --- | --- | --- |
| Duplicate registration | Register again with the same email | A clear duplicate-email error appears |
| Short password | Use `1234567` | The form requires at least eight characters |
| Password mismatch | Password `Password123`, confirmation `Password124` | The form says the passwords do not match |
| Empty allergy | Leave Ingredient empty and click Add Allergy | No empty allergy is created |
| Invalid food quantity | Enter `0` or `-1` | Input is rejected; nutrition totals do not change |
| Invalid weight | Enter `0` or a negative value | Input is rejected and history does not change |
| Invalid water | Enter a negative amount | Input is rejected and today's water does not decrease |
| Impossible restrictions | Enter several allergies covering all available foods | A clear no-safe-food explanation appears; no crash occurs |
| Unauthorized API | Call a protected endpoint in `/docs` without a token | The API returns `401 Unauthorized` |
| Cross-user privacy | Create a second account and inspect its records | The first user's private records are not visible |

### Test record template

Copy this table into an issue, report, or spreadsheet while testing:

| Step | Result | Actual result or problem | Evidence |
| --- | --- | --- | --- |
| 0. System ready | Pass / Fail |  | Screenshot/log |
| 1. Registration | Pass / Fail |  | Screenshot/log |
| 2. Profile | Pass / Fail |  | Screenshot/log |
| 3. Dashboard | Pass / Fail |  | Screenshot/log |
| 4. Allergy | Pass / Fail |  | Screenshot/log |
| 5. Foods | Pass / Fail |  | Screenshot/log |
| 6. Daily AI plan | Pass / Fail |  | Screenshot/log |
| 7. Weekly AI plan | Pass / Fail |  | Screenshot/log |
| 8. Grocery | Pass / Fail |  | Screenshot/log |
| 9. Food log | Pass / Fail |  | Screenshot/log |
| 10. Progress | Pass / Fail |  | Screenshot/log |
| 11. AI assistant | Pass / Fail |  | Screenshot/log |
| 12. Risk and image | Pass / Fail |  | Screenshot/log |
| 13. Session/logout | Pass / Fail |  | Screenshot/log |

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

## Deployment Link

The prepared local deployment URL is:

```text
http://localhost:8080
```

Run the full application with:

```powershell
docker compose up --build -d
```

Then open:

| Purpose | URL |
| --- | --- |
| Web application | http://localhost:8080 |
| Backend health check | http://localhost:8000/health |
| API documentation | http://localhost:8000/docs |

If a public hosting URL is added later, place it in `Deployment_Link.txt` and keep this local Docker URL as the backup testing link.

## Team Member Contributions

| Member | Contributions |
| --- | --- |
| NutriAI project member | Full-stack application implementation: Flutter user interface, FastAPI backend routes, SQLAlchemy models, PostgreSQL integration, Docker Compose setup, authentication, profile management, food database, allergies, meal planning, grocery lists, food logging, progress tracking, water tracking, AI service logic, testing guide, README, and presentation materials. |

Update the member name before final submission if the course requires individual names.

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
