import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  static Future<Map<String, dynamic>?> registerStudent(
      Map<String, dynamic> body,) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('students') // change to your actual table name
          .insert(body)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error registering student: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> registerTeacher(
      Map<String, dynamic> body,) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('teachers') // adjust to your actual table name
          .insert(body)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error registering teacher: $e');
      return null;
    }
  }


  static Future<List<Student>> fetchAllStudents() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('students') // 👈 change if your table name is different
          .select();

      return (response as List)
          .map((json) => Student.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('Error fetching students: $e');
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

  static Future<String?> uploadProfilePicture({
    required String userId,
    required String role,
    required String filePath,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      // Choose bucket based on role
      final bucket = role == 'teacher' ? 'teacher-avatars' : 'student-avatars';

      // File name: userId + timestamp to avoid overwriting
      final fileName = '$userId-${DateTime
          .now()
          .millisecondsSinceEpoch}.png';

      // Upload file
      final fileBytes = await File(filePath).readAsBytes();
      await supabase.storage.from(bucket).uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );

      // Get public URL
      final publicUrl = supabase.storage.from(bucket).getPublicUrl(fileName);

      // Update DB table with new profile picture
      final table = role == 'teacher' ? 'teachers' : 'students';
      await supabase.from(table).update({
        'profile_picture': publicUrl,
      }).eq('id', userId);

      return publicUrl;
    } catch (e) {
     print("❌ Error uploading profile picture: $e");
      return null;
    }
  }
}