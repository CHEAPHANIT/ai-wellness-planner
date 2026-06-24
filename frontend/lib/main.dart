import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool? _authenticated;
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final authenticated = await widget.apiClient.restoreToken();
    if (mounted) {
      setState(() {
        _authenticated = authenticated;
        _darkMode = preferences.getBool('nutriai_dark_mode') ?? false;
      });
    }
  }

  Future<void> _setDarkMode(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('nutriai_dark_mode', value);
    if (mounted) setState(() => _darkMode = value);
  }

  @override
  Widget build(BuildContext context) {
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2CCB8D),
      brightness: Brightness.dark,
      surface: const Color(0xFF151D1A),
    );
    return MaterialApp(
      title: 'NutriAI',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: const Color(0xFF0F1513),
        canvasColor: const Color(0xFF151D1A),
        dividerColor: const Color(0xFF33413B),
        hoverColor: const Color(0xFF64D6A5).withValues(alpha: 0.10),
        cardTheme: CardThemeData(
          elevation: 0,
          color: darkColorScheme.surface,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF33413B)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Color(0xFF102B22),
          foregroundColor: Color(0xFFF1F7F4),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: const Color(0xFF1B2521),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          labelStyle: TextStyle(color: darkColorScheme.onSurfaceVariant),
          hintStyle: TextStyle(color: darkColorScheme.onSurfaceVariant),
        ),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF151D1A)),
        navigationDrawerTheme: const NavigationDrawerThemeData(
          backgroundColor: Color(0xFF151D1A),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style:
              FilledButton.styleFrom(
                backgroundColor: const Color(0xFF159B65),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ).copyWith(
                elevation: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.hovered) ? 5 : 0,
                ),
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.hovered)
                      ? Colors.white.withValues(alpha: 0.12)
                      : null,
                ),
              ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style:
              OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64D6A5),
                minimumSize: const Size(0, 46),
                side: const BorderSide(color: Color(0xFF47705F)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.hovered)
                      ? const Color(0xFF213A30)
                      : null,
                ),
                elevation: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.hovered) ? 2 : 0,
                ),
              ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.hovered)
                  ? const Color(0xFF64D6A5).withValues(alpha: 0.12)
                  : null,
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.hovered)
                  ? const Color(0xFF64D6A5).withValues(alpha: 0.12)
                  : null,
            ),
          ),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFF1D352C),
          side: BorderSide(color: Color(0xFF365E4E)),
          labelStyle: TextStyle(color: Color(0xFFD8EEE4)),
        ),
      ),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F8B5F),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F6EF),
        hoverColor: const Color(0xFF0F8B5F).withValues(alpha: 0.08),
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
          style:
              FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F8B5F),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ).copyWith(
                elevation: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.hovered) ? 5 : 0,
                ),
                overlayColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.hovered)
                      ? Colors.white.withValues(alpha: 0.14)
                      : null,
                ),
              ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style:
              OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0C6B4B),
                minimumSize: const Size(0, 46),
                side: const BorderSide(color: Color(0xFF8BC7AA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ).copyWith(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.hovered)
                      ? const Color(0xFFE6F5ED)
                      : null,
                ),
                elevation: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.hovered) ? 2 : 0,
                ),
              ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.hovered)
                  ? const Color(0xFF0F8B5F).withValues(alpha: 0.10)
                  : null,
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.hovered)
                  ? const Color(0xFF0F8B5F).withValues(alpha: 0.10)
                  : null,
            ),
          ),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFFE8F4EC),
          side: BorderSide(color: Color(0xFFCFE4D6)),
          labelStyle: TextStyle(color: Color(0xFF1B4C3A)),
        ),
      ),
      home: _authenticated == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _authenticated!
          ? MainShell(
              apiClient: widget.apiClient,
              darkMode: _darkMode,
              onDarkModeChanged: _setDarkMode,
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
