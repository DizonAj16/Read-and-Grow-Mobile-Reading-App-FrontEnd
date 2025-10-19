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

  static final _sb = Supabase.instance.client;

  static Future<Map<String, dynamic>?> registerStudent(Map<String, dynamic> data) async {
    try {
      // Step 1: Create user
      final userResponse = await _sb
          .from('users')
          .insert({
        'username': data['student_username'],
        'password': data['student_password'],
        'role': 'student',
      })
          .select()
          .maybeSingle(); // ✅ use maybeSingle()

      if (userResponse == null) {
        print('⚠️ No user returned from insert.');
        return null;
      }

      final userId = userResponse['id'];

      // Step 2: Create student linked to that user
      final studentResponse = await _sb
          .from('students')
          .insert({
        'user_id': userId,
        'student_name': data['student_name'],
        'student_lrn': data['student_lrn'],
        'student_grade': data['student_grade'],
        'student_section': data['student_section'],
        'student_username': data['student_username'],
        'student_password': data['student_password'],
      })
          .select()
          .maybeSingle(); // ✅ prevents exception if no row returned

      print('✅ Student created successfully!');
      return studentResponse ?? {'id': userId}; // ✅ ensures non-null success
    } on PostgrestException catch (e) {
      print('❌ Supabase error: ${e.message}');
      return {'error': e.message};
    } catch (e) {
      print('❌ Error registering student: $e');
      return {'error': e.toString()};
    }
  }



  static Future<Map<String, dynamic>?> registerTeacher(
      Map<String, dynamic> body,) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('teachers')
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
          .from('students')
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
      final bucket = role == 'teacher' ? 'teacher-avatars' : 'student-avatars';
      final fileName = '$userId-${DateTime
          .now()
          .millisecondsSinceEpoch}.png';
      final fileBytes = await File(filePath).readAsBytes();
      await supabase.storage.from(bucket).uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = supabase.storage.from(bucket).getPublicUrl(fileName);
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