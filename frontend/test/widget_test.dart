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

  testWidgets('dark mode toggle changes the application theme', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(NutriAIApp(apiClient: _RestoredApiClient()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Dark Mode'), findsOneWidget);

    await tester.ensureVisible(find.text('Dark Mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('nutriai_dark_mode'), isTrue);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('saved dark mode is restored when the app starts', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'nutriai_dark_mode': true});
    await tester.pumpWidget(NutriAIApp(apiClient: _RestoredApiClient()));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('profile uses readable colors in dark mode', (tester) async {
    SharedPreferences.setMockInitialValues({'nutriai_dark_mode': true});
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(NutriAIApp(apiClient: _RestoredApiClient()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    final heading = tester.widget<Text>(find.text('Health Profile'));
    final sectionTitle = tester.widget<Text>(find.text('Body Information'));
    final firstField = tester.widget<TextField>(
      find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(TextField),
      ),
    );

    expect(heading.style?.color, const Color(0xFFF1F7F4));
    expect(sectionTitle.style?.color, const Color(0xFFF1F7F4));
    expect(firstField.style?.color, const Color(0xFFF1F7F4));
    expect(firstField.decoration?.fillColor, const Color(0xFF1B2521));

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('dark quick actions stay readable and open their pages', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'nutriai_dark_mode': true});
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(NutriAIApp(apiClient: _RestoredApiClient()));
    await tester.pumpAndSettle();

    const actions = <int, (String, String)>{
      3: ('Log Food', 'Food Logging'),
      4: ('Meal Plan', 'Meal Planner'),
      6: ('Track Progress', 'Progress Tracking'),
      8: ('AI Assistant', 'NutriAI Assistant'),
    };

    for (final entry in actions.entries) {
      final action = find.byKey(ValueKey('quick-action-${entry.key}'));
      final label = tester.widget<Text>(
        find.descendant(of: action, matching: find.text(entry.value.$1)),
      );
      expect(label.style?.color, const Color(0xFF17231F));

      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text(entry.value.$2), findsWidgets);

      if (entry.key == 4) {
        final dailyPlan = tester.widget<Text>(find.text('Daily Plan'));
        final weeklyPlan = tester.widget<Text>(find.text('Weekly Plan'));
        final dateLabel = tester.widget<Text>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                (widget.data?.startsWith('Today - ') ?? false),
          ),
        );
        expect(dailyPlan.style?.color, const Color(0xFFF1F7F4));
        expect(weeklyPlan.style?.color, const Color(0xFFABBAB3));
        expect(dateLabel.style?.color, const Color(0xFFF1F7F4));
      }

      if (entry.key != actions.keys.last) {
        await tester.tap(find.text('Dashboard').first);
        await tester.pumpAndSettle();
      }
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('add-food dropdown has contrasting dark-mode colors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'nutriai_dark_mode': true});
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(NutriAIApp(apiClient: _RestoredApiClient()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Foods'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Food'));
    await tester.pumpAndSettle();

    final field = find.byKey(const ValueKey('add-food-category'));
    final dropdown = tester.widget<DropdownButton<String>>(
      find.descendant(of: field, matching: find.byType(DropdownButton<String>)),
    );
    expect(dropdown.dropdownColor, const Color(0xFF151D1A));
    expect(dropdown.style?.color, const Color(0xFFF1F7F4));

    await tester.tap(field);
    await tester.pumpAndSettle();
    final menuLabels = tester.widgetList<Text>(find.text('Meal'));
    expect(menuLabels, isNotEmpty);
    expect(
      menuLabels.every(
        (label) => label.style?.color == const Color(0xFFF1F7F4),
      ),
      isTrue,
    );

    await tester.binding.setSurfaceSize(null);
  });
}

class _RestoredApiClient extends _FakeApiClient {
  @override
  Future<bool> restoreToken() async => true;
}

class _FakeApiClient extends ApiClient {
  @override
  Future<Map<String, dynamic>> me() async => {
    'id': 1,
    'email': 'test@example.com',
    'full_name': 'Test User',
    'is_active': true,
    'created_at': '2026-01-01T00:00:00Z',
  };

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
