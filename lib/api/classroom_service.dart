import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/classroom_model.dart';
import '../models/quiz_questions.dart';
import '../models/student_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassroomService {

  static Future<Map<String, dynamic>?> createClassV2({
    required String className,
    required String gradeLevel,
    required String section,
    required String schoolYear,
    required String classroomCode,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        print('No logged-in teacher found');
        return null;
      }

      final teacher = await supabase
          .from('teachers')
          .select('id')
          .eq('user_id', currentUser.id)
          .single();

      if (teacher == null || teacher['id'] == null) {
        print('Teacher record not found');
        return null;
      }

      final response = await supabase.from('class_rooms').insert({
        'teacher_id': teacher['id'],
        'class_name': className,
        'grade_level': gradeLevel,
        'section': section,
        'school_year': schoolYear,
        'classroom_code': classroomCode,
      }).select().single();

      return response;
    } catch (e) {
      print('Error inserting class_room: $e');
      return null;
    }
  }


  static Future<List<Map<String, dynamic>>> fetchStudentQuizzes(String studentId) async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('student_enrollments')
        .select('''
        class_room_id,
        class_room:class_rooms(
          class_name,
          assignments(
            id,
            task:tasks(
              id,
              title,
              quizzes(id, title)
            )
          )
        )
      ''')
        .eq('student_id', studentId);

    // Map into a flat list of quizzes
    List<Map<String, dynamic>> results = [];

    for (var enrollment in response) {
      final classRoom = enrollment['class_room'];
      final className = classRoom['class_name'];
      final assignments = classRoom['assignments'] ?? [];

      for (var assignment in assignments) {
        final task = assignment['task'];
        if (task == null) continue;

        final quizzes = task['quizzes'] ?? [];
        for (var quiz in quizzes) {
          results.add({
            'assignment_id': assignment['id'],
            'quiz_id': quiz['id'],
            'quiz_title': quiz['title'],
            'class_name': className,
            'task_title': task['title'],
          });
        }
      }
    }

    return results;
  }

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

  static Future<Map<String, dynamic>?> deleteClass(String classId) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('class_rooms')
          .delete()
          .eq('id', classId)
          .select()
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error deleting class: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getClassDetails(String classId) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('class_rooms')
          .select('*, student_enrollments(*), teacher:teachers(teacher_name)')
          .eq('id', classId)
          .maybeSingle();

      if (response == null) return {};

      final classDetails = Map<String, dynamic>.from(response as Map);

      // Count students
      final studentCount =
          (classDetails['student_enrollments'] as List<dynamic>?)?.length ?? 0;
      classDetails['student_count'] = studentCount;

      // Flatten teacher_name for UI
      final teacher = classDetails['teacher'];
      classDetails['teacher_name'] =
      teacher != null ? teacher['teacher_name'] ?? 'N/A' : 'N/A';

      return classDetails;
    } catch (e) {
      print('Error fetching class details: $e');
      return {};
    }
  }

  /// TEACHER CLASSES
  static Future<List<Classroom>> fetchTeacherClasses() async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.from('class_rooms').select();

      if (response == null) {
        return [];
      }

      return (response as List<dynamic>)
          .map((json) => Classroom.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('Error fetching teacher classes: $e');
      return [];
    }
  }
  static Future<List<Classroom>> getStudentClasses() async {
    final supabase = Supabase.instance.client;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("No logged in student");

      final student = await supabase
          .from('students')
          .select('id')
          .eq('user_id', user.id)
          .single();

      final studentId = student['id'];

      final response = await supabase
          .from('student_enrollments')
          .select('''
          class_room_id,
          class_rooms (
            id,
            class_name,
            section,
            assignments (
              id,
              task_id,
              due_date,
              instructions,
              tasks (
                id,
                title,
                description
              )
            )
          )
        ''')
          .eq('student_id', studentId);

      return (response as List<dynamic>)
          .map((json) => Classroom.fromJson(Map<String, dynamic>.from(json['class_rooms'])))
          .toList();
    } catch (e) {
      print('Error fetching student classes: $e');
      return [];
    }
  }


  static Future<Map<String, dynamic>?> assignStudent({
    required String studentId,
    required String classRoomId,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase.from('student_enrollments').insert({
        'student_id': studentId,
        'class_room_id': classRoomId,
      }).select().single();

      return response;
    } catch (e) {
      print('Error assigning student to class: $e');
      return null;
    }
  }
  static Future<http.Response> unassignStudent({required String studentId}) async {
    try {
      final supabase = Supabase.instance.client;

      // Delete the enrollment record for this student
      final res = await supabase
          .from('student_enrollments')
          .delete()
          .eq('student_id', studentId);



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


  /// Fetch only assigned student IDs
  static Future<Set<String>> getAssignedStudentIds() async {
    try {
      final supabase = Supabase.instance.client;

      final assignedResponse = await supabase
          .from('student_enrollments')
          .select('student_id');

      final assignedIds = (assignedResponse as List)
          .map((e) => e['student_id'] as String)
          .toSet();

      return assignedIds;
    } catch (e) {
      print('Error fetching assigned student IDs: $e');
      throw Exception('Failed to fetch assigned students');
    }
  }


  static Future<List<Student>> getAssignedStudents() async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('students')
          .select();

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

      // Get all assigned student IDs first
      final assignedResponse = await supabase
          .from('student_enrollments')
          .select('student_id');

      final assignedIds = (assignedResponse as List)
          .map((e) => e['student_id'] as String)
          .toList();

      // Fetch students NOT in the assignedIds list
      final response = await supabase
          .from('students')
          .select()
          .filter('id', 'not.in', '(${assignedIds.join(',')})');

      final List<dynamic> list = response ?? [];
      return list
          .map((json) => Student.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('Error fetching unassigned students: $e');
      throw Exception('Failed to fetch unassigned students');
    }
  }

  static Future<List<Student>> getAllStudents() async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.from('students').select();

      final List<dynamic> list = response ?? [];
      return list
          .map((json) => Student.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('Error fetching all students: $e');
      throw Exception('Failed to fetch students');
    }
  }

  static Future<Map<String, dynamic>> joinClass(String classCode) async {
    final supabase = Supabase.instance.client;

    try {
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

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

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


  static Future<http.Response?> uploadClassBackground({
    required String classId,
    required String filePath,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      final fileName =
          'class_backgrounds/$classId-${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg';

      final fileBytes = await File(filePath).readAsBytes();
      await supabase.storage.from('class_backgrounds').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl =
      supabase.storage.from('class_backgrounds').getPublicUrl(fileName);

      final response = await supabase.from('class_rooms').update({
        'background_url': publicUrl,
      }).eq('id', classId).select().single();

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