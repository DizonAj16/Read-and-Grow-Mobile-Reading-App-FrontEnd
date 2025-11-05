import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../utils/validators.dart';
import '../utils/data_validators.dart';
import '../utils/database_helpers.dart';

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
    try {
      final teacher = Teacher.fromJson(details);
      await teacher.saveToPrefs();
    } catch (e) {
      print('Error storing teacher details: $e');
    }
  }

  static Future<void> storeStudentDetails(Map<String, dynamic> details) async {
    try {
      final student = Student.fromJson(details);
      await student.saveToPrefs();
    } catch (e) {
      print('Error storing student details: $e');
    }
  }

  static final _sb = Supabase.instance.client;

  static Future<Map<String, dynamic>?> registerStudent(Map<String, dynamic> data) async {
    try {
      // Validate student data before registration
      final studentData = {
        'student_name': data['student_name'],
        'student_lrn': data['student_lrn'],
        'username': data['student_username'],
      };
      
      final validationErrors = DataValidators.validateStudentData(studentData);
      if (DataValidators.hasErrors(validationErrors)) {
        return {'error': DataValidators.getErrorMessage(validationErrors)};
      }

      // Validate username
      final usernameError = Validators.validateUsername(data['student_username'] as String?);
      if (usernameError != null) {
        return {'error': usernameError};
      }

      // Validate password
      final passwordError = Validators.validatePassword(data['student_password'] as String?);
      if (passwordError != null) {
        return {'error': passwordError};
      }

      // Check for duplicate username
      final usernameExists = await DatabaseHelpers.safeExists(
        supabase: _sb,
        table: 'users',
        filters: {'username': data['student_username']},
      );
      if (usernameExists) {
        return {'error': 'Username already exists'};
      }

      // Check for duplicate LRN
      final lrnExists = await DatabaseHelpers.safeExists(
        supabase: _sb,
        table: 'students',
        filters: {'student_lrn': data['student_lrn']},
      );
      if (lrnExists) {
        return {'error': 'LRN already exists'};
      }

      // Step 1: Create Supabase Auth account first
      final authEmail = "${data['student_username']}@student.app";
      String? userId;
      try {
        final authResponse = await _sb.auth.signUp(
          email: authEmail,
          password: data['student_password'] as String,
          data: {
            'username': data['student_username'],
            'name': data['student_name'],
          },
        );

        if (authResponse.user == null) {
          return {'error': 'Failed to create authentication account'};
        }
        userId = authResponse.user!.id;
      } catch (e) {
        print('❌ Auth signup error: $e');
        return {'error': 'Failed to create authentication account: $e'};
      }

      // Step 2: Create user record
      final userData = {
        'id': userId,
        'username': data['student_username'],
        'password': data['student_password'],
        'role': 'student',
      };

      final userResponse = await DatabaseHelpers.safeInsert(
        supabase: _sb,
        table: 'users',
        data: userData,
      );

      if (userResponse == null || userResponse.containsKey('error')) {
        // Rollback: delete auth user if user creation failed
        try {
          await _sb.auth.admin.deleteUser(userId);
        } catch (e) {
          print('Error rolling back auth user: $e');
        }
        return userResponse ?? {'error': 'Failed to create user account'};
      }

      // Step 2: Create student linked to that user
      final studentDataMap = {
        'id': userId,
        'student_name': data['student_name'],
        'student_lrn': data['student_lrn'],
        'student_grade': data['student_grade']?.toString().trim(),
        'student_section': data['student_section']?.toString().trim(),
        'username': data['student_username'],
      };

      // Remove null/empty values
      studentDataMap.removeWhere((key, value) => value == null || value.toString().isEmpty);

      final studentResponse = await DatabaseHelpers.safeInsert(
        supabase: _sb,
        table: 'students',
        data: studentDataMap,
      );

      if (studentResponse == null || studentResponse.containsKey('error')) {
        // Rollback: delete user if student creation failed
        try {
          await _sb.from('users').delete().eq('id', userId);
        } catch (e) {
          print('Error rolling back user creation: $e');
        }
        return studentResponse ?? {'error': 'Failed to create student profile'};
      }

      print('✅ Student created successfully!');
      return studentResponse;
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
      // Validate teacher data
      final validationErrors = DataValidators.validateTeacherData(body);
      if (DataValidators.hasErrors(validationErrors)) {
        return {'error': DataValidators.getErrorMessage(validationErrors)};
      }

      // Check for duplicate email
      final emailExists = await DatabaseHelpers.safeExists(
        supabase: supabase,
        table: 'teachers',
        filters: {'teacher_email': body['teacher_email']},
      );
      if (emailExists) {
        return {'error': 'Email already exists'};
      }

      // Clean data - remove null values
      final cleanBody = Map<String, dynamic>.from(
        body..removeWhere((key, value) => value == null || value.toString().trim().isEmpty),
      );

      final response = await DatabaseHelpers.safeInsert(
        supabase: supabase,
        table: 'teachers',
        data: cleanBody,
      );

      if (response != null && response.containsKey('error')) {
        return response;
      }

      return response;
    } catch (e) {
      print('Error registering teacher: $e');
      return {'error': e.toString()};
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
      debugPrint('📸 [UPLOAD_PROFILE] Starting upload - User: $userId, Role: $role');

      // 1️⃣ Validate inputs
      if (userId.isEmpty || !Validators.isValidUUID(userId)) {
        debugPrint('❌ [UPLOAD_PROFILE] Invalid user ID: $userId');
        return null;
      }

      if (role != 'teacher' && role != 'student') {
        debugPrint('❌ [UPLOAD_PROFILE] Invalid role: $role');
        return null;
      }

      // 2️⃣ Validate file exists
      final originalFile = File(filePath);
      if (!await originalFile.exists()) {
        debugPrint('❌ [UPLOAD_PROFILE] File does not exist: $filePath');
        return null;
      }

      // 3️⃣ Validate file size (max 5MB for profile pictures)
      final fileSize = await originalFile.length();
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (fileSize > maxSize) {
        debugPrint('❌ [UPLOAD_PROFILE] File too large: ${fileSize / 1024 / 1024}MB');
        return null;
      }

      // 4️⃣ Determine bucket and file extension
      final bucket = role == 'teacher' ? 'materials' : 'materials';
      final fileExtension = filePath.split('.').last.toLowerCase();
      final validExtension = (fileExtension == 'jpg' || fileExtension == 'jpeg' || fileExtension == 'png')
          ? fileExtension
          : 'png'; // Default to png if invalid

      debugPrint('📸 [UPLOAD_PROFILE] Using bucket: $bucket, extension: $validExtension, size: ${fileSize / 1024}KB');

      // 5️⃣ Create unique filename with proper extension
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId-$timestamp.$validExtension';

      // 6️⃣ Read file bytes
      final fileBytes = await originalFile.readAsBytes();
      debugPrint('📸 [UPLOAD_PROFILE] Read ${fileBytes.length} bytes');

      // 7️⃣ Determine content type
      final contentType = validExtension == 'png'
          ? 'image/png'
          : 'image/jpeg';

      // 8️⃣ Upload to Supabase Storage
      debugPrint('📸 [UPLOAD_PROFILE] Uploading to storage...');
      await supabase.storage.from(bucket).uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: contentType,
        ),
      );

      debugPrint('✅ [UPLOAD_PROFILE] File uploaded to storage');

      // 9️⃣ Get public URL
      final publicUrl = supabase.storage.from(bucket).getPublicUrl(fileName);

      if (publicUrl.isEmpty) {
        debugPrint('❌ [UPLOAD_PROFILE] Failed to get public URL');
        throw Exception('Failed to get public URL for uploaded file');
      }

      debugPrint('✅ [UPLOAD_PROFILE] Public URL: $publicUrl');

      // 🔟 Update database record
      final table = role == 'teacher' ? 'teachers' : 'students';
      debugPrint('📸 [UPLOAD_PROFILE] Updating $table table...');
      debugPrint('📸 [UPLOAD_PROFILE] Using userId: $userId, table: $table');
      
      // For teachers and students, the id in their respective tables matches the user id
      final updateResult = await supabase.from(table).update({
        'profile_picture': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId).select();
      
      debugPrint('📸 [UPLOAD_PROFILE] Update result: ${updateResult.length} rows updated');

      if (updateResult.isEmpty) {
        debugPrint('❌ [UPLOAD_PROFILE] Failed to update database');
        throw Exception('Failed to update profile picture in database');
      }

      debugPrint("✅ [UPLOAD_PROFILE] Profile picture uploaded successfully: $publicUrl");
      return publicUrl;
    } catch (e, stackTrace) {
      debugPrint("❌ [UPLOAD_PROFILE] Error uploading profile picture: $e");
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateStudentSelf({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final supabase = Supabase.instance.client;
    try {
      if (data.containsKey('username')) {
        await supabase.from('users').update({
          'username': data['username'],
        }).eq('id', userId);
      }

      final updatePayload = <String, dynamic>{};
      if (data.containsKey('student_name')) {
        updatePayload['student_name'] = data['student_name'];
      }
      if (data.containsKey('student_lrn')) {
        updatePayload['student_lrn'] = data['student_lrn'];
      }
      if (data.containsKey('student_grade')) {
        updatePayload['student_grade'] = data['student_grade'];
      }
      if (data.containsKey('student_section')) {
        updatePayload['student_section'] = data['student_section'];
      }

      if (updatePayload.isNotEmpty) {
        final updated = await supabase
            .from('students')
            .update(updatePayload)
            .eq('id', userId)
            .select()
            .single();
        return Map<String, dynamic>.from(updated);
      }

      return {};
    } catch (e) {
      print('Error updating student self: $e');
      return null;
    }
  }

  static Future<bool> updateStudentByAdmin({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final supabase = Supabase.instance.client;
    try {
      if (data.containsKey('username')) {
        await supabase.from('users').update({
          'username': data['username'],
        }).eq('id', userId);
      }

      final updatePayload = <String, dynamic>{};
      if (data.containsKey('student_name')) updatePayload['student_name'] = data['student_name'];
      if (data.containsKey('student_lrn')) updatePayload['student_lrn'] = data['student_lrn'];
      if (data.containsKey('student_grade')) updatePayload['student_grade'] = data['student_grade'];
      if (data.containsKey('student_section')) updatePayload['student_section'] = data['student_section'];

      if (updatePayload.isNotEmpty) {
        await supabase
            .from('students')
            .update(updatePayload)
            .eq('id', userId);
      }
      return true;
    } catch (e) {
      print('Error admin updating student: $e');
      return false;
    }
  }

  static Future<bool> deleteStudentByAdmin({
    required String userId,
  }) async {
    final supabase = Supabase.instance.client;
    try {
      // Fetch students.id for this user
      final studentRow = await supabase
          .from('students')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      final String? studentId = studentRow != null ? studentRow['id'] as String? : null;

      // Delete dependent rows
      if (studentId != null) {
        await supabase.from('student_enrollments').delete().eq('student_id', studentId);
        await supabase.from('student_task_progress').delete().eq('student_id', studentId);
      }
      // student_submissions references users.id
      await supabase.from('student_submissions').delete().eq('student_id', userId);

      // Delete student row
      await supabase.from('students').delete().eq('id', userId);

      // Finally delete user
      await supabase.from('users').delete().eq('id', userId);

      return true;
    } catch (e) {
      print('Error admin deleting student: $e');
      return false;
    }
  }

  static Future<bool> assignReadingLevelToStudent({
    required String userId,
    required String readingLevelId,
  }) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('students')
          .update({'current_reading_level_id': readingLevelId})
          .eq('id', userId);
      return true;
    } catch (e) {
      print('Error assigning reading level: $e');
      return false;
    }
  }
}