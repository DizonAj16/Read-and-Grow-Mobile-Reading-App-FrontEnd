import 'package:deped_reading_app_laravel/api/user_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:convert';
import '../../widgets/appbar/theme_toggle_button.dart';
import 'auth buttons widgets/signup_button.dart';
import 'form fields widgets/password_text_field.dart';
import '../../widgets/navigation/page_transition.dart';
import 'login_page.dart';

class StudentSignUpPage extends StatefulWidget {
  const StudentSignUpPage({super.key});

  @override
  State<StudentSignUpPage> createState() => _StudentSignUpPageState();
}

class _StudentSignUpPageState extends State<StudentSignUpPage> {
  final TextEditingController studentNameController = TextEditingController();
  final TextEditingController studentLRNController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();
  final TextEditingController studentUsernameController =
      TextEditingController();
  final TextEditingController studentPasswordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  final List<String> _grades = ['1', '2', '3', '4', '5'];

  @override
  void dispose() {
    // Disposes all controllers to free resources when the widget is removed from the widget tree.
    studentNameController.dispose();
    studentLRNController.dispose();
    sectionController.dispose();
    gradeController.dispose();
    studentUsernameController.dispose();
    studentPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handles the student registration process:
  /// - Validates the form.
  /// - Shows a loading dialog.
  /// - Calls the API for registration.
  /// - Handles the response and shows appropriate dialogs for success or failure.
  Future<void> registerStudent() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autoValidate = true;
      });
      return;
    }

    setState(() {});

    _showLoadingDialog("Creating your account...");

    try {
      final response = await UserService.registerStudent({
        'student_username': studentUsernameController.text,
        'student_password': studentPasswordController.text,
        'student_password_confirmation': confirmPasswordController.text,
        'student_name': studentNameController.text,
        'student_lrn': studentLRNController.text,
        'student_grade': gradeController.text,
        'student_section': sectionController.text,
      });

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        _handleErrorDialog(
          title: 'Server Error',
          message:
              response.statusCode >= 500
                  ? 'A server error occurred. Please try again later.'
                  : 'Server error: Invalid response format.',
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
                  message,
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
                  Icon(Icons.error, color: Colors.red, size: 30),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
      );
    }
  }

  /// Builds the header section with avatar and title for the student sign up page.
  Widget _buildHeader(BuildContext context) => Column(
    children: [
      const SizedBox(height: 50),
      CircleAvatar(
        radius: 80,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Image.asset('assets/icons/graduating-student.png', width: 115),
      ),
      const SizedBox(height: 5),
      Text(
        "Student Sign Up",
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
                controller: studentNameController,
                label: "Full Name",
                icon: Icons.person,
                hintText: "e.g. Maria Santos",
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Full Name is required'
                            : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: studentLRNController,
                label: "LRN",
                icon: Icons.confirmation_number,
                hintText: "e.g. 123456789012",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'LRN is required';
                  }
                  if (!RegExp(r'^\d{12}$').hasMatch(value.trim())) {
                    return 'LRN must be exactly 12 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value:
                    gradeController.text.isNotEmpty
                        ? gradeController.text
                        : null,
                items:
                    _grades.map((grade) {
                      return DropdownMenuItem(
                        value: grade,
                        child: Text("Grade $grade"),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    gradeController.text = value ?? '';
                  });
                },
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Grade is required'
                            : null,
                decoration: InputDecoration(
                  labelText: "Grade",
                  hintText: "Select your grade",
                  hintStyle: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(52, 158, 158, 158),
                  prefixIcon: Icon(
                    Icons.grade,
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
              ),

              const SizedBox(height: 20),
              _buildTextField(
                controller: sectionController,
                label: "Section",
                icon: Icons.group,
                hintText: "e.g. Section A",
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Section is required'
                            : null,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: studentUsernameController,
                label: "Username",
                icon: Icons.account_circle,
                hintText: "e.g. mariasantos",
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'Username is required'
                            : null,
              ),
              const SizedBox(height: 20),
              PasswordTextField(
                labelText: "Password",
                controller: studentPasswordController,
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
                  if (value != studentPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SignUpButton(text: "Sign Up", onPressed: registerStudent),
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

  /// Main build method for the student sign up page.
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
