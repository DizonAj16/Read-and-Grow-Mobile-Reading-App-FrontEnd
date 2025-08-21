import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_model.dart';
import '../models/classroom_model.dart';

class PrefsService {
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

  static Future<void> storeTeacherClassesToPrefs(List<Classroom> classes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('teacher_classes', Classroom.encodeList(classes));
  }

  static Future<List<Classroom>> getTeacherClassesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('teacher_classes');
    if (jsonString == null) return [];
    return Classroom.decodeList(jsonString);
  }

  static Future<void> storeStudentClassesToPrefs(List<Classroom> classes) async {
    final prefs = await SharedPreferences.getInstance();
    if (classes.isEmpty) {
      await prefs.remove('student_classes');
    } else {
      String jsonString = jsonEncode(classes.map((e) => e.toJson()).toList());
      await prefs.setString('student_classes', jsonString);
    }
  }

  static Future<List<Classroom>> getStudentClassesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('student_classes');
    if (jsonString == null) return [];
    return Classroom.decodeList(jsonString);
  }

  static Future<void> clearStudentClassesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('student_classes');
  }
}