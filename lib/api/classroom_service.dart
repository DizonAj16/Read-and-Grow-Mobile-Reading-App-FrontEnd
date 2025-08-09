import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/classroom.dart';
import '../models/student.dart';

class ClassroomService {
  static Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? "http://10.0.2.2:8000/api";
  }

  static Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Future<http.Response> createClass(Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/classrooms');
    return await http.post(
      url,
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> updateClass({
    required int classId,
    required Map<String, dynamic> body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/classrooms/$classId');
    return await http.put(
      url,
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> deleteClass(int classId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/classrooms/$classId');
    return await http.delete(url, headers: _authHeaders(token));
  }

  static Future<Map<String, dynamic>> getClassDetails(int classId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/classrooms/$classId');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load class details');
    }
  }

  static Future<List<Classroom>> fetchTeacherClasses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/classrooms');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Classroom.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch classes');
    }
  }

  static Future<List<Classroom>> getStudentClasses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/students/my-classes');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> classes = data['data'];
        return classes
            .map((json) => Classroom.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to fetch student classes');
    }
  }

  static Future<http.Response> assignStudent({
    required int studentId,
    required int classRoomId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/classrooms/assign-student');
    return http.post(
      url,
      headers: _authHeaders(token),
      body: jsonEncode({'student_id': studentId, 'class_room_id': classRoomId}),
    );
  }

  static Future<http.Response> unassignStudent({required int studentId}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/classrooms/unassign-student');
    return http.post(
      url,
      headers: _authHeaders(token),
      body: jsonEncode({'student_id': studentId}),
    );
  }

  static Future<List<Student>> getAssignedStudents(int classId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/classrooms/$classId/students');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['students'] ?? [];
      return list
          .map((json) => Student.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } else {
      throw Exception('Failed to fetch assigned students');
    }
  }

  static Future<List<Student>> getUnassignedStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/classrooms/students/unassigned');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['unassigned_students'] ?? [];
      return list
          .map((json) => Student.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } else {
      throw Exception('Failed to fetch unassigned students');
    }
  }

  static Future<http.Response> joinClass(String classCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/classrooms/join');
    return await http.post(
      url,
      headers: _authHeaders(token),
      body: jsonEncode({'classroom_code': classCode}),
    );
  }

  static Future<http.StreamedResponse> uploadClassBackground({
    required int classId,
    required String filePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/classrooms/$classId/upload-background');
    final request = http.MultipartRequest('POST', url);

    request.headers.addAll(_authHeaders(token));
    request.files.add(await http.MultipartFile.fromPath('background_image', filePath));

    return await request.send();
  }
}