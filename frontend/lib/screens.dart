import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'api_client.dart';

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('AI Meal Planning', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 24),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Sign in')),
                        ButtonSegment(value: true, label: Text('Register')),
                      ],
                      selected: {_register},
                      onSelectionChanged: (value) => setState(() => _register = value.first),
                    ),
                    const SizedBox(height: 16),
                    if (_register)
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Full name'),
                        validator: _required,
                      ),
                    if (_register) const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: _required,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      ErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_register ? 'Create account' : 'Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return Scaffold(
          appBar: compact
              ? AppBar(
                  title: const Text('AI Meal Planning'),
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
                NavigationRail(
                  extended: constraints.maxWidth > 980,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) => setState(() => _selectedIndex = value),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      'AI Meal Planning',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: IconButton(
                          tooltip: 'Sign out',
                          onPressed: widget.onLogout,
                          icon: const Icon(Icons.logout),
                        ),
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), label: Text('Dashboard')),
                    NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Profile')),
                    NavigationRailDestination(icon: Icon(Icons.restaurant_menu), label: Text('Planner')),
                    NavigationRailDestination(icon: Icon(Icons.fact_check_outlined), label: Text('Food log')),
                    NavigationRailDestination(icon: Icon(Icons.smart_toy_outlined), label: Text('Assistant')),
                  ],
                ),
              Expanded(
                child: Padding(
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
                    spacing: 8,
                    runSpacing: 8,
                    children: data.foods.take(12).map((food) => Chip(label: Text(food['name'].toString()))).toList(),
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
  String _goal = 'maintain';
  String _preference = 'high-protein';
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _recommendation;

  @override
  void dispose() {
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _payload => {
        'daily_calorie_target': int.tryParse(_calories.text) ?? 2200,
        'health_goal': _goal,
        'food_preference': _preference,
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
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(onPressed: _loading ? null : () => _recommend(save: false), icon: const Icon(Icons.auto_awesome), label: const Text('Recommend')),
                  OutlinedButton.icon(onPressed: _loading ? null : () => _recommend(save: true), icon: const Icon(Icons.today_outlined), label: const Text('Save plan')),
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
          ResponsiveGrid(
            minTileWidth: 260,
            children: meals.map((meal) {
              final mealMap = Map<String, dynamic>.from(meal as Map);
              final items = mealMap['items'] as List<dynamic>;
              return DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE1E6E3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(mealMap['meal_type'].toString().toUpperCase(), style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      Text('${mealMap['calories']} kcal', style: Theme.of(context).textTheme.titleMedium),
                      const Divider(height: 20),
                      ...items.map((item) {
                        final food = Map<String, dynamic>.from(item as Map);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('${food['name']} • ${food['serving_size']}'),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
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
        Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        ...children.expand((child) => [child, const SizedBox(height: 16)]),
      ],
    );
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
          childAspectRatio: 3.2,
          children: children,
        );
      },
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
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
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 4),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700));
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
