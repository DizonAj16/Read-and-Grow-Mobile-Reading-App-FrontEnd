import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TaskService {
  static Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? "http://10.0.2.2:8000/api";
  }

  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  static Future<List<String>> fetchTasksForStudent(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/students/tasks');
    final response = await http.get(url, headers: _authHeaders(token));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['tasks']);
    } else {
      throw Exception('Failed to load tasks');
    }
  }
}