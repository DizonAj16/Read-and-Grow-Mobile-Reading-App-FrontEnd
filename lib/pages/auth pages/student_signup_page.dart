import 'package:flutter/material.dart';
import 'dart:convert';
import '../../widgets/appbar/theme_toggle_button.dart';
import '../../widgets/buttons/signup_button.dart';
import '../../widgets/form/password_text_field.dart';
import '../../widgets/navigation/page_transition.dart';
import '../../api/api_service.dart';
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
  final TextEditingController studentUsernameController = TextEditingController();
  final TextEditingController studentPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  bool _isLoading = false;

  @override
  void dispose() {
    studentNameController.dispose();
    studentLRNController.dispose();
    sectionController.dispose();
    gradeController.dispose();
    studentUsernameController.dispose();
    studentPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerStudent() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autoValidate = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _showLoadingDialog("Creating your account...");

    try {
      final response = await ApiService.registerStudent({
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
          message: response.statusCode >= 500
              ? 'A server error occurred. Please try again later.'
              : 'Server error: Invalid response format.',
        );
        return;
      }

      if (response.statusCode == 201) {
        await Future.delayed(const Duration(seconds: 3));
        Navigator.of(context).pop(); // Close loading dialog
        await _showSuccessAndProceedDialogs(data['message'] ?? 'Registration successful!');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
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

  Future<void> _showSuccessAndProceedDialogs(String message) async {
    await _showSuccessDialog(message);
    await _showProceedingDialog();
    Navigator.of(context).pushReplacement(PageTransition(page: LoginPage()));
  }

  Future<void> _showSuccessDialog(String message) async {
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
        content: Text(message),
      ),
    );
    await Future.delayed(const Duration(seconds: 3));
    Navigator.of(context).pop(); // Close success dialog
  }

  Future<void> _showProceedingDialog() async {
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
                "Proceeding to login...",
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
    await Future.delayed(const Duration(seconds: 2));
    Navigator.of(context).pop(); // Close proceeding dialog
  }

  void _handleErrorDialog({required String title, required String message}) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(); // Close loading dialog
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
  }

  Widget _buildHeader(BuildContext context) => Column(
        children: [
          const SizedBox(height: 50),
          CircleAvatar(
            radius: 80,
            backgroundColor: Theme.of(context).colorScheme.onPrimary,
            child: Icon(
              Icons.person_add,
              size: 90,
              color: Theme.of(context).colorScheme.primary,
            ),
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

  Widget _buildSignUpForm(BuildContext context) => Form(
        key: _formKey,
        autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
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
                    validator: (value) => value == null || value.trim().isEmpty ? 'Full Name is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: studentLRNController,
                    label: "LRN",
                    icon: Icons.confirmation_number,
                    validator: (value) => value == null || value.trim().isEmpty ? 'LRN is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: gradeController,
                    label: "Grade",
                    icon: Icons.grade,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Grade is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: sectionController,
                    label: "Section",
                    icon: Icons.group,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Section is required' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: studentUsernameController,
                    label: "Username",
                    icon: Icons.account_circle,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Username is required' : null,
                  ),
                  const SizedBox(height: 20),
                  PasswordTextField(
                    labelText: "Password",
                    controller: studentPasswordController,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Password is required' : null,
                  ),
                  const SizedBox(height: 20),
                  PasswordTextField(
                    labelText: "Confirm Password",
                    controller: confirmPasswordController,
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
                          Navigator.of(context).push(PageTransition(page: LoginPage()));
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
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
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: validator,
    );
  }

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
