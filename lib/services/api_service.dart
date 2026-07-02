import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://222.222.222.49:8000/api/mobile';

  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/dashboard/summary'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }

    throw Exception(data['message'] ?? 'Failed to load dashboard summary.');
  }

  static Future<Map<String, dynamic>> getAssetSearchOptions() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/assets/search-options'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }

    throw Exception(data['message'] ?? 'Failed to load search options.');
  }

  static Future<List<dynamic>> searchAssets({
    required String type,
    String keyword = '',
    int? officeId,
    int? departmentId,
    int? employeeId,
    String status = '',
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final Map<String, String> query = {'type': type};

    if (keyword.trim().isNotEmpty) {
      query['keyword'] = keyword.trim();
    }

    if (officeId != null) {
      query['office_id'] = officeId.toString();
    }

    if (departmentId != null) {
      query['department_id'] = departmentId.toString();
    }

    if (employeeId != null) {
      query['employee_id'] = employeeId.toString();
    }

    if (status.trim().isNotEmpty) {
      query['status'] = status.trim();
    }

    final uri = Uri.parse(
      '$baseUrl/assets/search',
    ).replace(queryParameters: query);

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['assets'] as List<dynamic>;
    }

    throw Exception(data['message'] ?? 'Search failed.');
  }

  static Future<Map<String, dynamic>> returnAsset({
    required int assetId,
    String remarks = '',
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final Uri url = Uri.parse('$baseUrl/assets/$assetId/return');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'remarks': remarks}),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }

    throw Exception(data['message'] ?? 'Failed to return asset.');
  }

  static Future<Map<String, dynamic>> scanAsset(String code) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final encodedCode = Uri.encodeComponent(code);
    final Uri url = Uri.parse('$baseUrl/assets/scan/$encodedCode');

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['asset'] as Map<String, dynamic>;
    }

    throw Exception(data['message'] ?? 'Asset not found.');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final Uri url = Uri.parse('$baseUrl/login');

    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    final Map<String, dynamic> data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_tokenKey, data['token'] ?? '');
      await prefs.setString(_userNameKey, data['user']?['name'] ?? '');
      await prefs.setString(_userEmailKey, data['user']?['email'] ?? '');

      return data;
    }

    throw Exception(data['message'] ?? 'Login failed.');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token != null && token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {
        // Ignore logout API error and clear local session anyway.
      }
    }

    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }
}
