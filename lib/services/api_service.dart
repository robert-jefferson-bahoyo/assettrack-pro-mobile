import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String defaultBaseUrl = 'http://222.222.222.49:8000/api/mobile';

  static String baseUrl = defaultBaseUrl;

  static const String _baseUrlKey = 'api_base_url';
  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';

  static Future<Map<String, dynamic>> updateSerialNumber({
    required int assetId,
    required String serialNo,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final cleanSerialNo = serialNo.trim();

    if (cleanSerialNo.isEmpty) {
      throw Exception('Serial number is required.');
    }

    final uri = await _uri('/assets/$assetId/serial-number');

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'serial_no': cleanSerialNo}),
    );

    final Map<String, dynamic> data = _decodeBody(response);

    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    }

    throw Exception(data['message'] ?? 'Failed to update serial number.');
  }

  static String normalizeBaseUrl(String url) {
    var normalized = url.trim();

    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  static bool isValidBaseUrl(String url) {
    final normalized = normalizeBaseUrl(url);

    if (normalized.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(normalized);

    if (uri == null) {
      return false;
    }

    final scheme = uri.scheme.toLowerCase();

    if (scheme != 'http' && scheme != 'https') {
      return false;
    }

    if (uri.host.trim().isEmpty) {
      return false;
    }

    if (!normalized.contains('/api/mobile')) {
      return false;
    }

    return true;
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);

    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      baseUrl = normalizeBaseUrl(savedUrl);
      return baseUrl;
    }

    baseUrl = defaultBaseUrl;
    return baseUrl;
  }

  static Future<void> saveBaseUrl(String url) async {
    final normalized = normalizeBaseUrl(url);

    if (!isValidBaseUrl(normalized)) {
      throw Exception(
        'Invalid server URL. Example: http://192.168.1.10:8000/api/mobile',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, normalized);

    baseUrl = normalized;
  }

  static Future<void> resetBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);

    baseUrl = defaultBaseUrl;
  }

  static Future<Uri> _uri(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final currentBaseUrl = await getBaseUrl();
    final cleanPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse(
      '$currentBaseUrl$cleanPath',
    ).replace(queryParameters: queryParameters);
  }

  static Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception('Invalid server response.');
    } catch (_) {
      throw Exception(
        'Invalid server response. Please check if the Laravel API is running correctly.',
      );
    }
  }

  static Future<List<dynamic>> getAssetsByStatus(String status) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final uri = await _uri(
      '/assets/by-status',
      queryParameters: {'status': status},
    );

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = _decodeBody(response);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['assets'] as List<dynamic>;
    }

    throw Exception(data['message'] ?? 'Failed to load assets.');
  }

  static Future<List<dynamic>> getRecentActivity() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final uri = await _uri('/dashboard/recent-activity');

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = _decodeBody(response);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['recent_movements'] as List<dynamic>;
    }

    throw Exception(data['message'] ?? 'Failed to load recent activity.');
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('You are not logged in.');
    }

    final uri = await _uri('/dashboard/summary');

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = _decodeBody(response);

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

    final uri = await _uri('/assets/search-options');

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = _decodeBody(response);

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

    final uri = await _uri('/assets/search', queryParameters: query);

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = _decodeBody(response);

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

    final uri = await _uri('/assets/$assetId/return');

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'remarks': remarks}),
    );

    final Map<String, dynamic> data = _decodeBody(response);

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
    final uri = await _uri('/assets/scan/$encodedCode');

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    final Map<String, dynamic> data = _decodeBody(response);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['asset'] as Map<String, dynamic>;
    }

    throw Exception(data['message'] ?? 'Asset not found.');
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = await _uri('/login');

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    final Map<String, dynamic> data = _decodeBody(response);

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
        final uri = await _uri('/logout');

        await http.post(
          uri,
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

  static String friendlyError(Object e) {
    final message = e.toString().replaceFirst('Exception: ', '');

    if (message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Failed host lookup') ||
        message.contains('Network is unreachable') ||
        message.contains('Connection timed out')) {
      return 'Cannot connect to the server. Please check Wi-Fi, server IP, and Laravel server.';
    }

    if (message.contains('Connection closed before full header was received')) {
      return 'Server connection was interrupted. Please try again.';
    }

    if (message.contains('FormatException')) {
      return 'Invalid server response. Please check if the Laravel API is running correctly.';
    }

    return message;
  }
}
