import 'dart:convert';
import 'package:deped_reading_app_laravel/api/user_service.dart';
import 'package:deped_reading_app_laravel/pages/admin%20pages/admin%20dashboard/dialogs%20and%20snackbars/error_dialog.dart';
import 'package:deped_reading_app_laravel/pages/admin%20pages/admin%20dashboard/dialogs%20and%20snackbars/loading_dialog.dart';
import 'package:deped_reading_app_laravel/pages/admin%20pages/admin%20dashboard/registration%20forms/student_form.dart';
import 'package:deped_reading_app_laravel/pages/admin%20pages/admin%20dashboard/dialogs%20and%20snackbars/success_dialog.dart';
import 'package:deped_reading_app_laravel/pages/admin%20pages/admin%20dashboard/dialogs%20and%20snackbars/success_snackbar.dart';
import 'package:deped_reading_app_laravel/pages/admin%20pages/admin%20dashboard/registration%20forms/teacher_form.dart';
import 'package:flutter/material.dart';

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
  final TextEditingController confirmTeacherPasswordController =
      TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  // Controllers for student form
  final TextEditingController studentNameController = TextEditingController();
  final TextEditingController studentLrnController = TextEditingController();
  final TextEditingController studentSectionController =
      TextEditingController();
  final TextEditingController studentGradeController = TextEditingController();
  final TextEditingController studentEmailController = TextEditingController();
  final TextEditingController studentPasswordController =
      TextEditingController();
  final TextEditingController confirmStudentPasswordController =
      TextEditingController();
  final TextEditingController studentUsernameController =
      TextEditingController();

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
      final response = await UserService.registerTeacher({
        'teacher_username': usernameController.text,
        'teacher_password': passwordController.text,
        'teacher_password_confirmation': confirmTeacherPasswordController.text,
        'teacher_name': nameController.text,
        'teacher_email': emailController.text,
        'teacher_position': positionController.text,
      });

      if (response != null) {
        // ✅ Supabase returned inserted row
        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pop(); // Close loading dialog
        await _showSuccessDialog("Teacher account created!");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        Navigator.of(context).pop(); // Close form/dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SuccessSnackBar(message: "Teacher created successfully!"),
        );
      } else {
        // Insert failed or no data returned
        _handleErrorDialog(
          title: 'Registration Failed',
          message: 'Teacher registration failed. Please try again.',
        );
      }
    } catch (e) {
      _handleErrorDialog(
        title: 'Error',
        message: 'An error occurred: $e',
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
      final response = await UserService.registerStudent({
        'student_username': studentUsernameController.text,
        'student_password': studentPasswordController.text,
        'student_password_confirmation': confirmStudentPasswordController.text,
        'student_name': studentNameController.text,
        'student_lrn': studentLrnController.text,
        'student_grade': studentGradeController.text,
        'student_section': studentSectionController.text,
      });

      if (response != null) {
        // ✅ Success, Supabase returned inserted row
        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pop(); // Close loading dialog
        await _showSuccessDialog("Student account created!");
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        Navigator.of(context).pop(); // Close form/dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SuccessSnackBar(message: "Student created successfully!"),
        );
      } else {
        // Insert failed or no data returned
        _handleErrorDialog(
          title: 'Registration Failed',
          message: 'Student registration failed. Please try again.',
        );
      }
    } catch (e) {
      _handleErrorDialog(
        title: 'Error',
        message: 'An error occurred: $e',
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          // Use asset icon depending on selectedTab
          if (selectedTab == 0)
            Image.asset('assets/icons/teacher.png', width: 60, height: 60)
          else
            Image.asset(
              'assets/icons/graduating-student.png',
              width: 60,
              height: 60,
            ),
          SizedBox(height: 8),
          Text(
            selectedTab == 0
                ? "Create Teacher Account"
                : "Create Student Account",
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
                  color:
                      selectedTab == 0
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
                  color:
                      selectedTab == 1
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
          autovalidateMode:
              _autoValidate
                  ? AutovalidateMode.always
                  : AutovalidateMode.disabled,
          child:
              selectedTab == 0
                  ? TeacherForm(
                    nameController: nameController,
                    positionController: positionController,
                    usernameController: usernameController,
                    emailController: emailController,
                    passwordController: passwordController,
                    confirmPasswordController: confirmTeacherPasswordController,
                    passwordVisible: _teacherPasswordVisible,
                    confirmPasswordVisible: _teacherConfirmPasswordVisible,
                    onPasswordVisibilityChanged:
                        (v) => setState(() => _teacherPasswordVisible = v),
                    onConfirmPasswordVisibilityChanged:
                        (v) =>
                            setState(() => _teacherConfirmPasswordVisible = v),
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
                    onPasswordVisibilityChanged:
                        (v) => setState(() => _studentPasswordVisible = v),
                    onConfirmPasswordVisibilityChanged:
                        (v) =>
                            setState(() => _studentConfirmPasswordVisible = v),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed:
              _isLoading
                  ? null
                  : () {
                    if (selectedTab == 0) {
                      _addTeacher();
                    } else {
                      _addStudent();
                    }
                  },
          child: Text("Create", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
