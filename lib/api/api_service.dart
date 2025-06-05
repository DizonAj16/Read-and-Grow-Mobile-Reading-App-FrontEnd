import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = "http://10.0.2.2:8000/api"; // Use local IP on real device

class ApiService {
  static Future<http.Response> registerStudent(Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/student/register');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> registerTeacher(Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/teacher/register');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> login(Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/login');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> logout(String token) async {
    final url = Uri.parse('$baseUrl/logout');
    return await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
  }
}
