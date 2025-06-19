import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student.dart';
import '../models/teacher.dart';

class ApiService {
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? "http://10.0.2.2:8000/api";
  }

  /// Helper to build standard JSON headers.
  static Map<String, String> _jsonHeaders() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Helper to build authorization headers.
  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// Helper to set a string in SharedPreferences if value is not null.
  static Future<void> _setStringIfNotNull(
    SharedPreferences prefs,
    String key,
    String? value,
  ) async {
    if (value != null) {
      await prefs.setString(key, value);
    }
  }

  /// Helper to store teacher details in SharedPreferences using Teacher model.
  static Future<void> _storeTeacherDetails(Map<String, dynamic> details) async {
    final prefs = await SharedPreferences.getInstance();
    final teacher = Teacher.fromMap(details);
    await _setStringIfNotNull(prefs, 'teacher_name', teacher.name);
    await _setStringIfNotNull(prefs, 'teacher_position', teacher.position);
    await _setStringIfNotNull(prefs, 'teacher_email', teacher.email);
    await _setStringIfNotNull(prefs, 'username', teacher.username);
    // Store user_id if present
    if (details['user_id'] != null) {
      await prefs.setString('user_id', details['user_id'].toString());
    }
  }

  /// Helper to store student details in SharedPreferences using Student model.
  static Future<void> _storeStudentDetails(Map<String, dynamic> details) async {
    final student = Student.fromJson(details);
    await student.saveToPrefs();
    // Store user_id if present
    final prefs = await SharedPreferences.getInstance();
    if (details['user_id'] != null) {
      await prefs.setString('user_id', details['user_id'].toString());
    }
  }

  /// Registers a new student using the provided [body] data.
  /// Sends a POST request to the student registration endpoint.
  /// Returns the HTTP response.
  static Future<http.Response> registerStudent(
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await getBaseUrl()}/student/register');
    return await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
  }

  /// Registers a new teacher using the provided [body] data.
  /// Sends a POST request to the teacher registration endpoint.
  /// Returns the HTTP response.
  static Future<http.Response> registerTeacher(
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await getBaseUrl()}/teacher/register');
    return await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
  }

  /// Logs in a user (student or teacher) with the given [body] credentials.
  /// Sends a POST request to the login endpoint.
  /// Stores relevant user details in SharedPreferences if login is successful.
  /// Returns the HTTP response.
  static Future<http.Response> login(Map<String, dynamic> body) async {
    final url = Uri.parse('${await getBaseUrl()}/login');
    final loginBody = {'login': body['login'], 'password': body['password']};
    final response = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(loginBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['role'] == 'teacher' && data['details'] != null) {
        await _storeTeacherDetails(data['details']);
      }
      if (data['role'] == 'student' && data['details'] != null) {
        await _storeStudentDetails(data['details']);
      }
    }

    return response;
  }

  /// Logs out the user by sending a POST request to the logout endpoint.
  /// Requires the user's [token] for authorization.
  /// Returns the HTTP response.
  static Future<http.Response> logout(String token) async {
    final url = Uri.parse('${await getBaseUrl()}/logout');
    return await http.post(url, headers: _authHeaders(token));
  }

  /// Logs in an admin user with the given [body] credentials.
  /// Handles multi-step authentication if required.
  /// Returns a map containing the result of the login attempt.
  static Future<Map<String, dynamic>> adminLogin(
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await getBaseUrl()}/admin/login');
    final response = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      // Success (step 2 or final)
      return {'success': true, ...data};
    } else if (response.statusCode == 401 && data['step'] == 2) {
      // Step 2 required
      return {'success': false, 'step': 2, 'message': data['message']};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    }
  }

  /// Fetch all students for the teacher (requires auth token).
  static Future<List<Student>> fetchAllStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');
    final response = await http.get(
      Uri.parse('${await getBaseUrl()}/teacher/students'),
      headers: _authHeaders(token),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final students =
          (data['students'] as List)
              .map((json) => Student.fromJson(Map<String, dynamic>.from(json)))
              .toList();
      return students;
    } else {
      throw Exception('Failed to load students');
    }
  }

  /// Store students data in SharedPreferences as JSON using Student model.
  static Future<void> storeStudentsToPrefs(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    final filtered = students.map((s) => s.toJson()).toList();
    await prefs.setString('students_data', jsonEncode(filtered));
  }

  /// Retrieve students data from SharedPreferences as Student model.
  static Future<List<Student>> getStudentsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('students_data');
    if (jsonString == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded
        .map((e) => Student.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Fetch all teachers for the admin (requires auth token).
  static Future<List<Teacher>> fetchAllTeachers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');
    final response = await http.get(
      Uri.parse('${await getBaseUrl()}/teachers'),
      headers: _authHeaders(token),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final teachers =
          (data['teachers'] as List)
              .map((json) => Teacher.fromJson(Map<String, dynamic>.from(json)))
              .toList();
      return teachers;
    } else {
      throw Exception('Failed to load teachers');
    }
  }

  /// Delete a user (student or teacher) by user_id. Requires auth token.
  static Future<http.Response> deleteUser(dynamic userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');
    final url = Uri.parse('${await getBaseUrl()}/user/$userId');
    return await http.delete(url, headers: _authHeaders(token));
  }

  /// Update user information (student or teacher) by user_id.
  /// Requires auth token and a body containing fields to update.
  static Future<http.Response> updateUser({
    required dynamic userId,
    required Map<String, dynamic> body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await getBaseUrl()}/user/$userId');

    print("Sending update: $body"); // 👈 Add this for debug

    return await http.put(
      url,
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
  }
}
