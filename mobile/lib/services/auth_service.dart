import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  String? _token;
  Map<String, dynamic>? _user;

  AuthService(this._apiService);

  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  void setToken(String token) {
    _token = token;
    _apiService.setToken(token);
  }

  Future<void> login(String email, String password) async {
    final response = await _apiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    _token = response['token'] as String;
    _user = response['user'] as Map<String, dynamic>;
    _apiService.setToken(_token!);

    // Store token
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
  }

  Future<void> register(String email, String password, {String? name}) async {
    final response = await _apiService.post('/auth/register', {
      'email': email,
      'password': password,
      if (name != null) 'name': name,
    });

    _token = response['token'] as String;
    _user = response['user'] as Map<String, dynamic>;
    _apiService.setToken(_token!);

    // Store token
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _apiService.clearToken();

    // Clear stored token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthService(apiService);
});

