import 'package:flutter/material.dart';
import '../pages/admin pages/admin_page.dart';
import '../pages/auth pages/login_page.dart';
import '../pages/auth pages/teacher_signup_page.dart';
import '../pages/auth pages/student_signup_page.dart';
import '../pages/student pages/student_page.dart';
import '../pages/teacher pages/teacher_page.dart';

// AppRoutes defines named routes for all pages in the project
class AppRoutes {
  // Route names for navigation
  static const String landing = '/';
  static const String login = '/login';
  static const String teacherSignup = '/teacher-signup';
  static const String studentSignup = '/student-signup';
  static const String studentDashboard = '/studentDashboard';
  static const String teacherDashboard = '/teacherDashboard';
  static const String adminDashboard = '/adminDashboard';

  // Map of route names to their corresponding widget builders
  static final Map<String, WidgetBuilder> routes = {
    login: (context) => LoginPage(),
    teacherSignup: (context) => TeacherSignUpPage(),
    studentSignup: (context) => StudentSignUpPage(),
    studentDashboard: (context) => StudentPage(),
    teacherDashboard: (context) => TeacherPage(),
    adminDashboard: (context) => AdminPage(),
  };
}
