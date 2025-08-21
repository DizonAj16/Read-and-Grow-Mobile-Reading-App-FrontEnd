import 'package:deped_reading_app_laravel/api/auth_service.dart';
import 'package:deped_reading_app_laravel/pages/admin%20pages/admin_page.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student_page.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/appbar/theme_toggle_button.dart';
import 'auth buttons widgets/login_button.dart';
import 'form fields widgets/password_text_field.dart';
import '../../widgets/navigation/page_transition.dart';
import '../auth pages/student_signup_page.dart';
import '../auth pages/teacher_signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  /// Handles the login process:
  /// - Validates the form.
  /// - Shows a loading dialog.
  /// - Calls the API for login.
  /// - Handles response, stores token/role, and navigates to dashboard.
  /// - Shows appropriate dialogs for errors or success.
  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autoValidate = true;
      });
      return;
    }

    _showLoadingDialog("Logging in...");

    try {
      final response = await AuthService.login({
        'login': usernameController.text,
        'password': passwordController.text,
      });

      final decoded = jsonDecode(response.body);
      final data = decoded['data'] ?? {};
      await Future.delayed(const Duration(seconds: 2));
      Navigator.of(context).pop();

      if (response.statusCode == 200 && data.isNotEmpty) {
        // Store auth data
        final prefs = await SharedPreferences.getInstance();
        final token = data['token'] ?? '';
        await prefs.setString('token', token);

        final role = data['user']?['role']?.toString() ?? '';
        await prefs.setString('role', role);

        if (data['user']?['id'] != null) {
          await prefs.setString('user_id', data['user']['id'].toString());
        }

        // 🚫 Temporarily disable profile fetching
        /*
      _showLoadingDialog("Loading profile...");
      try {
        final profile = await AuthService.getAuthProfile();
        Navigator.of(context).pop();

        final profileData = profile;
        if (role == 'teacher') {
          final teacherData = profileData['teacher'] ?? profileData;
          print("📌 Teacher Profile Data: $teacherData"); // debug log
          await UserService.storeTeacherDetails(teacherData);
        } else if (role == 'student') {
          final studentData = profileData['student'] ?? profileData;
          print("📌 Student Profile Data: $studentData"); // debug log
          await UserService.storeStudentDetails(studentData);
        }

        await _showSuccessAndProceedDialogs(role);
      } catch (e) {
        Navigator.of(context).pop();
        _showErrorDialog(
          title: 'Profile Error',
          message: 'Logged in but failed to load profile. Please try again.',
        );
        debugPrint('Profile error: $e');
      }
      */

        // ✅ Directly go to success flow without profile
        await _showSuccessAndProceedDialogs(role);
      } else {
        final errorMessage = decoded['message'] ?? 'Login failed';
        _showErrorDialog(title: 'Login Failed', message: errorMessage);
      }
    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog(
        title: 'Error',
        message: 'An error occurred. Please try again.',
      );
      debugPrint('Login error: $e');
    }
  }

  /// Displays a loading dialog with a custom message.
  /// Used during async operations like login.
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder:
          (context) => Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animation/loading_rainbow.json',
                    height: 90,
                    width: 90,
                  ),
                  Text(
                    'Logging in...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// Shows a success dialog, then a proceeding dialog, then navigates to dashboard.
  /// Used after a successful login.
  Future<void> _showSuccessAndProceedDialogs(String? role) async {
    await _showSuccessDialog();
    _navigateToDashboard(role);
  }

  /// Shows a success dialog for login.
  /// Waits for a few seconds before closing.
  /// Shows a success dialog for login.
  /// Waits for a few seconds before closing.
  Future<void> _showSuccessDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Lottie.asset('assets/animation/success.json'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Login Successful!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
    );

    await Future.delayed(const Duration(milliseconds: 2100));
    Navigator.of(context).pop(); // Close success dialog
  }

  /// Navigates to the appropriate dashboard page based on user role.
  void _navigateToDashboard(String? role) {
    debugPrint("Navigating to dashboard for role: $role");

    if (role == 'student') {
      Navigator.of(context).pushAndRemoveUntil(
        PageTransition(page: StudentPage()),
        (route) => false,
      );
    } else if (role == 'teacher') {
      Navigator.of(context).pushAndRemoveUntil(
        PageTransition(page: TeacherPage()),
        (route) => false,
      );
    } else if (role == 'admin') {
      Navigator.of(
        context,
      ).pushAndRemoveUntil(PageTransition(page: AdminPage()), (route) => false);
    } else {
      debugPrint("No valid role detected.");
    }
  }

  /// Shows an error dialog with a title and message.
  /// Used for displaying validation, login, or storage errors.
  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 8.0,
            title: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  /// Builds the header section with avatar and title for the login page.
  Widget _buildHeader(BuildContext context) => Column(
    children: [
      const SizedBox(height: 50),
      // User avatar icon
      CircleAvatar(
        radius: 80,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Icon(
          Icons.person,
          size: 90,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 5),
      // Page title
      Text(
        "Login",
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 80),
    ],
  );

  /// Builds the login form with username/email, password, and action buttons.
  /// Includes validation and navigation to sign up pages.
  Widget _buildLoginForm(BuildContext context) => Form(
    key: _formKey,
    autovalidateMode:
        _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          // Username input field
          TextFormField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: "Username/Email",
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              filled: true,
              fillColor: const Color.fromARGB(52, 158, 158, 158),
              prefixIcon: Icon(
                Icons.account_circle,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              errorStyle: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          // Password input field
          PasswordTextField(
            labelText: "Password",
            controller: passwordController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Forgot Password?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          // Login button
          LoginButton(text: "Login", onPressed: login),
          // Add sign up as student and teacher buttons
          const SizedBox(height: 20),
          Divider(height: 10),
          const SizedBox(height: 5),
          Text(
            "or",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 20),
              elevation: 4,
            ),
            icon: Image.asset(
              'assets/icons/graduating-student.png', // for student
              width: 30,
              height: 30,
            ),
            label: const Text(
              "Sign up as Student",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).push(PageTransition(page: StudentSignUpPage()));
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 20),
              elevation: 4,
            ),
            icon: Image.asset(
              'assets/icons/teacher.png', // for teacher
              width: 30,
              height: 30,
            ),
            label: const Text(
              "Sign up as Teacher",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).push(PageTransition(page: TeacherSignUpPage()));
            },
          ),
        ],
      ),
    ),
  );

  /// Builds the background with an image and a gradient overlay.
  Widget _buildBackground(BuildContext context) => Stack(
    children: [
      // Background image with color filter
      ColorFiltered(
        colorFilter: ColorFilter.mode(
          Theme.of(context).colorScheme.primary.withOpacity(0.7),
          BlendMode.softLight,
        ),
        child: Opacity(
          opacity: 0.25,
          child: Image.asset(
            'assets/background/480681008_1020230633459316_6070422237958140538_n.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
      // Gradient overlay
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    ],
  );

  /// Main build method for the login page.
  /// Assembles the app bar, background, header, and login form.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        actions: [
          // Theme toggle button in the app bar
          ThemeToggleButton(iconColor: Theme.of(context).colorScheme.onPrimary),
        ],
      ),
      body: Stack(
        children: [
          // Page background
          _buildBackground(context),
          // Scrollable content with header and login form
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildHeader(context),
                    // Expands login form to fill remaining space
                    Expanded(child: _buildLoginForm(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
