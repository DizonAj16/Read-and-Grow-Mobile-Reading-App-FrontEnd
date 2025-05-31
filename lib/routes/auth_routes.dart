import 'package:flutter/material.dart';
import '../pages/auth pages/landing_page.dart';
import '../pages/auth pages/login_page.dart';
import '../pages/auth pages/sign_up_page.dart';

// AuthRoutes defines named routes for authentication-related pages
class AuthRoutes {
  // Route names for navigation
  static const String landing = '/';
  static const String login = '/login';
  static const String signup = '/signup';

  // Map of route names to their corresponding widget builders
  static final Map<String, WidgetBuilder> routes = {
    landing: (context) => LandingPage(),   // Landing page route
    login: (context) => LoginPage(),       // Login page route
    signup: (context) => SignUpPage(),     // Sign up page route
  };
}
