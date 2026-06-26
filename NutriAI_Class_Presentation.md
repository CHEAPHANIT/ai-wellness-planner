# NutriAI: AI Nutrition and Meal Planner

Focused Class Presentation - 12 Slides

---

## Slide 1: NutriAI

**AI Nutrition and Meal Planner**

- Presented by: Your Name
- Course: Your Course Name
- Date: June 2026

Speaker notes:

NutriAI is a full-stack nutrition application that turns personal health information into meal recommendations, grocery preparation, daily tracking, and AI-assisted guidance.

---

## Slide 2: Project Overview

- Full-stack nutrition and meal-planning application
- Built for personalized daily food decisions
- Supports profile-based calorie targets, allergies, preferences, and grocery planning
- Includes practical AI-assisted features rather than one isolated model

Speaker notes:

The project connects meal planning with real user behavior. It helps the user decide what to eat, prepare groceries, track progress, and ask nutrition questions in one system.

---

## Slide 3: Problem Statement

- Healthy meal planning requires calories, macros, allergies, preferences, budget, and habits to be considered together.
- Many users do not know how to translate nutrition goals into actual meals.
- Generic plans can recommend unsafe foods for users with allergies.
- Tracking tools and planning tools are often separated.

Speaker notes:

The main problem is not only finding a healthy food. The harder problem is choosing meals that fit the user's body data, goal, restrictions, and daily routine.

---

## Slide 4: Proposed Solution

- Create an account and complete a health profile
- Calculate BMI, BMR, maintenance calories, and goal calories
- Store allergies and preferences
- Generate daily or weekly meal plans
- Convert plans into grocery lists
- Track food, water, and weight progress
- Ask an AI nutrition assistant for contextual guidance

Speaker notes:

NutriAI solves the problem by connecting the full workflow: profile, restriction handling, recommendation, grocery preparation, tracking, and guidance.

---

## Slide 5: System Architecture

| Layer | Technology | Responsibility |
| --- | --- | --- |
| Frontend | Flutter and Dart | Screens, forms, charts, navigation |
| Backend | FastAPI and Python | REST API, validation, authentication, AI logic |
| Database | PostgreSQL | Users, profiles, foods, plans, logs, and history |
| Deployment | Docker Compose and Nginx | Runs database, backend, and web frontend together |

Speaker notes:

Flutter sends JSON requests to FastAPI. The backend authenticates users, runs services, reads and writes PostgreSQL through SQLAlchemy, then returns JSON responses to the interface.

---

## Slide 6: AI Technologies and Models Used

NutriAI is a hybrid intelligent system:

- Heuristic combinational search for meal recommendation
- Mifflin-St Jeor formula for calorie target calculation
- Nutrition-distance ranking for food substitutes
- Rule-based health-risk screening
- Optional LLM chatbot using Ollama or OpenAI
- Local deterministic chatbot fallback
- Conservative filename-based food-photo prototype

Speaker notes:

Not every AI feature is a neural network. The project uses explainable AI-style scoring, formulas, ranking, rules, and optional language-model guidance.

---

## Slide 7: Key Features

- Authentication, profile setup, and secure JWT sessions
- Food database with Cambodian and general foods
- Allergy tracking and allergy-safe recommendations
- Daily and weekly meal plan generation
- Grocery list generation with estimated costs
- Food logging and nutrition totals
- Water and weight progress tracking
- AI assistant, health-risk check, food substitutes, and photo assistance

Speaker notes:

The key feature is integration. Meal planning, grocery preparation, and tracking are connected instead of being separate tools.

---

## Slide 8: AI Detail - Meal Recommendation

1. Load foods from PostgreSQL.
2. Remove foods matching user allergies.
3. Apply preference and goal rules.
4. Divide daily targets across meals.
5. Build combinations of one to three foods.
6. Score calories, protein, carbohydrates, fat, category fit, and budget.
7. Select the lowest-scoring candidate.

```text
score = calorie gap + macro gaps + category penalty + budget penalty
```

Speaker notes:

This is exhaustive combinational search with heuristic scoring. A lower score means the meal is closer to the user's calorie, macro, category, and budget requirements.

---

## Slide 9: AI Detail - Chatbot and Supporting Logic

### Nutrition chatbot

- Uses profile context, allergies, goals, and today's calories
- Can use Ollama, OpenAI, or local mode
- Falls back to local rule-based guidance if an external provider fails

### Supporting AI services

- Calorie model estimates BMR and target calories
- Food substitutes rank nutritionally similar alternatives
- Health-risk screening explains BMI, habits, and exercise signals
- Image assistance returns unknown or low-confidence matches instead of inventing predictions

Speaker notes:

The assistant is designed to be useful even without an external AI provider. The supporting services are transparent so users can understand why the system produced an answer.

---

## Slide 10: Results and Demo Flow

Prepared demo path:

1. Register or log in with the test account
2. Complete a health profile
3. Add a milk allergy
4. Generate a daily meal plan
5. Confirm dairy foods are excluded
6. Generate a weekly plan
7. Export to a grocery list
8. Log food, water, and weight
9. Ask the nutrition assistant a milk-allergy question

Expected result:

- The system runs through Docker at `http://localhost:8080`
- Backend health check returns `{"status":"ok"}`
- Automated baseline: backend service tests and Flutter widget tests are included

Speaker notes:

The demo should prove the main AI behavior: the generated plan responds to user targets and avoids the recorded allergy. The grocery and tracking screens show that recommendations can become daily actions.

---

## Slide 11: Challenges and Lessons Learned

- Allergy safety must be handled before scoring meal candidates.
- AI provider failures should not break the app, so local fallback is important.
- Food-photo recognition should be honest about confidence when no trained vision model exists.
- Docker simplifies setup but environment variables must be documented clearly.
- End-to-end testing is necessary because meal planning touches profiles, foods, allergies, plans, and groceries.

Speaker notes:

The biggest lesson is that practical AI systems need reliability and transparency. A simple explainable answer is better than a confident but unsafe answer.

---

## Slide 12: Conclusion

NutriAI turns personal data into practical food decisions by connecting:

- Personalization
- Allergy awareness
- Meal planning
- Grocery preparation
- Nutrition tracking
- AI-assisted guidance

**One connected experience to personalize, plan, shop, track, and improve.**

Speaker notes:

NutriAI's main value is integration. It does not treat recommendations, shopping, and tracking as separate problems. Its hybrid AI approach keeps the core decisions understandable and extensible.
