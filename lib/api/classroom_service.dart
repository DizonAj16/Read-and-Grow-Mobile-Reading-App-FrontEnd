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

      final studentCount =
          (classDetails['student_enrollments'] as List<dynamic>?)?.length ?? 0;
      classDetails['student_count'] = studentCount;
      final teacher = classDetails['teacher'];
      classDetails['teacher_name'] =
      teacher != null ? teacher['teacher_name'] ?? 'N/A' : 'N/A';

      return classDetails;
    } catch (e) {
      print('Error fetching class details: $e');
      return {};
    }
  }

  static Future<List<Classroom>> fetchTeacherClasses() async {
    final supabase = Supabase.instance.client;

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('No logged-in teacher');

      final teacher = await supabase
          .from('teachers')
          .select('id')
          .eq('user_id', currentUser.id)
          .single();

      final teacherId = teacher['id'];
      final response = await supabase
          .from('class_rooms')
          .select('id, class_name, section, teacher_id, student_enrollments(count)')
          .eq('teacher_id', teacherId);

      return (response as List<dynamic>).map((json) {
        final data = Map<String, dynamic>.from(json);
        final enrollments = data['student_enrollments'] as List?;
        final studentCount =
        (enrollments != null && enrollments.isNotEmpty)
            ? (enrollments.first['count'] ?? 0)
            : 0;

        data['student_count'] = studentCount;
        return Classroom.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching teacher classes: $e');
      return [];
    }
  }

  static Future<int> fetchStudentCount(String classId) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('class_students')
          .select('id')
          .eq('class_room_id', classId);

      return response.length;
    } catch (e) {
      print('Error fetching student count for class $classId: $e');
      return 0;
    }
  }

  static Future<List<Classroom>> getStudentClasses() async {
    final supabase = Supabase.instance.client;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("No logged-in student");

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
        grade_level,
        section,
        school_year,
        teacher_id,
        teacher:teachers (
          teacher_name,
          teacher_email,
          teacher_position,
          profile_picture
        ),
        student_enrollments (student_id)
      )
    ''')
          .eq('student_id', studentId);

      return (response as List<dynamic>).map((item) {
        final classRoom = Map<String, dynamic>.from(item['class_rooms'] ?? {});
        final teacher = classRoom['teacher'] ?? {};
        final enrollments = classRoom['student_enrollments'] as List? ?? [];

        classRoom['student_count'] = enrollments.length;
        classRoom['teacher_name'] = teacher['teacher_name'];
        classRoom['teacher_email'] = teacher['teacher_email'];
        classRoom['teacher_position'] = teacher['teacher_position'];
        classRoom['teacher_avatar'] = teacher['profile_picture'];

        return Classroom.fromJson(classRoom);
      }).toList();
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
      final assignedResponse = await supabase
          .from('student_enrollments')
          .select('student_id');

      final assignedIds = (assignedResponse as List)
          .map((e) => e['student_id'] as String)
          .toList();
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
      // 1️⃣ Find the class by its code
      final classData = await supabase
          .from('class_rooms')
          .select('id, class_name, teacher_id')
          .eq('classroom_code', classCode)
          .maybeSingle();

      if (classData == null) {
        return {
          'success': false,
          'message': 'Class not found for the given code.',
        };
      }

      // 2️⃣ Get the current user's corresponding student record
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated.',
        };
      }

      final student = await supabase
          .from('students')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (student == null) {
        return {
          'success': false,
          'message': 'Student record not found.',
        };
      }

      final studentId = student['id'];

      // 3️⃣ Check if already enrolled
      final existing = await supabase
          .from('student_enrollments')
          .select('student_id')
          .eq('student_id', studentId)
          .eq('class_room_id', classData['id'])
          .maybeSingle();

      if (existing != null) {
        return {
          'success': false,
          'message': 'You are already enrolled in this class.',
        };
      }

      // 4️⃣ Insert new enrollment
      final inserted = await supabase
          .from('student_enrollments')
          .insert({
        'student_id': studentId,
        'class_room_id': classData['id'],
      })
          .select()
          .maybeSingle();

      return {
        'success': true,
        'class': classData,
        'enrollment': inserted,
        'message': 'Successfully joined the class!',
      };
    } catch (e) {
      print("❌ Error joining class: $e");
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