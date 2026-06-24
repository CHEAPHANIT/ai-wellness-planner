# NutriAI: AI Nutrition and Meal Planner

Class Presentation Slide Deck

---

## Slide 1: Project Title

# NutriAI

## AI Nutrition and Meal Planner

Presented by: _Your Name_

Course: _Your Course Name_

Date: _Presentation Date_

Speaker notes:

Introduce NutriAI as a full-stack web application that helps users plan meals, track nutrition, manage allergies, generate grocery lists, and receive basic AI-assisted nutrition support.

---

## Slide 2: Problem Statement

Many people want to eat healthier, but meal planning is difficult because they must consider:

- Daily calorie needs
- Protein, carbohydrate, and fat targets
- Allergies and dietary restrictions
- Food preferences
- Budget and grocery planning
- Actual food intake compared with the plan

Speaker notes:

Explain that users often use separate tools for diet tracking, grocery lists, and health goals. NutriAI combines these into one system.

---

## Slide 3: Project Goal

The goal of NutriAI is to build an intelligent meal-planning system that recommends meals based on:

- User health profile
- Body goal
- Food allergies
- Dietary preference
- Nutrition targets
- Available foods
- Grocery budget

Speaker notes:

The main idea is personalization. The system does not recommend the same meal to every user. It uses user data to make the result more useful.

---

## Slide 4: Target Users

NutriAI is designed for:

- Students and working adults
- Users who want to lose, gain, or maintain weight
- Users who want to track calories and macronutrients
- Users with allergies or food restrictions
- Cambodian/local-food-focused users

Speaker notes:

Mention that the system includes familiar foods such as Cambodian meals, making it more relevant than generic meal planners.

---

## Slide 5: Main Features

NutriAI supports:

- Register, login, logout, and password reset
- Health profile management
- BMI, BMR, and calorie target calculation
- Food database with search and favorite foods
- Allergy management
- Daily and weekly meal planning
- Grocery list generation
- Food, water, and weight tracking
- AI assistant and food substitute suggestions

Speaker notes:

Give a quick overview. Do not explain every feature deeply yet; this slide shows the system scope.

---

## Slide 6: User Journey

```text
Create account
      ↓
Complete health profile
      ↓
Add allergies and preferences
      ↓
Generate meal plan
      ↓
Export grocery list
      ↓
Log food, water, and weight
      ↓
Track progress and ask AI assistant
```

Speaker notes:

Walk through the normal flow from a new user to daily usage. This helps the audience understand how screens connect.

---

## Slide 7: System Architecture

| Layer | Technology | Responsibility |
| --- | --- | --- |
| Frontend | Flutter | User interface, navigation, forms, charts |
| Backend | FastAPI | API routes, validation, business logic |
| Database | PostgreSQL | Stores users, foods, profiles, plans, logs |
| ORM | SQLAlchemy | Maps Python models to database tables |
| Auth | JWT | Protects user-specific data |
| Deployment | Docker Compose | Runs frontend, backend, and database |

Speaker notes:

Explain that the app uses a client-server architecture. Flutter sends REST requests to FastAPI, FastAPI reads/writes PostgreSQL, then returns JSON responses.

---

## Slide 8: How One Request Works

Example: Generate meal plan

```text
Flutter Meal Planner Screen
        ↓
REST API request
        ↓
FastAPI route validates input
        ↓
Meal recommendation service scores foods
        ↓
PostgreSQL saves meal plan
        ↓
Flutter displays result
```

Speaker notes:

Use this slide to explain the real backend process. The frontend is not doing all the work; it communicates with the backend service.

---

## Slide 9: AI and Intelligent Logic

NutriAI uses practical AI-assisted logic:

- Meal recommendation using heuristic scoring
- Calorie target calculation using health formulas
- Food substitute suggestions based on nutrition similarity
- Health-risk screening using transparent rules
- Nutrition chatbot with local or external AI provider support
- Conservative food-photo assistance

Speaker notes:

Clarify that this project combines formula-based logic, rule-based logic, and optional AI provider integration. This is safer and more explainable for a health-related student project.

---

## Slide 10: Meal Recommendation Logic

The meal recommender:

1. Loads available foods
2. Removes foods that conflict with allergies
3. Applies dietary preference rules
4. Builds possible food combinations
5. Scores each combination against targets
6. Selects the best matching meal

Simplified score:

```text
score =
  calorie difference
+ protein difference
+ carbohydrate difference
+ fat difference
+ category penalty
+ budget penalty
```

Speaker notes:

Explain that lower score means a better match. This makes the recommendation process understandable and easier to improve later.

---

## Slide 11: Database Design

Main data stored in PostgreSQL:

- Users and authentication data
- Health profiles and goals
- Food database records
- Allergies
- Meal plans
- Grocery items
- Food logs
- Water logs
- Weight progress
- Chatbot records and health-risk results

Speaker notes:

Mention that the database supports persistence, so user data remains after refresh or restart.

---

## Slide 12: Frontend Screens

The Flutter application includes:

- Dashboard
- Profile
- Foods
- Log Food
- Meal Planner
- Grocery
- Progress
- Allergies
- AI Assistant
- Settings

Speaker notes:

This is a good place to switch briefly to a live demo if allowed. Show the dashboard, profile, meal planner, and dark mode.

---

## Slide 13: Recent UI Improvements

The interface was improved with:

- Dark mode support across the system
- Better text contrast in dark mode
- Hover effects on cards and buttons
- Clickable quick action cards
- Theme-aware dropdown colors
- More consistent card styling

Speaker notes:

Connect this to usability. A health app needs to be readable and pleasant because users may use it daily.

---

## Slide 14: Testing and Validation

The project includes:

- Flutter widget tests
- Authentication flow testing
- Navigation testing
- Dark mode readability testing
- Quick action button testing
- Dropdown contrast testing
- Backend route and service structure for API validation

Speaker notes:

Mention that testing helped catch visual issues, especially dark mode contrast and navigation behavior.

---

## Slide 15: Deployment

NutriAI can run with Docker Compose:

```powershell
docker compose up --build -d
docker compose ps
```

Services:

- PostgreSQL database
- FastAPI backend
- Flutter web frontend served through Nginx

Speaker notes:

Explain that Docker makes the project easier to run on another computer because it starts the whole system with one command.

---

## Slide 16: Challenges

Main challenges during development:

- Connecting Flutter frontend with FastAPI backend
- Managing authenticated user data
- Designing personalized meal recommendation logic
- Handling allergies safely
- Keeping dark mode readable
- Making the system easy to run through Docker

Speaker notes:

Be honest here. Challenges show that the project involved real engineering decisions, not only UI design.

---

## Slide 17: Future Improvements

Possible improvements:

- Train a real food image recognition model
- Add email/SMS OTP for real password recovery
- Improve recommendation algorithm with machine learning
- Add nutrition history charts
- Support more Cambodian foods and prices
- Add admin dashboard for food data management
- Deploy online for public access

Speaker notes:

Show that the current version is complete enough for demonstration but has a clear path for future work.

---

## Slide 18: Conclusion

NutriAI provides an integrated nutrition planning experience by combining:

- Personal health profiles
- Meal recommendation
- Allergy-aware food filtering
- Grocery planning
- Nutrition tracking
- AI-assisted guidance
- Full-stack web architecture

Speaker notes:

End by emphasizing the value: the system helps users make better food decisions through personalization, tracking, and practical AI support.

---

## Optional Demo Flow

If you do a live demo, use this order:

1. Register or log in
2. Open Dashboard
3. Complete or show Profile
4. Search food database
5. Generate a meal plan
6. Export grocery list
7. Log food
8. Show Progress
9. Toggle dark mode
10. Ask AI Assistant a simple question

Demo tip:

Prepare sample data before class so the system already has profile, food logs, and meal plan results.

---

## Short Presentation Script

Good morning/afternoon everyone. Today I will present my project, NutriAI, an AI nutrition and meal planner.

The problem I wanted to solve is that healthy meal planning is difficult because users need to think about calories, macronutrients, allergies, preferences, and budget at the same time. Many tools only focus on one part of the problem, so I built NutriAI as one integrated platform.

The system allows users to create an account, complete a health profile, calculate BMI and calorie targets, manage allergies, generate meal plans, create grocery lists, log food, track water and weight, and ask nutrition-related questions through an AI assistant.

Technically, NutriAI is a full-stack application. The frontend is built with Flutter. The backend uses Python FastAPI, and the database is PostgreSQL. The system uses JWT authentication so each user can access only their own data. Docker Compose is used to run the frontend, backend, and database together.

The main intelligent feature is the meal recommendation service. It loads available foods, removes foods that conflict with allergies, applies user preferences, builds possible combinations, scores them against calorie, macro, category, and budget targets, then selects the best matching meal.

This project also includes AI-assisted services such as food substitute suggestions, health-risk screening, calorie recommendation, chatbot support, and food-photo assistance. For safety, the health-related outputs are educational and not medical diagnosis.

During development, I also improved the user interface with dark mode, hover effects, clickable quick actions, and better color contrast. Testing was used to verify navigation, authentication, dark mode readability, and UI behavior.

In conclusion, NutriAI combines meal planning, nutrition tracking, allergy management, grocery planning, and AI guidance into one practical system. In the future, it could be improved with a trained food image recognition model, real email OTP, more food data, and online deployment.

Thank you.
