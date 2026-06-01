import 'package:flutter/material.dart';

import 'api_client.dart';
import 'screens.dart';

void main() {
  runApp(NutriAIApp(apiClient: ApiClient()));
}

class NutriAIApp extends StatefulWidget {
  const NutriAIApp({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<NutriAIApp> createState() => _NutriAIAppState();
}

class _NutriAIAppState extends State<NutriAIApp> {
  bool _authenticated = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F8B5F),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F6EF),
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF17231F),
              displayColor: const Color(0xFF17231F),
            ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Color(0xFF0C3B2E),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFD9E5DE)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Color(0xFFFAFCFA),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F8B5F),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0C6B4B),
            minimumSize: const Size(0, 46),
            side: const BorderSide(color: Color(0xFF8BC7AA)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFFE8F4EC),
          side: BorderSide(color: Color(0xFFCFE4D6)),
          labelStyle: TextStyle(color: Color(0xFF1B4C3A)),
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
