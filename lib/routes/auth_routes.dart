import 'package:flutter/material.dart';
import '../pages/auth pages/landing_page.dart';
import '../pages/auth pages/login_page.dart';
import '../pages/auth pages/sign_up_page.dart';

class AuthRoutes {
  static const String landing = '/';
  static const String login = '/login';
  static const String signup = '/signup';

  static final Map<String, WidgetBuilder> routes = {
    landing: (context) => LandingPage(),
    login: (context) => LoginPage(),
    signup: (context) => SignUpPage(),
  };
}
