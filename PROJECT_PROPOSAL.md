# Project Proposal: NutriAI - AI Nutrition and Meal Planner

## 1. Project Overview

NutriAI is a full-stack web and mobile-ready application designed to help users plan meals, track nutrition, manage water intake, monitor weight progress, and receive basic AI-assisted nutrition guidance. The system combines a Flutter frontend, a FastAPI backend, and a PostgreSQL database to provide a practical digital health and meal planning platform.

The project focuses on personalized nutrition. Users can create an account, enter their body profile and health goals, generate meal plans, log foods, track daily nutrition, manage allergies, generate grocery lists, and ask nutrition-related questions through an AI assistant.

This project is suitable for a final-year university system because it includes real-world software engineering components: authentication, database design, REST API development, frontend UI design, AI service integration, Docker deployment, and user-centered health tracking features.

## 2. Problem Statement

Many users want to eat healthier but struggle to plan meals, understand nutritional intake, manage dietary restrictions, and maintain consistent progress. Existing meal planning tools may be too complex, too generic, or not adapted to local food preferences. Users also often need a simple way to connect their health profile, food choices, allergies, water intake, and progress tracking in one system.

NutriAI solves this problem by providing one integrated platform for meal planning, food logging, grocery generation, and AI-supported nutrition guidance.

## 3. Project Objectives

The main objectives of NutriAI are:

- To help users create personalized nutrition profiles and daily health goals.
- To generate meal recommendations based on user preferences, body profile, allergies, and target calories.
- To allow users to log foods and view daily nutrition summaries.
- To support grocery planning based on generated meal plans.
- To help users track hydration and weight progress over time.
- To provide basic AI-assisted nutrition support through chatbot, calorie prediction, food substitute, image recognition, and health risk features.
- To build a maintainable full-stack application using Flutter, FastAPI, PostgreSQL, SQLAlchemy, and Docker.

## 4. Target Users

The target users for this system include:

- Students and working adults who want simple meal planning support.
- People trying to lose weight, gain weight, or maintain a healthy lifestyle.
- Users who want to track calories, protein, carbohydrates, fat, water, and weight.
- Users with food allergies or dietary restrictions.
- Cambodian or local-food-focused users who want meal recommendations including familiar foods.

## 5. Technology Stack

| Layer | Technology |
| --- | --- |
| Frontend | Flutter |
| Backend API | Python FastAPI |
| Database | PostgreSQL |
| ORM | SQLAlchemy |
| Data validation | Pydantic |
| Authentication | JWT bearer token |
| AI and ML services | Python service layer with rule-based logic and integration points |
| Deployment | Docker Compose |
| Web server | Nginx for production frontend |

## 6. System Architecture

NutriAI uses a client-server architecture.

The Flutter application is the user interface. It communicates with the backend through REST API calls. The FastAPI backend handles authentication, business logic, AI service calls, and database operations. PostgreSQL stores users, profiles, foods, meal plans, food logs, grocery lists, allergies, water logs, weight progress, chatbot records, and health risk predictions.

The project can run locally during development or through Docker Compose for easier setup. Docker Compose starts three services: PostgreSQL, backend API, and frontend web server.

## 7. Main Features

### 7.1 User Registration and Login

The system allows users to create an account using email, full name, and password. Passwords are not stored directly. They are hashed before being saved in the database.

After registration, users can log in with their email and password. The backend returns a JWT access token, which the frontend uses to authenticate future requests.

This feature is important because every user has personal profile data, meal plans, food logs, allergies, water logs, and progress records. Authentication ensures that each user can only access their own data.

Main capabilities:

- Register a new user account.
- Log in with email and password.
- Store password securely using hashing.
- Use JWT token authentication.
- Get current logged-in user information.
- Log out on the frontend by clearing the saved token.

### 7.2 Forgot Password and OTP Verification

The system includes a simple password recovery flow. Users can request a password reset by entering their email. The backend generates a demo OTP code. After the OTP is verified, the user can change the password.

In a production system, this OTP would be sent through email or SMS. For this project, the OTP is returned for demonstration purposes.

Main capabilities:

- Request password reset.
- Generate OTP code.
- Verify OTP code.
- Change password using verified OTP.
- Change password using old password when available.

### 7.3 User Health Profile

The health profile feature stores user information that is needed for personalized nutrition recommendations. Users can enter their age, gender, height, weight, activity level, goal, dietary preference, health conditions, eating habits, and exercise frequency.

The backend uses this information to calculate health and nutrition values such as BMI, BMI status, BMR, maintenance calories, and target daily calories.

Main capabilities:

- Save personal body information.
- Save lifestyle and activity information.
- Save dietary preference and health conditions.
- Calculate BMI.
- Calculate BMR.
- Estimate maintenance calories.
- Estimate target calories based on user goal.

### 7.4 Goal Management

The system stores the user's nutrition and body goal. This can include target weight, calorie target, protein target, carbohydrate target, and fat target.

This feature helps the system compare actual daily intake against user targets. It also improves the meal planning experience because generated meals can be aligned with the user's goals.

Main capabilities:

- Store target weight.
- Store target daily calories.
- Store macro targets.
- Retrieve the active user goal.
- Use goals in dashboard and meal planning workflows.

### 7.5 Dashboard

The dashboard gives users a quick summary of their current nutrition and profile status. It shows key statistics such as calories today, protein intake, number of foods in the database, and profile age.

The dashboard acts as the main entry point after login. It helps users understand their health data at a glance without navigating through every screen.

Main capabilities:

- Show calories consumed today.
- Show protein consumed today.
- Show available foods count.
- Show basic profile information.
- Display food database preview.
- Provide a quick overview of user progress.

### 7.6 Food Database

The food database stores food items with nutritional information. Each food can include calories, protein, carbohydrates, fat, serving size, and other useful food details.

The system includes seeded Cambodian and common foods such as Bai Sach Chrouk, Kuy Teav, Num Banh Chok, Grilled Fish, Rice, Chicken, and vegetables. This makes the project more relevant to local users and avoids relying only on generic western meals.

Main capabilities:

- View available foods.
- Search foods by keyword.
- Add new food items through the backend API.
- Store nutrition values for each food.
- Use foods in food logging and meal planning.

### 7.7 Food Logging

Food logging allows users to record what they eat during the day. A user selects a food, meal type, quantity, and optional notes. The backend saves the record and uses it to calculate daily nutrition totals.

This feature is important because meal planning alone is not enough. Users also need to track what they actually eat to understand their progress.

Main capabilities:

- Log a food item.
- Select meal type such as breakfast, lunch, dinner, or snack.
- Enter quantity.
- Add notes.
- View logged foods.
- Connect food logs to daily nutrition summaries.

### 7.8 Daily Nutrition Summary

The nutrition summary calculates total calories, protein, carbohydrates, and fat for a selected date. It can also compare intake with user targets and return remaining calories or a nutrition score.

This feature helps users understand whether they are under, near, or over their daily targets.

Main capabilities:

- Calculate daily calories.
- Calculate daily protein, carbohydrates, and fat.
- Show remaining calories.
- Provide a nutrition score.
- Support dashboard and food log screens.

### 7.9 AI Calorie Prediction

The AI calorie prediction feature estimates recommended calories based on user data such as age, gender, height, weight, activity level, and goal. It supports the health profile and meal planning features.

This feature can start with deterministic formula-based logic and later be improved with a machine learning model.

Main capabilities:

- Accept user health information.
- Predict daily calorie needs.
- Return estimated target calories.
- Support profile and meal planning recommendations.

### 7.10 AI Meal Recommendation

The meal recommendation feature suggests meals based on user requirements such as calorie target, macronutrient targets, food preference, and allergies.

The backend service can recommend breakfast, lunch, dinner, and snack options. It uses the available food database and user restrictions to produce suitable meal ideas.

Main capabilities:

- Generate meal recommendations.
- Consider calorie target.
- Consider protein, carbohydrate, and fat targets.
- Consider food preference.
- Avoid allergic ingredients where possible.
- Return structured meal data for frontend display.

### 7.11 Daily Meal Plan Generation

The system can generate and save a daily meal plan. A meal plan includes meal sections such as breakfast, lunch, dinner, and snack. Each section can contain selected foods, calories, protein, carbohydrates, and fat.

Meal plan details are stored as JSON in the database. This makes the project easier to maintain while still supporting structured meal output.

Main capabilities:

- Generate daily meal plan.
- Save generated meal plan.
- Store meal details in the database.
- Retrieve saved meal plans.
- Display meal plan details in the frontend.

### 7.12 Weekly Meal Plan Generation

The weekly meal plan feature expands the daily planner by generating meal plans for multiple days. This helps users prepare ahead instead of planning one day at a time.

This feature is useful for students, families, and busy users because it supports weekly food preparation and grocery planning.

Main capabilities:

- Generate multiple daily plans for a week.
- Save weekly meal plan data.
- Display meal plans by day.
- Reuse existing recommendation logic.
- Support grocery generation from planned meals.

### 7.13 Grocery List Generation

The grocery feature automatically creates a grocery list based on a meal plan. It helps users know what ingredients or food items they need to buy.

The system can generate grocery items from the latest meal plan or a selected meal plan. It can also include estimated cost and purchased status.

Main capabilities:

- Generate grocery list from meal plan.
- Store grocery list and grocery items.
- Show estimated total cost.
- Show item quantity.
- Mark items as purchased.
- Support budget-aware shopping in future improvements.

### 7.14 Allergy Management

The allergy feature lets users record ingredients or foods they should avoid. Each allergy can include an ingredient name and severity level.

This feature improves personalization and safety because meal recommendations can avoid foods that may cause allergic reactions.

Main capabilities:

- Add allergy record.
- View allergy records.
- Delete allergy records.
- Store severity information.
- Use allergy data in meal recommendations.

### 7.15 Food Substitute Recommendation

The food substitute feature suggests alternative foods when a user cannot eat a certain food because of allergy, preference, or availability.

For example, if a user cannot eat a specific ingredient, the system can suggest another food with similar nutrition value or meal role.

Main capabilities:

- Accept a food name.
- Return substitute suggestions.
- Support allergy-aware eating.
- Improve meal flexibility.

### 7.16 Water Intake Tracking

The water tracking feature allows users to log daily water intake. Users can save the amount of water consumed in milliliters and view the water record for a specific date.

Hydration is an important part of health, so including it makes the application more complete than a simple meal planner.

Main capabilities:

- Log water intake.
- Retrieve water intake by date.
- Show water progress on the progress screen.
- Support daily hydration monitoring.

### 7.17 Weight Progress Tracking

The progress feature allows users to record their weight over time. The backend returns a summary including current weight, target weight, and progress percentage.

This feature helps users see whether they are moving toward their goal. It is especially useful for users who want to lose weight, gain weight, or maintain weight.

Main capabilities:

- Record weekly or periodic weight.
- Retrieve weight progress summary.
- Compare current weight with target weight.
- Calculate progress percentage.
- Display progress in the frontend.

### 7.18 AI Nutrition Chatbot

The AI assistant lets users ask nutrition-related questions. The system currently supports a local rule-based fallback and includes an integration point for OpenAI or Gemini through an API key.

This feature gives users simple guidance without needing to search manually. It can answer general questions about dieting, calories, hydration, meal choices, and healthy habits.

Main capabilities:

- Accept user nutrition questions.
- Return chatbot response.
- Save chatbot interaction history.
- Work without paid API keys using fallback logic.
- Support hosted AI model integration later.

### 7.19 Food Image Recognition

The image recognition feature allows users to upload a food image. The backend has a service layer prepared for TensorFlow or OpenCV integration and also includes a fallback suitable for demonstration.

This feature can later be expanded to identify food from images and estimate nutrition automatically.

Main capabilities:

- Upload food image.
- Process image in backend service.
- Return predicted food information.
- Provide a foundation for computer vision integration.

### 7.20 Health Risk Prediction

The health risk feature provides a basic educational risk prediction based on user health information such as BMI, activity, eating habits, and other profile data.

The system includes a medical disclaimer because the result is not a diagnosis. It should be used only for educational and awareness purposes.

Main capabilities:

- Accept health profile input.
- Calculate basic risk level.
- Return recommendations.
- Save health risk prediction.
- Display a medical disclaimer.

## 8. Non-Functional Requirements

### 8.1 Security

The system uses hashed passwords and JWT authentication. Private user data is protected by backend dependency checks that require a valid logged-in user.

### 8.2 Usability

The Flutter interface is designed with clear screens for authentication, dashboard, profile, planner, food log, assistant, and progress. Users can navigate through the system without needing technical knowledge.

### 8.3 Maintainability

The backend is divided into routes, schemas, models, services, database setup, and core configuration. This structure makes the project easier to extend and debug.

### 8.4 Scalability

The project can be extended with more foods, more AI logic, more user data, and additional frontend screens. PostgreSQL provides a reliable base for structured data.

### 8.5 Portability

Docker Compose allows the system to run on another computer with fewer setup steps. The frontend can also run through Flutter directly during development.

## 9. Database Design Summary

The system uses PostgreSQL tables for:

- Users
- User profiles
- Goals
- Foods
- Food logs
- Nutrition logs
- Meal plans
- Grocery lists
- Grocery items
- Allergies
- Water logs
- Weight progress
- Chatbot messages
- Health risk predictions

This database structure supports personalization, history tracking, and AI-related outputs.

## 10. API Modules

The backend provides REST API modules for:

- Authentication
- Profile and goals
- Foods
- Meal plans
- Food logs and nutrition summaries
- Grocery lists
- Progress tracking
- Water tracking
- Allergies
- AI services

These APIs allow the Flutter frontend to communicate with the backend in a structured way.

## 11. Future Feature Expansion

The following features can be added in future versions:

### 11.1 Meal Calendar

A weekly calendar view can show breakfast, lunch, dinner, and snacks for each day. Users could edit meals directly from the calendar.

### 11.2 Favorite Meals

Users could save favorite meals and reuse them in future meal plans. This would make the system faster and more personalized.

### 11.3 Edit and Delete Food Logs

Users should be able to correct mistakes by editing or deleting logged foods.

### 11.4 Advanced Nutrition Charts

The dashboard could include charts for calories, protein, water intake, and weight progress over time.

### 11.5 Admin Food Management

An admin role could manage the food database, approve new foods, and update nutrition values.

### 11.6 PDF or CSV Export

Users could export weekly meal plans, nutrition summaries, or grocery lists as PDF or CSV files.

### 11.7 Notification Reminders

The system could remind users to drink water, log meals, or check their progress.

### 11.8 Improved AI Image Recognition

The image recognition feature could be connected to a trained food classification model to identify foods and estimate calories from images.

## 12. Expected Benefits

NutriAI provides several benefits:

- Helps users make healthier food decisions.
- Saves time by generating meal plans automatically.
- Supports local food preferences.
- Helps users manage allergies and substitutions.
- Encourages consistent hydration and weight tracking.
- Provides a practical example of AI-assisted health software.
- Demonstrates full-stack development skills using modern tools.

## 13. Project Limitations

The system is an educational project and should not replace professional medical advice. Health risk prediction is basic and must be treated as informational only.

The AI features can work with fallback logic, but advanced real-world accuracy would require better datasets, trained models, professional nutrition validation, and external AI service integration.

## 14. Conclusion

NutriAI is a practical AI nutrition and meal planning platform that combines meal recommendation, nutrition tracking, grocery planning, water logging, progress monitoring, and AI guidance. The project demonstrates strong full-stack development concepts and provides a useful solution for users who want a simpler way to manage daily nutrition and health goals.

With future enhancements such as meal calendars, favorite meals, charts, notifications, and improved AI image recognition, NutriAI can become a more complete digital wellness assistant.
