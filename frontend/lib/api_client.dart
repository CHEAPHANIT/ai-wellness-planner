import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    String baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000',
    ),
  }) : baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), '');

  final String baseUrl;
  String? _token;

  void clearToken() {
    _token = null;
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Map<String, String> get _authHeaders => {
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<void> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    await _postJson('/api/auth/register', {
      'email': email,
      'full_name': fullName,
      'password': password,
    });
    await login(email: email, password: password);
  }

  Future<void> login({required String email, required String password}) async {
    final response = await http.post(
      _uri('/api/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    final data = _decode(response) as Map<String, dynamic>;
    _token = data['access_token'] as String;
  }

  Future<Map<String, dynamic>> me() async {
    return _getMap('/api/auth/me');
  }

  Future<Map<String, dynamic>> profile() async {
    return _getMap('/api/profile');
  }

  Future<Map<String, dynamic>?> goal() async {
    final data = await _get('/api/profile/goal');
    if (data == null) {
      return null;
    }
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> saveProfile({
    required Map<String, dynamic> profile,
    required Map<String, dynamic> goal,
  }) async {
    return _putJson('/api/profile', {'profile': profile, 'goal': goal});
  }

  Future<List<Map<String, dynamic>>> foods({String? search}) async {
    final query = search == null || search.trim().isEmpty
        ? ''
        : '?search=${Uri.encodeQueryComponent(search.trim())}';
    final data = await _get('/api/foods$query') as List<dynamic>;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> logFood({
    required int foodId,
    required String mealType,
    required double quantity,
    String? notes,
  }) async {
    return _postJson('/api/logs/food', {
      'food_id': foodId,
      'meal_type': mealType,
      'quantity': quantity,
      'notes': notes,
    });
  }

  Future<List<Map<String, dynamic>>> foodLogs() async {
    final data = await _get('/api/logs/food') as List<dynamic>;
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> nutritionSummary(String date) async {
    return _getMap('/api/logs/nutrition/$date');
  }

  Future<Map<String, dynamic>> predictCalories(Map<String, dynamic> payload) {
    return _postJson('/api/ai/calories', payload);
  }

  Future<Map<String, dynamic>> recommendMeals(Map<String, dynamic> payload) {
    return _postJson('/api/ai/meals', payload);
  }

  Future<Map<String, dynamic>> generateMealPlan(Map<String, dynamic> payload) {
    return _postJson('/api/meal-plans/generate', {
      'recommendation_request': payload,
    });
  }

  Future<Map<String, dynamic>> recognizeFoodImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/ai/image-recognition'));
    request.headers.addAll(_authHeaders);
    request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  Future<Map<String, dynamic>> askNutritionQuestion(String question) {
    return _postJson('/api/ai/chat', {'question': question});
  }

  Future<Map<String, dynamic>> predictHealthRisk(Map<String, dynamic> payload) {
    return _postJson('/api/ai/health-risk', payload);
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final data = await _get(path);
    return Map<String, dynamic>.from(data as Map);
  }

  Future<dynamic> _get(String path) async {
    final response = await http.get(_uri(path), headers: _jsonHeaders);
    return _decode(response);
  }

  Future<Map<String, dynamic>> _postJson(String path, Map<String, dynamic> body) async {
    final response = await http.post(_uri(path), headers: _jsonHeaders, body: jsonEncode(body));
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  Future<Map<String, dynamic>> _putJson(String path, Map<String, dynamic> body) async {
    final response = await http.put(_uri(path), headers: _jsonHeaders, body: jsonEncode(body));
    return Map<String, dynamic>.from(_decode(response) as Map);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_extractError(response));
    }
    if (response.body.isEmpty) {
      return null;
    }
    return jsonDecode(response.body);
  }

  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {
      return 'Request failed with status ${response.statusCode}';
    }
    return 'Request failed with status ${response.statusCode}';
  }
}

