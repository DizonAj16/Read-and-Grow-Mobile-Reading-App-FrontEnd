import 'package:deped_reading_app_laravel/api/user_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import '../../widgets/appbar/theme_toggle_button.dart';
import 'auth buttons widgets/signup_button.dart';
import 'form fields widgets/password_text_field.dart';
import '../../widgets/navigation/page_transition.dart';
import 'login_page.dart';

class TeacherSignUpPage extends StatefulWidget {
  const TeacherSignUpPage({super.key});

  @override
  State<TeacherSignUpPage> createState() => _TeacherSignUpPageState();
}

class _TeacherSignUpPageState extends State<TeacherSignUpPage> {
  final TextEditingController teacherNameController = TextEditingController();
  final TextEditingController teacherPositionController =
      TextEditingController();
  final TextEditingController teacherEmailController = TextEditingController();
  final TextEditingController teacherUsernameController =
      TextEditingController();
  final TextEditingController teacherPasswordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  @override
  void dispose() {
    // Disposes all controllers to free resources when the widget is removed from the widget tree.
    teacherNameController.dispose();
    teacherPositionController.dispose();
    teacherEmailController.dispose();
    teacherUsernameController.dispose();
    teacherPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handles the teacher registration process:
  /// - Validates the form.
  /// - Shows a loading dialog.
  /// - Calls the API for registration.
  /// - Handles the response and shows appropriate dialogs for success or failure.
  Future<void> registerTeacher() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autoValidate = true;
      });
      return;
    }

    setState(() {});

    _showLoadingDialog("Creating your account...");

    try {
      final response = await UserService.registerTeacher({
        'teacher_username': teacherUsernameController.text,
        'teacher_password': teacherPasswordController.text,
        'teacher_password_confirmation': confirmPasswordController.text,
        'teacher_name': teacherNameController.text,
        'teacher_email': teacherEmailController.text,
        'teacher_position': teacherPositionController.text,
      });

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        _handleErrorDialog(
          title: 'Server Error',
          message: 'Server error: Invalid response format.',
        );
        return;
      }

      if (response.statusCode == 201) {
        await Future.delayed(const Duration(seconds: 2));
        Navigator.of(context).pop(); // Close loading dialog
        await _showSuccessAndProceedDialogs(
          data['message'] ?? 'Registration successful!',
        );
        if (mounted) {
          setState(() {});
        }
      } else {
        _handleErrorDialog(
          title: 'Registration Failed',
          message: data['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      _handleErrorDialog(
        title: 'Error',
        message: 'An error occurred. Please try again.',
      );
    }
  }

  /// Displays a loading dialog with a custom message.
  /// Used during async operations like registration.
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
                    'Signing in...',
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

  /// Shows a success dialog, then a proceeding dialog, then navigates to the login page.
  /// Used after a successful registration.
  Future<void> _showSuccessAndProceedDialogs(String message) async {
    await _showSuccessDialog(message);
    Navigator.of(context).pushReplacement(PageTransition(page: LoginPage()));
  }

  /// Shows a success dialog for registration.
  /// Waits for a few seconds before closing.
  Future<void> _showSuccessDialog(String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 35),
                SizedBox(width: 8),
                const Text('Success'),
              ],
            ),
            content: Text(message),
          ),
    );
    await Future.delayed(const Duration(seconds: 2));
    Navigator.of(context).pop(); // Close success dialog
  }

  /// Handles error dialogs:
  /// - Closes the loading dialog.
  /// - Shows an error dialog with a title and message.
  /// - Sets loading state to false.
  void _handleErrorDialog({required String title, required String message}) {
    if (mounted) {
      setState(() {});
      Navigator.of(context).pop(); // Close loading dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
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
  }

  /// Builds the header section with avatar and title for the teacher sign up page.
  Widget _buildHeader(BuildContext context) => Column(
    children: [
      const SizedBox(height: 50),
      CircleAvatar(
        radius: 80,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Image.asset('assets/icons/teacher.png', width: 115),
      ),
      const SizedBox(height: 5),
      Text(
        "Teacher Sign Up",
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 80),
    ],
  );

  /// Builds the sign up form with all required fields and validation.
  /// Includes navigation to the login page.
  Widget _buildSignUpForm(BuildContext context) => Form(
    key: _formKey,
    autovalidateMode:
        _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildTextField(
                controller: teacherNameController,
                label: "Full Name",
                icon: Icons.person,
                hintText: "e.g. Juan Dela Cruz",
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Full Name is required'
                            : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: teacherPositionController,
                label: "Position",
                icon: Icons.work,
                hintText: "e.g. English Teacher",
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Position is required'
                            : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: teacherUsernameController,
                label: "Username",
                icon: Icons.account_circle,
                hintText: "e.g. juandelacruz",
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Username is required'
                            : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: teacherEmailController,
                label: "Email",
                icon: Icons.email,
                hintText: "e.g. juan@email.com",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              PasswordTextField(
                labelText: "Password",
                controller: teacherPasswordController,
                hintText: "At least 6 characters",
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Password is required'
                            : null,
              ),
              const SizedBox(height: 20),
              PasswordTextField(
                labelText: "Confirm Password",
                controller: confirmPasswordController,
                hintText: "Re-enter your password",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Confirm Password is required';
                  }
                  if (value != teacherPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SignUpButton(text: "Sign Up", onPressed: registerTeacher),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).push(PageTransition(page: LoginPage()));
                    },
                    child: Text(
                      "Log In",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );

  /// Builds a reusable text field with icon, label, and validation.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        // <-- italicized
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        filled: true,
        fillColor: const Color.fromARGB(52, 158, 158, 158),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
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
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: validator,
    );
  }

  /// Builds the background with a gradient overlay.
  Widget _buildBackground(BuildContext context) => Container(
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
  );

  /// Main build method for the teacher sign up page.
  /// Assembles the app bar, background, header, and sign up form.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        actions: [
          ThemeToggleButton(iconColor: Theme.of(context).colorScheme.onPrimary),
        ],
      ),
      body: Stack(
        children: [
          _buildBackground(context),
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(child: _buildSignUpForm(context)),
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
