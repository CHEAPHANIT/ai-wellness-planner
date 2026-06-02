import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';

const _leaf = Color(0xFF0F8B5F);
const _leafDark = Color(0xFF0C3B2E);
const _amber = Color(0xFFF2A93B);
const _coral = Color(0xFFE76F51);
const _blue = Color(0xFF3178C6);

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.apiClient,
    required this.onAuthenticated,
  });

  final ApiClient apiClient;
  final VoidCallback onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'demo@example.com');
  final _name = TextEditingController(text: 'Demo User');
  final _password = TextEditingController(text: 'password123');
  bool _register = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_register) {
        await widget.apiClient.register(
          email: _email.text.trim(),
          fullName: _name.text.trim(),
          password: _password.text,
        );
      } else {
        await widget.apiClient.login(email: _email.text.trim(), password: _password.text);
      }
      widget.onAuthenticated();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0C3B2E), Color(0xFF0F8B5F), Color(0xFFF2F6EF)],
            stops: [0, 0.48, 1],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;
                  return Flex(
                    direction: compact ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (compact)
                        const AuthBrandPanel()
                      else
                        const Expanded(
                          flex: 5,
                          child: Padding(
                            padding: EdgeInsets.only(right: 36),
                            child: AuthBrandPanel(),
                          ),
                        ),
                      if (compact) const SizedBox(height: 24),
                      if (compact)
                        AppCard(
                          padding: const EdgeInsets.all(26),
                          child: _AuthForm(
                            formKey: _formKey,
                            register: _register,
                            loading: _loading,
                            error: _error,
                            email: _email,
                            name: _name,
                            password: _password,
                            onRegisterChanged: (value) => setState(() => _register = value),
                            onSubmit: _submit,
                          ),
                        )
                      else
                        Expanded(
                          flex: 4,
                          child: AppCard(
                            padding: const EdgeInsets.all(26),
                            child: _AuthForm(
                              formKey: _formKey,
                              register: _register,
                              loading: _loading,
                              error: _error,
                              email: _email,
                              name: _name,
                              password: _password,
                              onRegisterChanged: (value) => setState(() => _register = value),
                              onSubmit: _submit,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.register,
    required this.loading,
    required this.error,
    required this.email,
    required this.name,
    required this.password,
    required this.onRegisterChanged,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool register;
  final bool loading;
  final String? error;
  final TextEditingController email;
  final TextEditingController name;
  final TextEditingController password;
  final ValueChanged<bool> onRegisterChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Welcome to NutriAI', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Plan meals, track nutrition, and monitor progress.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF62716A))),
          const SizedBox(height: 22),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, icon: Icon(Icons.login), label: Text('Sign in')),
              ButtonSegment(value: true, icon: Icon(Icons.person_add_alt), label: Text('Register')),
            ],
            selected: {register},
            onSelectionChanged: (value) => onRegisterChanged(value.first),
          ),
          const SizedBox(height: 16),
          if (register)
            TextFormField(
              controller: name,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined), labelText: 'Full name'),
              validator: _required,
            ),
          if (register) const SizedBox(height: 12),
          TextFormField(
            controller: email,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline), labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: password,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline), labelText: 'Password'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.length < 8) {
                return 'Use at least 8 characters';
              }
              return null;
            },
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(message: error!),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: loading ? null : onSubmit,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.arrow_forward),
            label: Text(register ? 'Create account' : 'Sign in'),
          ),
        ],
      ),
    );
  }
}

class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(size: 58),
          const SizedBox(height: 24),
          Text(
            'NutriAI',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            'AI Nutrition & Meal Planner',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFFE8F4EC), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FeaturePill(icon: Icons.restaurant_menu, label: 'Smart meals'),
              FeaturePill(icon: Icons.water_drop_outlined, label: 'Water goals'),
              FeaturePill(icon: Icons.monitor_heart_outlined, label: 'Risk insights'),
              FeaturePill(icon: Icons.shopping_cart_outlined, label: 'Groceries'),
            ],
          ),
        ],
      ),
    );
  }
}

class FeaturePill extends StatelessWidget {
  const FeaturePill({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 42});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 22, offset: Offset(0, 10)),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(Icons.eco_rounded, color: _leaf, size: size * 0.58),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.apiClient,
    required this.onLogout,
  });

  final ApiClient apiClient;
  final VoidCallback onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(apiClient: widget.apiClient),
      ProfileScreen(apiClient: widget.apiClient),
      PlannerScreen(apiClient: widget.apiClient),
      FoodLogScreen(apiClient: widget.apiClient),
      AssistantScreen(apiClient: widget.apiClient),
      ProgressScreen(apiClient: widget.apiClient),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Scaffold(
          appBar: compact
              ? AppBar(
                  title: const Row(
                    children: [
                      Icon(Icons.eco_rounded),
                      SizedBox(width: 10),
                      Text('NutriAI'),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Sign out',
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout),
                    ),
                  ],
                )
              : null,
          body: Row(
            children: [
              if (!compact)
                Container(
                  width: constraints.maxWidth > 1080 ? 248 : 92,
                  decoration: const BoxDecoration(
                    color: _leafDark,
                    boxShadow: [BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(8, 0))],
                  ),
                  child: NavigationRail(
                    backgroundColor: Colors.transparent,
                    indicatorColor: const Color(0xFFBFE8CF),
                    selectedIconTheme: const IconThemeData(color: _leafDark),
                    unselectedIconTheme: const IconThemeData(color: Color(0xFFD8E9DF)),
                    selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    unselectedLabelTextStyle: const TextStyle(color: Color(0xFFD8E9DF), fontWeight: FontWeight.w600),
                    extended: constraints.maxWidth > 1080,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (value) => setState(() => _selectedIndex = value),
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: constraints.maxWidth > 1080
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                BrandMark(size: 38),
                                SizedBox(width: 12),
                                Text('NutriAI', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                              ],
                            )
                          : const BrandMark(size: 38),
                    ),
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: IconButton.filledTonal(
                            tooltip: 'Sign out',
                            onPressed: widget.onLogout,
                            icon: const Icon(Icons.logout),
                          ),
                        ),
                      ),
                    ),
                    destinations: const [
                      NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                      NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
                      NavigationRailDestination(icon: Icon(Icons.restaurant_menu), selectedIcon: Icon(Icons.restaurant), label: Text('Planner')),
                      NavigationRailDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: Text('Food log')),
                      NavigationRailDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: Text('Assistant')),
                      NavigationRailDestination(icon: Icon(Icons.show_chart), selectedIcon: Icon(Icons.show_chart), label: Text('Progress')),
                    ],
                  ),
                ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF7FBF4), Color(0xFFEFF5F0)],
                    ),
                  ),
                  padding: EdgeInsets.all(compact ? 12 : 24),
                  child: pages[_selectedIndex],
                ),
              ),
            ],
          ),
          bottomNavigationBar: compact
              ? NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) => setState(() => _selectedIndex = value),
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
                    NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
                    NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Planner'),
                    NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Log'),
                    NavigationDestination(icon: Icon(Icons.smart_toy_outlined), label: 'AI'),
                    NavigationDestination(icon: Icon(Icons.show_chart), label: 'Progress'),
                  ],
                )
              : null,
        );
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<_DashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final profile = await widget.apiClient.profile();
    final foods = await widget.apiClient.foods();
    final summary = await widget.apiClient.nutritionSummary(todayIsoDate());
    return _DashboardData(profile: profile, foods: foods, summary: summary);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorView(message: snapshot.error.toString(), onRetry: () => setState(() => _future = _load()));
        }
        final data = snapshot.data!;
        final summary = data.summary;
        return PageScaffold(
          title: 'Dashboard',
          children: [
            ResponsiveGrid(
              children: [
                StatTile(label: 'Calories today', value: '${summary['calories'] ?? 0} kcal', icon: Icons.local_fire_department),
                StatTile(label: 'Protein', value: '${summary['protein_g'] ?? 0} g', icon: Icons.fitness_center),
                StatTile(label: 'Foods', value: '${data.foods.length}', icon: Icons.inventory_2_outlined),
                StatTile(label: 'Profile age', value: '${data.profile['age'] ?? '-'}', icon: Icons.badge_outlined),
              ],
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionTitle(title: 'Food database'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: data.foods.take(12).map((food) => FoodChip(food: food)).toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class FoodChip extends StatelessWidget {
  const FoodChip({super.key, required this.food});

  final Map<String, dynamic> food;

  @override
  Widget build(BuildContext context) {
    final category = food['category']?.toString() ?? 'food';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _foodColor(category).withValues(alpha: 0.12),
        border: Border.all(color: _foodColor(category).withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_foodIcon(category), size: 17, color: _foodColor(category)),
            const SizedBox(width: 8),
            Text(food['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Color _foodColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('protein') || lower.contains('meal')) {
      return _coral;
    }
    if (lower.contains('fruit') || lower.contains('snack')) {
      return _amber;
    }
    if (lower.contains('carbohydrate') || lower.contains('breakfast')) {
      return _blue;
    }
    return _leaf;
  }

  IconData _foodIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('protein') || lower.contains('meal')) {
      return Icons.restaurant;
    }
    if (lower.contains('fruit') || lower.contains('snack')) {
      return Icons.local_dining;
    }
    if (lower.contains('carbohydrate') || lower.contains('breakfast')) {
      return Icons.rice_bowl_outlined;
    }
    return Icons.eco_outlined;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _age = TextEditingController(text: '25');
  final _height = TextEditingController(text: '175');
  final _weight = TextEditingController(text: '75');
  final _targetWeight = TextEditingController(text: '70');
  final _protein = TextEditingController(text: '140');
  final _carbs = TextEditingController(text: '240');
  final _fat = TextEditingController(text: '70');
  String _gender = 'male';
  String _activity = 'moderate';
  String _goal = 'maintain';
  String _preference = 'high-protein';
  String _exercise = '3 days per week';
  String _habits = 'balanced';
  bool _loading = false;
  String? _message;
  String? _error;
  Map<String, dynamic>? _calorieResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _targetWeight.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await widget.apiClient.profile();
      final goal = await widget.apiClient.goal();
      _age.text = '${profile['age'] ?? _age.text}';
      _height.text = '${profile['height_cm'] ?? _height.text}';
      _weight.text = '${profile['weight_kg'] ?? _weight.text}';
      _gender = profile['gender']?.toString() ?? _gender;
      _activity = profile['activity_level']?.toString() ?? _activity;
      _preference = profile['food_preference']?.toString() ?? _preference;
      _exercise = profile['exercise_frequency']?.toString() ?? _exercise;
      _habits = profile['eating_habits']?.toString() ?? _habits;
      if (goal != null) {
        _goal = goal['goal_type']?.toString() ?? _goal;
        _targetWeight.text = '${goal['target_weight_kg'] ?? _targetWeight.text}';
        _protein.text = '${goal['protein_target_g'] ?? _protein.text}';
        _carbs.text = '${goal['carbs_target_g'] ?? _carbs.text}';
        _fat.text = '${goal['fat_target_g'] ?? _fat.text}';
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await widget.apiClient.saveProfile(
        profile: {
          'age': int.tryParse(_age.text),
          'gender': _gender,
          'height_cm': double.tryParse(_height.text),
          'weight_kg': double.tryParse(_weight.text),
          'activity_level': _activity,
          'food_preference': _preference,
          'exercise_frequency': _exercise,
          'eating_habits': _habits,
        },
        goal: {
          'goal_type': _goal,
          'target_weight_kg': double.tryParse(_targetWeight.text),
          'protein_target_g': double.tryParse(_protein.text),
          'carbs_target_g': double.tryParse(_carbs.text),
          'fat_target_g': double.tryParse(_fat.text),
        },
      );
      _message = 'Profile saved';
    } catch (error) {
      _error = error.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _predictCalories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.apiClient.predictCalories({
        'age': int.tryParse(_age.text),
        'gender': _gender,
        'height_cm': double.tryParse(_height.text),
        'weight_kg': double.tryParse(_weight.text),
        'activity_level': _activity,
        'goal': _goal,
      });
      setState(() => _calorieResult = result);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Profile',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: 'Profile and goals'),
              const SizedBox(height: 16),
              ResponsiveGrid(
                minTileWidth: 220,
                children: [
                  NumberField(controller: _age, label: 'Age'),
                  SelectField(label: 'Gender', value: _gender, values: const ['male', 'female'], onChanged: (value) => setState(() => _gender = value)),
                  NumberField(controller: _height, label: 'Height cm'),
                  NumberField(controller: _weight, label: 'Weight kg'),
                  SelectField(label: 'Activity', value: _activity, values: const ['sedentary', 'light', 'moderate', 'active', 'very_active'], onChanged: (value) => setState(() => _activity = value)),
                  SelectField(label: 'Goal', value: _goal, values: const ['lose_weight', 'maintain', 'gain_muscle', 'gain_weight'], onChanged: (value) => setState(() => _goal = value)),
                  TextFormField(decoration: const InputDecoration(labelText: 'Food preference'), initialValue: _preference, onChanged: (value) => _preference = value),
                  TextFormField(decoration: const InputDecoration(labelText: 'Exercise frequency'), initialValue: _exercise, onChanged: (value) => _exercise = value),
                  TextFormField(decoration: const InputDecoration(labelText: 'Eating habits'), initialValue: _habits, onChanged: (value) => _habits = value),
                  NumberField(controller: _targetWeight, label: 'Target weight kg'),
                  NumberField(controller: _protein, label: 'Protein target g'),
                  NumberField(controller: _carbs, label: 'Carb target g'),
                  NumberField(controller: _fat, label: 'Fat target g'),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(onPressed: _loading ? null : _save, icon: const Icon(Icons.save_outlined), label: const Text('Save')),
                  OutlinedButton.icon(onPressed: _loading ? null : _predictCalories, icon: const Icon(Icons.bolt_outlined), label: const Text('Predict calories')),
                ],
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                SuccessBanner(message: _message!),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorBanner(message: _error!),
              ],
              if (_calorieResult != null) ...[
                const SizedBox(height: 16),
                StatTile(
                  label: 'Recommended daily calories',
                  value: '${_calorieResult!['recommended_daily_calories']} kcal',
                  icon: Icons.local_fire_department_outlined,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _calories = TextEditingController(text: '2200');
  final _protein = TextEditingController(text: '140');
  final _carbs = TextEditingController(text: '240');
  final _fat = TextEditingController(text: '70');
  final _allergies = TextEditingController();
  final _budget = TextEditingController(text: '35');
  String _goal = 'maintain';
  String _preference = 'high-protein';
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _recommendation;
  Map<String, dynamic>? _groceryList;

  @override
  void dispose() {
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _allergies.dispose();
    _budget.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _payload => {
        'daily_calorie_target': int.tryParse(_calories.text) ?? 2200,
        'health_goal': _goal,
        'food_preference': _preference,
        'allergies': _allergies.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
        'budget': double.tryParse(_budget.text),
        'protein_requirement_g': double.tryParse(_protein.text),
        'carbohydrate_requirement_g': double.tryParse(_carbs.text),
        'fat_requirement_g': double.tryParse(_fat.text),
      };

  Future<void> _recommend({required bool save}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = save ? await widget.apiClient.generateMealPlan(_payload) : await widget.apiClient.recommendMeals(_payload);
      setState(() => _recommendation = save ? Map<String, dynamic>.from(result['plan_json'] as Map) : result);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _generateGroceries() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.apiClient.generateGroceryList(budget: double.tryParse(_budget.text));
      setState(() => _groceryList = result);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Meal planner',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: 'Recommendation inputs'),
              const SizedBox(height: 16),
              ResponsiveGrid(
                minTileWidth: 220,
                children: [
                  NumberField(controller: _calories, label: 'Daily calories'),
                  SelectField(label: 'Goal', value: _goal, values: const ['lose_weight', 'maintain', 'gain_muscle', 'gain_weight'], onChanged: (value) => setState(() => _goal = value)),
                  TextFormField(decoration: const InputDecoration(labelText: 'Food preference'), initialValue: _preference, onChanged: (value) => _preference = value),
                  NumberField(controller: _protein, label: 'Protein g'),
                  NumberField(controller: _carbs, label: 'Carbs g'),
                  NumberField(controller: _fat, label: 'Fat g'),
                  TextFormField(controller: _allergies, decoration: const InputDecoration(labelText: 'Allergies to avoid')),
                  NumberField(controller: _budget, label: 'Weekly budget'),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(onPressed: _loading ? null : () => _recommend(save: false), icon: const Icon(Icons.auto_awesome), label: const Text('Recommend')),
                  OutlinedButton.icon(onPressed: _loading ? null : () => _recommend(save: true), icon: const Icon(Icons.today_outlined), label: const Text('Save plan')),
                  OutlinedButton.icon(onPressed: _loading ? null : _generateGroceries, icon: const Icon(Icons.shopping_cart_outlined), label: const Text('Grocery list')),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorBanner(message: _error!),
              ],
            ],
          ),
        ),
        if (_recommendation != null) MealRecommendationView(data: _recommendation!),
        if (_groceryList != null) GroceryListView(data: _groceryList!),
      ],
    );
  }
}

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  final _quantity = TextEditingController(text: '1');
  final _notes = TextEditingController();
  List<Map<String, dynamic>> _foods = [];
  List<Map<String, dynamic>> _logs = [];
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _imageResult;
  int? _selectedFoodId;
  String _mealType = 'lunch';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final foods = await widget.apiClient.foods();
      final logs = await widget.apiClient.foodLogs();
      final summary = await widget.apiClient.nutritionSummary(todayIsoDate());
      setState(() {
        _foods = foods;
        _logs = logs;
        _summary = summary;
        _selectedFoodId ??= foods.isEmpty ? null : foods.first['id'] as int;
        _error = null;
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logFood() async {
    if (_selectedFoodId == null) {
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.apiClient.logFood(
        foodId: _selectedFoodId!,
        mealType: _mealType,
        quantity: double.tryParse(_quantity.text) ?? 1,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      _notes.clear();
      await _load();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.single.bytes == null) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final file = result.files.single;
      final recognition = await widget.apiClient.recognizeFoodImage(bytes: file.bytes!, filename: file.name);
      setState(() => _imageResult = recognition);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Food log',
      children: [
        if (_summary != null)
          ResponsiveGrid(
            children: [
              StatTile(label: 'Calories', value: '${_summary!['calories']} kcal', icon: Icons.local_fire_department_outlined),
              StatTile(label: 'Protein', value: '${_summary!['protein_g']} g', icon: Icons.fitness_center),
              StatTile(label: 'Carbs', value: '${_summary!['carbs_g']} g', icon: Icons.grain_outlined),
              StatTile(label: 'Fat', value: '${_summary!['fat_g']} g', icon: Icons.opacity),
            ],
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: 'Add food'),
              const SizedBox(height: 16),
              ResponsiveGrid(
                minTileWidth: 220,
                children: [
                  DropdownButtonFormField<int>(
                    key: ValueKey(_selectedFoodId),
                    initialValue: _selectedFoodId,
                    decoration: const InputDecoration(labelText: 'Food'),
                    items: _foods.map((food) => DropdownMenuItem<int>(value: food['id'] as int, child: Text(food['name'].toString()))).toList(),
                    onChanged: (value) => setState(() => _selectedFoodId = value),
                  ),
                  SelectField(label: 'Meal', value: _mealType, values: const ['breakfast', 'lunch', 'dinner', 'snack'], onChanged: (value) => setState(() => _mealType = value)),
                  NumberField(controller: _quantity, label: 'Quantity'),
                  TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes')),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(onPressed: _loading ? null : _logFood, icon: const Icon(Icons.add_task), label: const Text('Log food')),
                  OutlinedButton.icon(onPressed: _loading ? null : _pickImage, icon: const Icon(Icons.image_search_outlined), label: const Text('Recognize image')),
                ],
              ),
              if (_imageResult != null) ...[
                const SizedBox(height: 16),
                StatTile(
                  label: _imageResult!['food_name'].toString(),
                  value: '${_imageResult!['estimated_calories']} kcal',
                  icon: Icons.image_outlined,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorBanner(message: _error!),
              ],
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: 'Recent logs'),
              const SizedBox(height: 12),
              if (_logs.isEmpty)
                const Text('No food logs')
              else
                ..._logs.take(8).map((log) {
                  final food = Map<String, dynamic>.from(log['food'] as Map);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.restaurant),
                    title: Text(food['name'].toString()),
                    subtitle: Text('${log['meal_type']} • quantity ${log['quantity']}'),
                    trailing: Text('${food['calories']} kcal'),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _question = TextEditingController(text: 'Can I eat pizza while dieting?');
  final _weight = TextEditingController(text: '80');
  final _height = TextEditingController(text: '170');
  String _habits = 'balanced';
  String _exercise = '3 days per week';
  String _goal = 'lose_weight';
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _chat;
  Map<String, dynamic>? _risk;

  @override
  void dispose() {
    _question.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.apiClient.askNutritionQuestion(_question.text.trim());
      setState(() => _chat = result);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _predictRisk() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.apiClient.predictHealthRisk({
        'eating_habits': _habits,
        'exercise_frequency': _exercise,
        'weight_kg': double.tryParse(_weight.text),
        'height_cm': double.tryParse(_height.text),
        'goal': _goal,
      });
      setState(() => _risk = result);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'AI assistant',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: 'Nutrition chatbot'),
              const SizedBox(height: 16),
              TextFormField(controller: _question, decoration: const InputDecoration(labelText: 'Question'), minLines: 2, maxLines: 4),
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: _loading ? null : _ask, icon: const Icon(Icons.send_outlined), label: const Text('Ask')),
              if (_chat != null) ...[
                const SizedBox(height: 16),
                Text(_chat!['answer'].toString(), style: Theme.of(context).textTheme.bodyLarge),
              ],
            ],
          ),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: 'Health risk'),
              const SizedBox(height: 16),
              ResponsiveGrid(
                minTileWidth: 220,
                children: [
                  NumberField(controller: _weight, label: 'Weight kg'),
                  NumberField(controller: _height, label: 'Height cm'),
                  TextFormField(decoration: const InputDecoration(labelText: 'Eating habits'), initialValue: _habits, onChanged: (value) => _habits = value),
                  TextFormField(decoration: const InputDecoration(labelText: 'Exercise frequency'), initialValue: _exercise, onChanged: (value) => _exercise = value),
                  SelectField(label: 'Goal', value: _goal, values: const ['lose_weight', 'maintain', 'gain_muscle', 'gain_weight'], onChanged: (value) => setState(() => _goal = value)),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _loading ? null : _predictRisk, icon: const Icon(Icons.health_and_safety_outlined), label: const Text('Predict risk')),
              if (_risk != null) ...[
                const SizedBox(height: 16),
                StatTile(label: _risk!['risk_level'].toString(), value: 'BMI ${_risk!['bmi']}', icon: Icons.monitor_heart_outlined),
                const SizedBox(height: 12),
                ...(_risk!['recommendations'] as List<dynamic>).map((item) => ListTile(leading: const Icon(Icons.check_circle_outline), title: Text(item.toString()))),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorBanner(message: _error!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _weight = TextEditingController(text: '75');
  final _water = TextEditingController(text: '2000');
  Map<String, dynamic>? _progress;
  Map<String, dynamic>? _waterLog;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _weight.dispose();
    _water.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final progress = await widget.apiClient.weightProgress();
      final water = await widget.apiClient.waterLog(todayIsoDate());
      setState(() {
        _progress = progress;
        _waterLog = water;
        _error = null;
      });
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _recordWeight() async {
    await widget.apiClient.recordWeight(double.tryParse(_weight.text) ?? 75);
    await _load();
  }

  Future<void> _recordWater() async {
    await widget.apiClient.logWater(double.tryParse(_water.text) ?? 0);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Progress',
      children: [
        if (_progress != null)
          ResponsiveGrid(
            children: [
              StatTile(label: 'Current weight', value: '${_progress!['current_weight'] ?? '-'} kg', icon: Icons.monitor_weight_outlined),
              StatTile(label: 'Target weight', value: '${_progress!['target_weight'] ?? '-'} kg', icon: Icons.flag_outlined),
              StatTile(label: 'Progress', value: '${_progress!['progress_percentage']}%', icon: Icons.trending_up),
              StatTile(label: 'Water today', value: '${_waterLog?['amount_ml'] ?? 0} ml', icon: Icons.water_drop_outlined),
            ],
          ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: 'Track health progress'),
              const SizedBox(height: 16),
              ResponsiveGrid(
                minTileWidth: 220,
                children: [
                  NumberField(controller: _weight, label: 'Weekly weight kg'),
                  NumberField(controller: _water, label: 'Water intake ml'),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(onPressed: _loading ? null : _recordWeight, icon: const Icon(Icons.monitor_weight_outlined), label: const Text('Save weight')),
                  OutlinedButton.icon(onPressed: _loading ? null : _recordWater, icon: const Icon(Icons.water_drop_outlined), label: const Text('Save water')),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorBanner(message: _error!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class MealRecommendationView extends StatelessWidget {
  const MealRecommendationView({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final meals = data['meals'] as List<dynamic>;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: 'Recommended plan'),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 14.0;
              final columns = (constraints.maxWidth / 280).floor().clamp(1, 4);
              final tileWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: meals.map((meal) {
                  return SizedBox(
                    width: tileWidth,
                    child: MealPlanTile(data: Map<String, dynamic>.from(meal as Map)),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MealPlanTile extends StatelessWidget {
  const MealPlanTile({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final items = data['items'] as List<dynamic>? ?? [];
    final mealType = _mealTitle(data['meal_type'].toString());
    final calories = data['calories'];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFB),
        border: Border.all(color: const Color(0xFFDDE5E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    mealType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '$calories kcal',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text('No foods selected', style: Theme.of(context).textTheme.bodyMedium)
            else
              ...items.map((item) {
                final food = Map<String, dynamic>.from(item as Map);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 7),
                        child: SizedBox(
                          width: 5,
                          height: 5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFF6B7A73),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '${food['name']} • ${food['serving_size']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _mealTitle(String value) {
    if (value.isEmpty) {
      return 'Meal';
    }
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}

class GroceryListView extends StatelessWidget {
  const GroceryListView({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final items = data['items'] as List<dynamic>? ?? [];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: data['name'].toString()),
          const SizedBox(height: 8),
          Text('Estimated total: ${data['estimated_total_cost']}'),
          const SizedBox(height: 12),
          ...items.map((item) {
            final grocery = Map<String, dynamic>.from(item as Map);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: grocery['purchased'] == true,
              onChanged: null,
              title: Text(grocery['food_item'].toString()),
              subtitle: Text('${grocery['quantity']} • ${grocery['estimated_cost']}'),
            );
          }),
        ],
      ),
    );
  }
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        PageHeader(title: title),
        const SizedBox(height: 16),
        ...children.expand((child) => [child, const SizedBox(height: 16)]),
      ],
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_leafDark, _leaf, Color(0xFF7FCB8D)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x1F0C3B2E), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.eco_rounded, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(_pageSubtitle(title), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFE7F5EA))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pageSubtitle(String title) {
    return switch (title) {
      'Dashboard' => 'Today at a glance',
      'Profile' => 'Personalize your nutrition targets',
      'Meal planner' => 'Generate meals and shopping ideas',
      'Food log' => 'Record what you eat and track macros',
      'AI assistant' => 'Ask questions and check basic risks',
      'Progress' => 'Monitor weight and hydration',
      _ => 'NutriAI workspace',
    };
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 180,
  });

  final List<Widget> children;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.8,
          children: children,
        );
      },
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFDDE8E1)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x120C3B2E), blurRadius: 16, offset: Offset(0, 8))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _metricColor(label).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: _metricColor(label), size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF62716A))),
                  const SizedBox(height: 4),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _metricColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('calorie') || lower.contains('risk')) {
      return _coral;
    }
    if (lower.contains('water') || lower.contains('carb')) {
      return _blue;
    }
    if (lower.contains('protein') || lower.contains('weight')) {
      return _leaf;
    }
    return _amber;
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 22, decoration: BoxDecoration(color: _leaf, borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
      ],
    );
  }
}

class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: values.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class NumberField extends StatelessWidget {
  const NumberField({super.key, required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return BannerBox(message: message, color: const Color(0xFFFFE9E5), icon: Icons.error_outline);
  }
}

class SuccessBanner extends StatelessWidget {
  const SuccessBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return BannerBox(message: message, color: const Color(0xFFE7F5EA), icon: Icons.check_circle_outline);
  }
}

class BannerBox extends StatelessWidget {
  const BannerBox({
    super.key,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorBanner(message: message),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _DashboardData {
  _DashboardData({
    required this.profile,
    required this.foods,
    required this.summary,
  });

  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> foods;
  final Map<String, dynamic> summary;
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return null;
}

String todayIsoDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
