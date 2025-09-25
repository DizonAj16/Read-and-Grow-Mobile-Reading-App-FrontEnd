import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/classroom_model.dart';
import '../models/student_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassroomService {
  static Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') ?? "http://10.0.2.2:8000/api";
  }

  static Map<String, String> _authHeaders(String token) =>
      {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  // static Future<http.Response> createClass(Map<String, dynamic> body) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');
  //   if (token == null) throw Exception('No auth token found');
  //
  //   final url = Uri.parse('${await _getBaseUrl()}/classrooms');
  //   return await http.post(
  //     url,
  //     headers: _authHeaders(token),
  //     body: jsonEncode(body),
  //   );
  // }

  static Future<Map<String, dynamic>?> createClassV2() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.from('class_rooms').insert({
        'grade_level_id': '79c1fe62-e993-4183-b191-e3b18b464963',
        'teacher_id': 'ca5142cc-1ec6-4867-9762-6a7751d5620a',
        'class_name': 'Math 101',
        'grade_level': '2',
        'section': 'A',
        'school_year': '2022',
        'classroom_code': '2',
      }).select().single();

      if (response != null) {
        // Return the inserted record as a Map
        return response;
      } else {
        // Insert succeeded but no data returned (rare)
        return null;
      }
    } catch (e) {
      print('Error inserting class_room: $e');
      return null;
    }
  }


  // static Future<http.Response> updateClass({
  //   required int classId,
  //   required Map<String, dynamic> body,
  // }) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');
  //   if (token == null) throw Exception('No auth token found');
  //
  //   final url = Uri.parse('${await _getBaseUrl()}/classrooms/$classId');
  //   return await http.put(
  //     url,
  //     headers: _authHeaders(token),
  //     body: jsonEncode(body),
  //   );
  // }

  static Future<Map<String, dynamic>?> updateClass({
    required String classId,

    required Map<String, dynamic> body,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('class_rooms')
          .update(body)
          .eq('id', classId)
          .select()
          .single();

      return response;
    } catch (e) {
      print('Error updating class: $e');
      return null;
    }
  }

  static Future<http.Response> deleteClass(String classId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('No auth token found');

    final url = Uri.parse('${await _getBaseUrl()}/classrooms/$classId');
    return await http.delete(url, headers: _authHeaders(token));
  }

  static Future<Map<String, dynamic>> getClassDetails(String classId) async {
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

  // static Future<List<Classroom>> fetchTeacherClasses() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString('token');
  //   if (token == null) throw Exception('No auth token found');
  //
  //   final url = Uri.parse('${await _getBaseUrl()}/classrooms');
  //   final response = await http.get(url, headers: _authHeaders(token));
  //
  //   if (response.statusCode == 200) {
  //     final List<dynamic> data = jsonDecode(response.body);
  //     return data.map((json) => Classroom.fromJson(json)).toList();
  //   } else {
  //     throw Exception('Failed to fetch classes');
  //   }
  // }
  //

  /// TEACHER CLASSES
  static Future<List<Classroom>> fetchTeacherClasses() async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.from('class_rooms').select();

      // Supabase returns a List<dynamic>, so we just map it
      return (response as List<dynamic>)
          .map((json) => Classroom.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('Error fetching teacher classes: $e');
      return [];
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
    required String studentId,
    required String classRoomId,
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

  static Future<http.Response> unassignStudent({required String studentId}) async {
    try {
      final supabase = Supabase.instance.client;

      // Set the student's class_id to null to "unassign"
      final updates = await supabase
          .from('students')
          .update({'class_id': null})
          .eq('id', studentId);

      if (updates == null || updates.isEmpty) {
        return http.Response(
          '{"error": "Failed to unassign student"}',
          400,
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Return success response
      return http.Response(
        '{"message": "Student unassigned successfully"}',
        200,
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error unassigning student: $e');
      return http.Response(
        '{"error": "Failed to unassign student"}',
        500,
        headers: {'Content-Type': 'application/json'},
      );
    }
  }


  static Future<List<Student>> getAssignedStudents(String classId) async {
    try {
      final supabase = Supabase.instance.client;

      // Query all students where class_id matches
      final response = await supabase
          .from('students')
          .select()
          .eq('class_id', classId);

      final List<dynamic> list = response ?? [];
      return list
          .map((json) => Student.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('Error fetching assigned students: $e');
      throw Exception('Failed to fetch assigned students');
    }
  }


  static Future<List<Student>> getUnassignedStudents() async {
    try {
      final supabase = Supabase.instance.client;

      // Query all students where class_id is NULL (unassigned)
      final response = await supabase
          .from('students')
          .select()
          .isFilter('class_id', null);

      final List<dynamic> list = response ?? [];
      return list
          .map((json) => Student.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('Error fetching unassigned students: $e');
      throw Exception('Failed to fetch unassigned students');
    }
  }

  static Future<Map<String, dynamic>> joinClass(String classCode) async {  // doneeeeee
    final supabase = Supabase.instance.client;

    try {
      // Find class by classroom_code
      final classData = await supabase
          .from('class_rooms')
          .select()
          .eq('classroom_code', classCode)
          .maybeSingle();

      if (classData == null) {
        return {
          'success': false,
          'message': 'Class not found',
        };
      }

      // Get current user
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Insert into student_classes pivot table
      final inserted = await supabase.from('student_classes').insert({
        'student_id': userId,
        'class_id': classData['id'],
      }).select().maybeSingle();

      return {
        'success': true,
        'class': classData,
        'assignment': inserted,
      };
    } catch (e) {
      print("Error joining class: $e");
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }


  static Future<http.Response?> uploadClassBackground({  // doneeeeee
    required String classId, // UUID string
    required String filePath,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Generate unique path
      final fileName =
          'class_backgrounds/$classId-${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg';

      // Read file as bytes
      final fileBytes = await File(filePath).readAsBytes();

      // Upload to Supabase storage bucket
      await supabase.storage.from('class_backgrounds').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );

      // Get public URL of uploaded file
      final publicUrl =
      supabase.storage.from('class_backgrounds').getPublicUrl(fileName);

      // Update class record with new background
      final response = await supabase.from('class_rooms').update({
        'background_url': publicUrl,
      }).eq('id', classId).select().single();

      // Return a fake http.Response for compatibility
      return http.Response(
        jsonEncode({'background_image': publicUrl}),
        200,
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      print('Error uploading class background: $e');
      return null;
    }
  }
}