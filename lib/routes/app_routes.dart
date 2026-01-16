import 'package:flutter/material.dart';
import '../pages/admin pages/admin_page.dart';
import '../pages/auth pages/teacher/teacher_signup_page.dart';
import '../pages/auth pages/student/student_signup_page.dart';
import '../pages/student pages/student_page.dart';
import '../pages/teacher pages/teacher_page.dart';

class AppRoutes {
  static const String landing = '/';
  static const String teacherLogin = 'teacher/login';
  static const String studentLogin = 'student/login';
  static const String teacherSignup = '/teacher-signup';
  static const String studentSignup = '/student-signup';
  static const String studentDashboard = '/studentDashboard';
  static const String teacherDashboard = '/teacherDashboard';
  static const String adminDashboard = '/adminDashboard';

  static final Map<String, WidgetBuilder> routes = {
    teacherSignup: (context) => TeacherSignUpPage(),
    studentSignup: (context) => StudentSignUpPage(),
    studentDashboard: (context) => StudentPage(),
    teacherDashboard: (context) => TeacherPage(),
    adminDashboard: (context) => AdminPage(),
  };
}
