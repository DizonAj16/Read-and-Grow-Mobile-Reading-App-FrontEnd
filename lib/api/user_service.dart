import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';

class UserService {
  static Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? "http://10.0.2.2:8000/api";
  }

  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Future<void> storeTeacherDetails(Map<String, dynamic> details) async {
    final teacher = Teacher.fromJson(details);
    await teacher.saveToPrefs();
  }

  static Future<void> storeStudentDetails(Map<String, dynamic> details) async {
    final student = Student.fromJson(details);
    await student.saveToPrefs();
  }

  static Future<http.Response> registerStudent(
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await _getBaseUrl()}/register/student');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> registerTeacher(
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await _getBaseUrl()}/register/teacher');
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
  }

  static Future<List<Student>> fetchAllStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final response = await http.get(
      Uri.parse('${await _getBaseUrl()}/teachers/students'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['students'] as List)
          .map((json) => Student.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } else {
      throw Exception('Failed to load students');
    }
  }

  static Future<List<Teacher>> fetchAllTeachers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final response = await http.get(
      Uri.parse('${await _getBaseUrl()}/teachers/'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['teachers'] as List)
          .map((json) => Teacher.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } else {
      throw Exception('Failed to load teachers');
    }
  }

  static Future<http.Response> deleteUser(dynamic userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final role = prefs.getString('role');
    String url;
    if (role == 'teacher') {
      url = '${await _getBaseUrl()}/teachers/users/$userId';
    } else {
      url = '${await _getBaseUrl()}/admins/users/$userId';
    }
    return await http.delete(Uri.parse(url), headers: _authHeaders(token));
  }

  static Future<http.Response> updateUser({
    required dynamic userId,
    required Map<String, dynamic> body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final role = prefs.getString('role');
    String url;
    if (role == 'teacher') {
      url = '${await _getBaseUrl()}/teachers/users/$userId';
    } else {
      url = '${await _getBaseUrl()}/admins/users/$userId';
    }

    return await http.put(
      Uri.parse(url),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
  }

  static Future<http.StreamedResponse> uploadProfilePicture({
    required String userId,
    required String role,
    required String filePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // use one dynamic endpoint for both roles
    final uri = Uri.parse('${await _getBaseUrl()}/profile/$role/upload');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    // ✅ Laravel expects `user_id`, not `teacher_id` or `student_id`
    request.fields['user_id'] = userId;

    request.files.add(
      await http.MultipartFile.fromPath('profile_picture', filePath),
    );

    return await request.send();
  }
}
