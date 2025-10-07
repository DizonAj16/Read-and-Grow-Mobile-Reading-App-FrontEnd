import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    teacherNameController.dispose();
    teacherPositionController.dispose();
    teacherEmailController.dispose();
    teacherUsernameController.dispose();
    teacherPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerTeacher() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    _showLoadingDialog("Creating your account...");

    try {
      final supabase = Supabase.instance.client;

      final authResponse = await supabase.auth.signUp(
        email: teacherEmailController.text.trim(),
        password: teacherPasswordController.text.trim(),
        data: {
          "username": teacherUsernameController.text.trim(),
          "name": teacherNameController.text.trim(),
          "position": teacherPositionController.text.trim(),
        },
      );

      if (authResponse.user == null) {
        Navigator.of(context).pop();
        _handleErrorDialog(
          title: "Registration Failed",
          message: "Unable to create account. Please try again.",
        );
        return;
      }


      final user = authResponse.user;
      final userId = user!.id;
      await supabase.from('users').insert({
        'id':  userId,
        'username': teacherUsernameController.text,
        'password': teacherPasswordController.text,
        'role': 'teacher',
      });


      await supabase.from('teachers').insert({
        'user_id': authResponse.user!.id,
        'teacher_name': teacherNameController.text.trim(),
        'username': teacherUsernameController.text.trim(),
        'teacher_email': teacherEmailController.text.trim(),
        'teacher_position': teacherPositionController.text.trim(),
      });


      Navigator.of(context).pop();
      await _showSuccessAndProceedDialogs("Registration successful!");
    } catch (e) {
      Navigator.of(context).pop();
      _handleErrorDialog(title: "Error", message: e.toString());
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
    Navigator.of(context).pushReplacement(PageTransition(page: LoginPage()));
  }

  Future<void> _showSuccessDialog(String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 35),
            const SizedBox(width: 8),
            const Text('Success'),
          ],
        ),
        content: Text(message),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    Navigator.of(context).pop();
  }

  void _handleErrorDialog({required String title, required String message}) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 35),
              const SizedBox(width: 8),
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

  Widget _buildSignUpForm(BuildContext context) => Form(
    key: _formKey,
    autovalidateMode:
    _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius:
        const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _buildTextField(
            controller: teacherNameController,
            label: "Full Name",
            icon: Icons.person,
            hintText: "e.g. Juan Dela Cruz",
            validator: (value) =>
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
            validator: (value) =>
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
            validator: (value) =>
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
        prefixIcon:
        Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        filled: true,
        fillColor: const Color.fromARGB(52, 158, 158, 158),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
        iconTheme:
        IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        actions: [
          ThemeToggleButton(
            iconColor: Theme.of(context).colorScheme.onPrimary,
          ),
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
