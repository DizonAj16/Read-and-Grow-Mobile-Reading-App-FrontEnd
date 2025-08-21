import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? "http://10.0.2.2:8000/api";
  }

  static Map<String, String> _jsonHeaders() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Future<http.Response> login(Map<String, dynamic> body) async {
    final url = Uri.parse('${await _getBaseUrl()}/auth/login');
    final loginBody = {'login': body['login'], 'password': body['password']};
    final response = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(loginBody),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded['data'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['user']['role']);
      await prefs.setString('user_id', data['user']['id'].toString());
    }

    return response;
  }

  static Future<http.Response> logout(String token) async {
    final url = Uri.parse('${await _getBaseUrl()}/auth/logout');
    return await http.post(url, headers: _authHeaders(token));
  }

  static Future<Map<String, dynamic>> adminLogin(
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await _getBaseUrl()}/auth/admin/login');
    final response = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );

    debugPrint('Admin login status: ${response.statusCode}');
    debugPrint('Admin login body: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      // Extract token and user info
      final token = data['data']?['token'];
      final user = data['data']?['user'];

      return {
        'success': true,
        'message': data['message'],
        'token': token,
        'user': user,
      };
    } else if (response.statusCode == 401 && data['step'] == 2) {
      return {'success': false, 'step': 2, 'message': data['message']};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    }
  }

  static Future<Map<String, dynamic>> getAuthProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No authentication token found');

    final url = Uri.parse('${await _getBaseUrl()}/profile/me');
    final response = await http.get(url, headers: _authHeaders(token));

    // ✅ Put the debugPrints right after getting the response
    debugPrint('Profile status: ${response.statusCode}');
    debugPrint('Profile body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode}');
    }
  }
}
