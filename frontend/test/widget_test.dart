import 'package:ai_meal_planning/main.dart';
import 'package:ai_meal_planning/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_meal_planning/api_client.dart';

void main() {
  testWidgets('renders authentication screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(NutriAIApp(apiClient: ApiClient()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to NutriAI'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });

  testWidgets('compact layout uses a usable navigation drawer', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(500, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          apiClient: _FakeApiClient(),
          onLogout: () {},
          darkMode: false,
          onDarkModeChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('AI Assistant'), findsWidgets);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('dashboard quick action opens the planner', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(
      MaterialApp(
        home: MainShell(
          apiClient: _FakeApiClient(),
          onLogout: () {},
          darkMode: false,
          onDarkModeChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meal Plan'));
    await tester.pumpAndSettle();
    expect(find.text('Meal Planner'), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('restored session opens the dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(NutriAIApp(apiClient: _RestoredApiClient()));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Welcome to NutriAI'), findsNothing);
  });
}

class _RestoredApiClient extends _FakeApiClient {
  @override
  Future<bool> restoreToken() async => true;
}

class _FakeApiClient extends ApiClient {
  @override
  Future<Map<String, dynamic>> profile() async => {
    'age': 30,
    'gender': 'male',
    'height_cm': 175,
    'weight_kg': 75,
    'activity_level': 'moderate',
    'food_preference': 'balanced',
  };

  @override
  Future<Map<String, dynamic>?> goal() async => {
    'goal_type': 'maintain',
    'daily_calorie_target': 2200,
    'protein_target_g': 130,
    'carbs_target_g': 240,
    'fat_target_g': 70,
  };

  @override
  Future<List<Map<String, dynamic>>> foods({String? search}) async => [];

  @override
  Future<List<Map<String, dynamic>>> foodLogs() async => [];

  @override
  Future<Map<String, dynamic>> nutritionSummary(String date) async => {
    'calories': 0,
    'protein_g': 0,
    'carbs_g': 0,
    'fat_g': 0,
  };

  @override
  Future<Map<String, dynamic>> weightProgress() async => {
    'current_weight': 75,
    'target_weight': 72,
    'progress_percentage': 0,
    'history': [],
  };

  @override
  Future<Map<String, dynamic>> waterLog(String date) async => {
    'amount_ml': 0,
    'recommended_ml': 2600,
  };

  @override
  Future<List<Map<String, dynamic>>> mealPlans() async => [];

  @override
  Future<List<Map<String, dynamic>>> allergies() async => [];
}
