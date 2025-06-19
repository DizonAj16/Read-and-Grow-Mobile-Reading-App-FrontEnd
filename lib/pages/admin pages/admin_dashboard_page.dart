import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:flutter/material.dart';
import 'admin_view_students_page.dart';
import 'admin_view_teachers_page.dart';
import 'dart:convert';

/// Admin dashboard page with options to view teachers/students and create accounts.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            // Button to view the list of teachers
            ElevatedButton.icon(
              icon: Image.asset(
                'assets/icons/teacher.png',
                width: 40,
                height: 40,
              ),
              label: Text(
                "View Teacher List",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AdminViewTeachersPage(),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            // Button to view the list of students
            ElevatedButton.icon(
              icon: Image.asset(
                'assets/icons/graduating-student.png',
                width: 40,
                height: 40,
              ),
              label: Text(
                "View Student List",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AdminViewStudentsPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      // Floating action button to open the create teacher or student dialog
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const CreateAccountDialog(),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Colors.white),
        shape: CircleBorder(),
        tooltip: "Create Teacher or Student Account",
      ),
    );
  }
}

/// Dialog for creating teacher or student accounts.
class CreateAccountDialog extends StatefulWidget {
  const CreateAccountDialog({super.key});

  @override
  State<CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<CreateAccountDialog> {
  int selectedTab = 0; // 0 = Teacher, 1 = Student

  // Controllers for teacher form
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmTeacherPasswordController = TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  // Controllers for student form
  final TextEditingController studentNameController = TextEditingController();
  final TextEditingController studentLrnController = TextEditingController();
  final TextEditingController studentSectionController = TextEditingController();
  final TextEditingController studentGradeController = TextEditingController();
  final TextEditingController studentEmailController = TextEditingController();
  final TextEditingController studentPasswordController = TextEditingController();
  final TextEditingController confirmStudentPasswordController = TextEditingController();
  final TextEditingController studentUsernameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  bool _isLoading = false;

  // Password visibility toggles
  bool _teacherPasswordVisible = false;
  bool _teacherConfirmPasswordVisible = false;
  bool _studentPasswordVisible = false;
  bool _studentConfirmPasswordVisible = false;

  @override
  void dispose() {
    // Dispose all controllers
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmTeacherPasswordController.dispose();
    positionController.dispose();
    usernameController.dispose();
    studentNameController.dispose();
    studentLrnController.dispose();
    studentSectionController.dispose();
    studentGradeController.dispose();
    studentEmailController.dispose();
    studentPasswordController.dispose();
    confirmStudentPasswordController.dispose();
    studentUsernameController.dispose();
    super.dispose();
  }

  /// Show a loading dialog with a custom message.
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  /// Show a success dialog and auto-close after a short delay.
  Future<void> _showSuccessDialog(String message) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(message: message),
    );
    await Future.delayed(const Duration(seconds: 1));
    Navigator.of(context).pop(); // Close success dialog
  }

  /// Show an error dialog with a custom title and message.
  void _handleErrorDialog({required String title, required String message}) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(); // Close loading dialog
      showDialog(
        context: context,
        builder: (context) => ErrorDialog(title: title, message: message),
      );
    }
  }

  /// Register a new teacher using the API.
  Future<void> _addTeacher() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autoValidate = true;
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    _showLoadingDialog("Creating teacher account...");
    try {
      final response = await ApiService.registerTeacher({
        'teacher_username': usernameController.text,
        'teacher_password': passwordController.text,
        'teacher_password_confirmation': confirmTeacherPasswordController.text,
        'teacher_name': nameController.text,
        'teacher_email': emailController.text,
        'teacher_position': positionController.text,
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
        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pop(); // Close loading dialog
        await _showSuccessDialog(data['message'] ?? 'Teacher account created!');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SuccessSnackBar(message: "Teacher created successfully!"),
        );
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

  /// Register a new student using the API.
  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autoValidate = true;
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    _showLoadingDialog("Creating student account...");
    try {
      final response = await ApiService.registerStudent({
        'student_username': studentUsernameController.text,
        'student_password': studentPasswordController.text,
        'student_password_confirmation': confirmStudentPasswordController.text,
        'student_name': studentNameController.text,
        'student_lrn': studentLrnController.text,
        'student_grade': studentGradeController.text,
        'student_section': studentSectionController.text,
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
        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pop(); // Close loading dialog
        await _showSuccessDialog(data['message'] ?? 'Student account created!');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SuccessSnackBar(message: "Student created successfully!"),
        );
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          // Use asset icon depending on selectedTab
          if (selectedTab == 0)
            Image.asset(
              'assets/icons/teacher.png',
              width: 60,
              height: 60,
            )
          else
            Image.asset(
              'assets/icons/graduating-student.png',
              width: 60,
              height: 60,
            ),
          SizedBox(height: 8),
          Text(
            selectedTab == 0 ? "Create Teacher Account" : "Create Student Account",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          Divider(thickness: 1, color: Colors.grey.shade300),
          // Toggle between Teacher and Student account creation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text("Teacher"),
                selected: selectedTab == 0,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() => selectedTab = 0);
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: selectedTab == 0
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12),
              ChoiceChip(
                label: Text("Student"),
                selected: selectedTab == 1,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() => selectedTab = 1);
                },
                selectedColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: selectedTab == 1
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
          child: selectedTab == 0
              ? TeacherForm(
                  nameController: nameController,
                  positionController: positionController,
                  usernameController: usernameController,
                  emailController: emailController,
                  passwordController: passwordController,
                  confirmPasswordController: confirmTeacherPasswordController,
                  passwordVisible: _teacherPasswordVisible,
                  confirmPasswordVisible: _teacherConfirmPasswordVisible,
                  onPasswordVisibilityChanged: (v) => setState(() => _teacherPasswordVisible = v),
                  onConfirmPasswordVisibilityChanged: (v) => setState(() => _teacherConfirmPasswordVisible = v),
                )
              : StudentForm(
                  nameController: studentNameController,
                  lrnController: studentLrnController,
                  gradeController: studentGradeController,
                  sectionController: studentSectionController,
                  usernameController: studentUsernameController,
                  passwordController: studentPasswordController,
                  confirmPasswordController: confirmStudentPasswordController,
                  passwordVisible: _studentPasswordVisible,
                  confirmPasswordVisible: _studentConfirmPasswordVisible,
                  onPasswordVisibilityChanged: (v) => setState(() => _studentPasswordVisible = v),
                  onConfirmPasswordVisibilityChanged: (v) => setState(() => _studentConfirmPasswordVisible = v),
                ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isLoading
              ? null
              : () {
                  if (selectedTab == 0) {
                    _addTeacher();
                  } else {
                    _addStudent();
                  }
                },
          child: Text(
            "Create",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Modular teacher form widget.
class TeacherForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController positionController;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool passwordVisible;
  final bool confirmPasswordVisible;
  final ValueChanged<bool> onPasswordVisibilityChanged;
  final ValueChanged<bool> onConfirmPasswordVisibilityChanged;

  const TeacherForm({
    super.key,
    required this.nameController,
    required this.positionController,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.onPasswordVisibilityChanged,
    required this.onConfirmPasswordVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: "Teacher Name",
            prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: positionController,
          decoration: InputDecoration(
            labelText: "Position",
            prefixIcon: Icon(Icons.work, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Position is required' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: usernameController,
          decoration: InputDecoration(
            labelText: "Username",
            prefixIcon: Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Username is required' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: "Email",
            prefixIcon: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Email is required';
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) return 'Enter a valid email';
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          obscureText: !passwordVisible,
          decoration: InputDecoration(
            labelText: "Password",
            prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => onPasswordVisibilityChanged(!passwordVisible),
            ),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Password is required' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: !confirmPasswordVisible,
          decoration: InputDecoration(
            labelText: "Confirm Password",
            prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => onConfirmPasswordVisibilityChanged(!confirmPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Confirm Password is required';
            if (value != passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }
}

/// Modular student form widget.
class StudentForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController lrnController;
  final TextEditingController gradeController;
  final TextEditingController sectionController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool passwordVisible;
  final bool confirmPasswordVisible;
  final ValueChanged<bool> onPasswordVisibilityChanged;
  final ValueChanged<bool> onConfirmPasswordVisibilityChanged;

  const StudentForm({
    super.key,
    required this.nameController,
    required this.lrnController,
    required this.gradeController,
    required this.sectionController,
    required this.usernameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.passwordVisible,
    required this.confirmPasswordVisible,
    required this.onPasswordVisibilityChanged,
    required this.onConfirmPasswordVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: "Student Name",
            prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: lrnController,
          decoration: InputDecoration(
            labelText: "LRN",
            prefixIcon: Icon(Icons.confirmation_number, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'LRN is required' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: gradeController,
          decoration: InputDecoration(
            labelText: "Grade",
            prefixIcon: Icon(Icons.grade, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Grade is required' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: sectionController,
          decoration: InputDecoration(
            labelText: "Section",
            prefixIcon: Icon(Icons.group, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Section is required' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: usernameController,
          decoration: InputDecoration(
            labelText: "Username",
            prefixIcon: Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Username is required' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          obscureText: !passwordVisible,
          decoration: InputDecoration(
            labelText: "Password",
            prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => onPasswordVisibilityChanged(!passwordVisible),
            ),
          ),
          validator: (value) => value == null || value.trim().isEmpty ? 'Password is required' : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: !confirmPasswordVisible,
          decoration: InputDecoration(
            labelText: "Confirm Password",
            prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => onConfirmPasswordVisibilityChanged(!confirmPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'Confirm Password is required';
            if (value != passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }
}

/// Loading dialog widget.
class LoadingDialog extends StatelessWidget {
  final String message;
  const LoadingDialog({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return Dialog(
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
    );
  }
}

/// Success dialog widget.
class SuccessDialog extends StatelessWidget {
  final String message;
  const SuccessDialog({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 35),
          SizedBox(width: 8),
          const Text('Success'),
        ],
      ),
      content: Text(message),
    );
  }
}

/// Error dialog widget.
class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  const ErrorDialog({super.key, required this.title, required this.message});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
    );
  }
}

/// Success snackbar widget.
class SuccessSnackBar extends SnackBar {
  SuccessSnackBar({required String message})
      : super(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(message),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          duration: Duration(seconds: 2),
        );
}

