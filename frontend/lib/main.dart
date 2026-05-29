import 'package:flutter/material.dart';

import 'api_client.dart';
import 'screens.dart';

void main() {
  runApp(AIMealPlanningApp(apiClient: ApiClient()));
}

class AIMealPlanningApp extends StatefulWidget {
  const AIMealPlanningApp({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<AIMealPlanningApp> createState() => _AIMealPlanningAppState();
}

class _AIMealPlanningAppState extends State<AIMealPlanningApp> {
  bool _authenticated = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Meal Planning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D6B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE1E6E3)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: _authenticated
          ? MainShell(
              apiClient: widget.apiClient,
              onLogout: () {
                widget.apiClient.clearToken();
                setState(() => _authenticated = false);
              },
            )
          : AuthScreen(
              apiClient: widget.apiClient,
              onAuthenticated: () => setState(() => _authenticated = true),
            ),
    );
  }
}

