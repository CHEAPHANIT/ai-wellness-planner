import 'package:ai_meal_planning/main.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_meal_planning/api_client.dart';

void main() {
  testWidgets('renders authentication screen', (tester) async {
    await tester.pumpWidget(NutriAIApp(apiClient: ApiClient()));

    expect(find.text('Welcome to NutriAI'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });
}
