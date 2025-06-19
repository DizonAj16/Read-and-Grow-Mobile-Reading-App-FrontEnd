import 'package:deped_reading_app_laravel/pages/admin%20pages/admin_page.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student_page.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher_page.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/appbar/theme_toggle_button.dart';
import '../../widgets/buttons/login_button.dart';
import '../../widgets/form/password_text_field.dart';
import '../../api/api_service.dart';
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
      final response = await ApiService.login({
        'login': usernameController.text, // Changed from 'username' to 'login'
        'password': passwordController.text,
      });

      final data = jsonDecode(response.body);
      await Future.delayed(const Duration(seconds: 1));
      Navigator.of(context).pop(); // Close loading dialog

      // Defensive: Check if SharedPreferences is available before using
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']?.toString() ?? '');
        await prefs.setString('role', data['role']?.toString() ?? '');
      } catch (e) {
        _showErrorDialog(
          title: 'Error',
          message: 'Unable to access local storage. Please restart the app.',
        );
        return;
      }

      if (response.statusCode == 200) {
        await _showSuccessAndProceedDialogs(data['role']);
      } else if (response.statusCode == 422) {
        // Validation error
        String errorMsg = '';
        if (data['errors'] != null) {
          data['errors'].forEach((key, value) {
            errorMsg += '${value[0]}\n';
          });
        }
        _showErrorDialog(
          title: 'Validation Error',
          message: errorMsg.trim().isEmpty ? (data['message'] ?? 'Validation error') : errorMsg.trim(),
        );
      } else if (response.statusCode == 401) {
        _showErrorDialog(
          title: 'Login Failed',
          message: data['message'] ?? 'Incorrect password.',
        );
      } else if (response.statusCode == 404) {
        _showErrorDialog(
          title: 'User Not Found',
          message: data['message'] ?? 'User not found.',
        );
      } else {
        _showErrorDialog(
          title: 'Login Failed',
          message: data['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      _showErrorDialog(
        title: 'Error',
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Displays a loading dialog with a custom message.
  /// Used during async operations like login.
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
    await _showProceedingDialog(role);
    _navigateToDashboard(role);
  }

  /// Shows a success dialog for login.
  /// Waits for a few seconds before closing.
  Future<void> _showSuccessDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 35),
            SizedBox(width: 8),
            const Text('Success'),
          ],
        ),
        content: const Text('Login successful!'),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    Navigator.of(context).pop(); // Close success dialog
  }

  /// Shows a dialog indicating the user is being redirected to their dashboard.
  /// Waits for a few seconds before closing.
  Future<void> _showProceedingDialog(String? role) async {
    String dashboardText = '';
    if (role == 'student') {
      dashboardText = "Proceeding to Student Dashboard...";
    } else if (role == 'teacher') {
      dashboardText = "Proceeding to Teacher Dashboard...";
    } else if (role == 'admin') {
      dashboardText = "Proceeding to Admin Dashboard...";
    } else {
      dashboardText = "Proceeding...";
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                dashboardText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    Navigator.of(context).pop(); // Close proceeding dialog
  }

  /// Navigates to the appropriate dashboard page based on user role.
  void _navigateToDashboard(String? role) {
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
      Navigator.of(context).pushAndRemoveUntil(
        PageTransition(page: AdminPage()),
        (route) => false,
      );
    }
  }

  /// Shows an error dialog with a title and message.
  /// Used for displaying validation, login, or storage errors.
  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 35),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 80),
        ],
      );

  /// Builds the login form with username/email, password, and action buttons.
  /// Includes validation and navigation to sign up pages.
  Widget _buildLoginForm(BuildContext context) => Form(
        key: _formKey,
        autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
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
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  filled: true,
                  fillColor: const Color.fromARGB(52, 158, 158, 158),
                  prefixIcon: Icon(Icons.account_circle, color: Theme.of(context).colorScheme.onSurface),
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
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              // Login button
              LoginButton(
                text: "Login",
                onPressed: login,
              ),
              // Add sign up as student and teacher buttons
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(PageTransition(page: StudentSignUpPage()));
                    },
                    child: Text(
                      "Sign up as Student",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(PageTransition(page: TeacherSignUpPage()));
                    },
                    child: Text(
                      "Sign up as Teacher",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ],
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
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
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
