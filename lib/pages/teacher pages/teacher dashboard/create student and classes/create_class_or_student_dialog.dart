import 'dart:convert';
import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/api/user_service.dart';
import 'package:flutter/material.dart';
import 'create_dialog_utils.dart';
import 'class_form.dart';
import 'student_form.dart';

class CreateClassOrStudentDialog extends StatefulWidget {
  final VoidCallback? onStudentAdded;
  final VoidCallback? onClassAdded;

  const CreateClassOrStudentDialog({
    super.key,
    this.onStudentAdded,
    this.onClassAdded,
  });

  @override
  State<CreateClassOrStudentDialog> createState() =>
      _CreateClassOrStudentDialogState();
}

class _CreateClassOrStudentDialogState
    extends State<CreateClassOrStudentDialog> {
  int selectedTab = 0; // 0 = Class, 1 = Student
  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  bool _isLoading = false;
  bool _studentPasswordVisible = false;
  bool _studentConfirmPasswordVisible = false;
  int? _selectedGradeLevel;

  // Controllers
  final TextEditingController classNameController = TextEditingController();
  final TextEditingController classSectionController = TextEditingController();
  final TextEditingController gradeLevelController = TextEditingController();
  final TextEditingController schoolYearController = TextEditingController();
  final TextEditingController studentNameController = TextEditingController();
  final TextEditingController studentLrnController = TextEditingController();
  final TextEditingController studentSectionController =
      TextEditingController();
  final TextEditingController studentGradeController = TextEditingController();
  final TextEditingController studentUsernameController =
      TextEditingController();
  final TextEditingController studentPasswordController =
      TextEditingController();
  final TextEditingController confirmStudentPasswordController =
      TextEditingController();

  @override
  void dispose() {
    classNameController.dispose();
    classSectionController.dispose();
    studentNameController.dispose();
    studentLrnController.dispose();
    studentSectionController.dispose();
    studentGradeController.dispose();
    studentUsernameController.dispose();
    studentPasswordController.dispose();
    confirmStudentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    setState(() => _isLoading = true);
    DialogUtils.showLoadingDialog(context, "Creating student account...");

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

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        _handleError(
          title: 'Server Error',
          message:
              response.statusCode >= 500
                  ? 'A server error occurred. Please try again later.'
                  : 'Server error: Invalid response format.',
        );
        return;
      }

      if (response.statusCode == 201) {
        await _handleSuccess(data['message'] ?? 'Student account created!');
        widget.onStudentAdded?.call();
      } else {
        _handleError(
          title: 'Registration Failed',
          message: data['message'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      _handleError(
        title: 'Error',
        message: 'An error occurred. Please try again.',
      );
    }
  }

Future<void> _addClass() async {
  if (!_formKey.currentState!.validate()) {
    setState(() => _autoValidate = true);
    return;
  }

  setState(() => _isLoading = true);
  DialogUtils.showLoadingDialog(context, "Creating class...");
  final startTime = DateTime.now();

  try {
    final response = await ClassroomService.createClass({
      'class_name': classNameController.text.trim(),
      'section': classSectionController.text.trim(),
      'grade_level': gradeLevelController.text.trim(),
      'school_year': schoolYearController.text.trim(),
    });

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    if (elapsed < 2000) {
      await Future.delayed(Duration(milliseconds: 2000 - elapsed));
    }

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      _handleError(
        title: 'Server Error',
        message: 'Invalid server response format.',
      );
      return;
    }

    if (response.statusCode == 201) {
      await _handleSuccess('Class created!');
      widget.onClassAdded?.call();
    } else {
      _handleError(
        title: 'Create Class Failed',
        message: data['message'] ?? 'An error occurred.',
      );
    }
  } catch (e) {
    _handleError(
      title: 'Error',
      message: 'Failed to create class. Please try again.',
    );
  }
}


  Future<void> _handleSuccess(String message) async {
    if (!mounted) return;

    Navigator.of(context).pop(); // Close loading dialog
    await DialogUtils.showSuccessDialog(context, message);

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pop(); // Close dialog

    _showSuccessSnackbar(
      selectedTab == 0
          ? "Class created successfully!"
          : "Student created successfully!",
    );
  }

  void _handleError({required String title, required String message}) {
    if (!mounted) return;

    setState(() => _isLoading = false);
    Navigator.of(context).pop(); // Close loading dialog
    DialogUtils.showErrorDialog(
      context: context,
      title: title,
      message: message,
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          selectedTab == 1
              ? Image.asset(
                'assets/icons/graduating-student.png',
                width: 70,
                height: 70,
              )
              : Icon(
                Icons.class_,
                color: Theme.of(context).colorScheme.primary,
                size: 70,
              ),
          const SizedBox(height: 8),
          Text(
            selectedTab == 0 ? "Create New Class" : "Create Student Account",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          Divider(thickness: 1, color: Colors.grey.shade300),
          // Toggle buttons for selection
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text("Class"),
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
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text("Student"),
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
                  ? ClassForm(
                    classNameController: classNameController,
                    classSectionController: classSectionController,
                    gradeLevelController: gradeLevelController,
                    schoolYearController: schoolYearController,
                    selectedGradeLevel: _selectedGradeLevel,
                    onGradeLevelChanged: (value) {
                      setState(() {
                        _selectedGradeLevel = value;
                        gradeLevelController.text = value.toString();
                      });
                    },
                  )
                  : StudentForm(
                    studentNameController: studentNameController,
                    studentLrnController: studentLrnController,
                    studentSectionController: studentSectionController,
                    studentGradeController: studentGradeController,
                    studentUsernameController: studentUsernameController,
                    studentPasswordController: studentPasswordController,
                    confirmStudentPasswordController:
                        confirmStudentPasswordController,
                    studentPasswordVisible: _studentPasswordVisible,
                    studentConfirmPasswordVisible:
                        _studentConfirmPasswordVisible,
                    onPasswordToggle:
                        () => setState(
                          () =>
                              _studentPasswordVisible =
                                  !_studentPasswordVisible,
                        ),
                    onConfirmPasswordToggle:
                        () => setState(
                          () =>
                              _studentConfirmPasswordVisible =
                                  !_studentConfirmPasswordVisible,
                        ),
                  ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.grey),
          label: const Text(
            "Cancel",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            foregroundColor: Colors.grey,
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 3,
          ),
          onPressed:
              _isLoading
                  ? null
                  : () {
                    if (selectedTab == 0) {
                      _addClass();
                    } else {
                      _addStudent();
                    }
                  },
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            selectedTab == 0 ? "Create" : "Create",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
