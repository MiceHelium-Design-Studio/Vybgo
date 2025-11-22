import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final url = '$baseUrl$endpoint';
    try {
      print('[API] → POST $url');
      print('[API] Body: ${jsonEncode(body)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('[API] ← ${response.statusCode} ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Request failed');
      }
    } catch (e, stackTrace) {
      print('[API] ✗ Error: $e');
      print('[API] Stack trace: $stackTrace');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final url = '$baseUrl$endpoint';
    try {
      print('[API] → GET $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('[API] ← ${response.statusCode} ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Request failed');
      }
    } catch (e, stackTrace) {
      print('[API] ✗ Error: $e');
      print('[API] Stack trace: $stackTrace');
      throw Exception('Network error: $e');
    }
  }

  Future<List<dynamic>> getList(String endpoint) async {
    final url = '$baseUrl$endpoint';
    try {
      print('[API] → GET $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      print('[API] ← ${response.statusCode} ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data is List) {
          return data;
        }
        return [data];
      } else {
        throw Exception(data['error'] ?? 'Request failed');
      }
    } catch (e, stackTrace) {
      print('[API] ✗ Error: $e');
      print('[API] Stack trace: $stackTrace');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    final url = '$baseUrl$endpoint';
    try {
      print('[API] → PATCH $url');
      print('[API] Body: ${jsonEncode(body)}');
      
      final response = await http.patch(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('[API] ← ${response.statusCode} ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Request failed');
      }
    } catch (e, stackTrace) {
      print('[API] ✗ Error: $e');
      print('[API] Stack trace: $stackTrace');
      throw Exception('Network error: $e');
    }
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

