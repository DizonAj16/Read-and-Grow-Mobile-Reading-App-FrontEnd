import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/classroom.dart';
import '../models/student.dart';
import '../models/teacher.dart';

class ApiService {
  static Future<String> getBaseUrl() async {
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

  static Future<void> _storeTeacherDetails(Map<String, dynamic> details) async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
    final uri = Uri.parse(savedBaseUrl);
    final baseUrl = '${uri.scheme}://${uri.authority}';

    final teacher = Teacher.fromJson(details);
    if (teacher.profilePicture != null &&
        !teacher.profilePicture!.startsWith('http')) {
      teacher.profilePicture =
          '$baseUrl/storage/profile_images/${teacher.profilePicture}';
    }

    await teacher.saveToPrefs();
  }

  static Future<void> _storeStudentDetails(Map<String, dynamic> details) async {
    final student = Student.fromJson(details);
    await student.saveToPrefs();
    final prefs = await SharedPreferences.getInstance();
    if (details['user_id'] != null) {
      await prefs.setString('user_id', details['user_id'].toString());
    }
  }

  static Future<http.Response> registerStudent(
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await getBaseUrl()}/register/student');
    return await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> registerTeacher(
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await getBaseUrl()}/register/teacher');
    return await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> login(Map<String, dynamic> body) async {
    final url = Uri.parse('${await getBaseUrl()}/auth/login');
    final loginBody = {'login': body['login'], 'password': body['password']};
    final response = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(loginBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('role', data['role']);

      if (data['role'] == 'teacher' && data['details'] != null) {
        await _storeTeacherDetails(data['details']);
        await _fetchAndStoreTeacherClasses();
      }

      if (data['role'] == 'student' && data['details'] != null) {
        await _storeStudentDetails(data['details']);
        if (data['student_class'] != null) {
          List<Classroom> classes =
              (data['student_class'] as List)
                  .map(
                    (json) =>
                        Classroom.fromJson(Map<String, dynamic>.from(json)),
                  )
                  .toList();
          await storeStudentClassesToPrefs(classes);
        }
      }
    }

    return response;
  }

  static Future<http.Response> logout(String token) async {
    final url = Uri.parse('${await getBaseUrl()}/auth/logout');
    return await http.post(url, headers: _authHeaders(token));
  }

  static Future<Map<String, dynamic>> adminLogin(
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${await getBaseUrl()}/auth/admin/login');
    final response = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {'success': true, ...data};
    } else if (response.statusCode == 401 && data['step'] == 2) {
      return {'success': false, 'step': 2, 'message': data['message']};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    }
  }

  static Future<List<Student>> fetchAllStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final response = await http.get(
      Uri.parse('${await getBaseUrl()}/teachers/students'),
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

  static Future<void> storeStudentsToPrefs(List<Student> students) async {
    final prefs = await SharedPreferences.getInstance();
    final filtered = students.map((s) => s.toJson()).toList();
    await prefs.setString('students_data', jsonEncode(filtered));
  }

  static Future<List<Student>> getStudentsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('students_data');
    if (jsonString == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded
        .map((e) => Student.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<Teacher>> fetchAllTeachers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final response = await http.get(
      Uri.parse('${await getBaseUrl()}/teachers/'),
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

  static Future<http.Response> deleteUser(dynamic userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final role = prefs.getString('role');
    String url;
    if (role == 'teacher') {
      url = '${await getBaseUrl()}/teachers/users/$userId';
    } else {
      url = '${await getBaseUrl()}/admins/users/$userId';
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
      url = '${await getBaseUrl()}/teachers/users/$userId';
    } else {
      url = '${await getBaseUrl()}/admins/users/$userId';
    }

    return await http.put(
      Uri.parse(url),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> createClass(Map<String, dynamic> body) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await getBaseUrl()}/classrooms');
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

    final url = Uri.parse('${await getBaseUrl()}/classrooms/$classId');
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

    final url = Uri.parse('${await getBaseUrl()}/classrooms/$classId');
    return await http.delete(url, headers: _authHeaders(token));
  }

  static Future<Map<String, dynamic>> getClassDetails(int classId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await getBaseUrl()}/classrooms/$classId');
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

    final url = Uri.parse('${await getBaseUrl()}/classrooms');
    final response = await http.get(url, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Classroom.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch classes');
    }
  }

  static Future<void> _fetchAndStoreTeacherClasses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classes = await fetchTeacherClasses();
      await prefs.setString('teacher_classes', Classroom.encodeList(classes));
    } catch (e) {
      print("Error storing teacher classes: $e");
    }
  }

  static Future<List<Classroom>> getTeacherClassesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('teacher_classes');
    if (jsonString == null) return [];
    return Classroom.decodeList(jsonString);
  }

  static Future<void> storeClassesToPrefs(List<Classroom> classes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('teacher_classes', Classroom.encodeList(classes));
  }

  static Future<List<Classroom>> getClassesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('teacher_classes');
    if (jsonString == null) return [];
    return Classroom.decodeList(jsonString);
  }

  static Future<List<Classroom>> getStudentClasses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await getBaseUrl()}/students/my-classes');
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

  static Future<void> storeStudentClassesToPrefs(
    List<Classroom> classes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_classes', Classroom.encodeList(classes));
  }

  static Future<List<Classroom>> getStudentClassesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('student_classes');
    if (jsonString == null) return [];
    return Classroom.decodeList(jsonString);
  }

  static Future<http.StreamedResponse> uploadProfilePicture({
    required String userId,
    required String role,
    required String filePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    String endpoint =
        (role == 'teacher')
            ? '/profile/teacher/upload'
            : '/profile/student/upload';

    final uri = Uri.parse('${await getBaseUrl()}$endpoint');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['${role}_id'] = userId;
    request.files.add(
      await http.MultipartFile.fromPath('profile_picture', filePath),
    );

    return await request.send();
  }

  static Future<http.Response> assignStudent({
    required int studentId,
    required int classRoomId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await getBaseUrl()}/classrooms/assign-student');
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

    final url = Uri.parse('${await getBaseUrl()}/classrooms/unassign-student');
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

    final url = Uri.parse('${await getBaseUrl()}/classrooms/$classId/students');
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

    final url = Uri.parse(
      '${await getBaseUrl()}/classrooms/students/unassigned',
    );
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

  static Future<http.StreamedResponse> uploadClassBackground({
    required int classId,
    required String filePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse(
      '${await getBaseUrl()}/classrooms/$classId/upload-background',
    );
    final request = http.MultipartRequest('POST', url);

    request.headers.addAll(_authHeaders(token));
    request.files.add(
      await http.MultipartFile.fromPath('background_image', filePath),
    );

    return await request.send();
  }

  static Future<List<Student>> fetchClassmates() async {
    final response = await http.get(
      Uri.parse('${await getBaseUrl()}/students/classmates'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final classmates =
          (data['classmates'] as List)
              .map((json) => Student.fromJson(Map<String, dynamic>.from(json)))
              .toList();
      return classmates;
    } else {
      throw Exception('Failed to load classmates');
    }
  }

  // ✅ FIXED: moved outside the fetchClassmates method
  static Future<String?> getStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }
}
