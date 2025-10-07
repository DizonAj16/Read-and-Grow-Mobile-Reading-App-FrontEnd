import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      setState(() => _autoValidate = true);
      return;
    }

    _showLoadingDialog("Creating your account...");

    try {
      final supabase = Supabase.instance.client;

      final authResponse = await supabase.auth.signUp(
        email: "${studentUsernameController.text}@gmail.com",
        password: studentPasswordController.text,
      );

      if (authResponse.user == null) {
        Navigator.of(context).pop();
        _handleErrorDialog(
          title: "Registration Failed",
          message: "Could not create account. Please try again.",
        );
        return;
      }

      final user = authResponse.user;
      final userId = user!.id;

      await supabase.from('users').insert({
        'id': userId,
        'username': studentUsernameController.text,
        'password': studentPasswordController.text,
        'role': 'student',
      });

      await supabase.from('students').insert({
        'user_id': userId,
        'username': studentUsernameController.text,
        'student_name': studentNameController.text,
        'student_lrn': studentLRNController.text,
        'student_grade': gradeController.text,
        'student_section': sectionController.text,
      });


      if (mounted) {
        Navigator.of(context).pop();
        await _showSuccessAndProceedDialogs("Registration successful!");
      }
    } catch (e) {
      Navigator.of(context).pop();
      _handleErrorDialog(
        title: "Error",
        message: "Failed to sign up: $e",
      );
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                message,
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

  Future<void> _showSuccessAndProceedDialogs(String message) async {
    await _showSuccessDialog(message);
    if (mounted) {
      Navigator.of(context).pushReplacement(PageTransition(page: LoginPage()));
    }
  }

  Future<void> _showSuccessDialog(String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
    if (mounted) Navigator.of(context).pop();
  }

  void _handleErrorDialog({required String title, required String message}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 30),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
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

  Widget _buildHeader(BuildContext context) => Column(
    children: [
      const SizedBox(height: 50),
      CircleAvatar(
        radius: 80,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Image.asset('assets/icons/graduating-student.png',
            width: 115),
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
          _buildTextField(
            controller: studentNameController,
            label: "Full Name",
            icon: Icons.person,
            hintText: "e.g. Maria Santos",
            validator: (value) =>
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
            gradeController.text.isNotEmpty ? gradeController.text : null,
            items: _grades
                .map((grade) =>
                DropdownMenuItem(value: grade, child: Text("Grade $grade")))
                .toList(),
            onChanged: (value) {
              setState(() => gradeController.text = value ?? '');
            },
            validator: (value) =>
            value == null || value.isEmpty ? 'Grade is required' : null,
            decoration: _dropdownDecoration(context),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: sectionController,
            label: "Section",
            icon: Icons.group,
            hintText: "e.g. Section A",
            validator: (value) =>
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
            validator: (value) =>
            value == null || value.trim().isEmpty
                ? 'Username is required'
                : null,
          ),
          const SizedBox(height: 20),
          PasswordTextField(
            labelText: "Password",
            controller: studentPasswordController,
            hintText: "At least 6 characters",
            validator: (value) =>
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
                  Navigator.of(context)
                      .push(PageTransition(page: LoginPage()));
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
    ),
  );

  InputDecoration _dropdownDecoration(BuildContext context) => InputDecoration(
    labelText: "Grade",
    hintText: "Select your grade",
    hintStyle: TextStyle(
      fontStyle: FontStyle.italic,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    ),
    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
    filled: true,
    fillColor: const Color.fromARGB(52, 158, 158, 158),
    prefixIcon: Icon(Icons.grade,
        color: Theme.of(context).colorScheme.onSurface),
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
  );

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
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
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
