import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

// --- Dialog for Create Class or Student (admin-style, API integrated for student) ---
class CreateClassOrStudentDialog extends StatefulWidget {
  final VoidCallback? onStudentAdded;
  final VoidCallback? onClassAdded;

  const CreateClassOrStudentDialog({this.onStudentAdded, this.onClassAdded});
  @override
  State<CreateClassOrStudentDialog> createState() =>
      CreateClassOrStudentDialogState();
}

class CreateClassOrStudentDialogState
    extends State<CreateClassOrStudentDialog> {
  int selectedTab = 1; // 0 = Class, 1 = Student

  // Controllers for form fields
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

  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  bool _isLoading = false;
  bool _studentPasswordVisible = false;
  bool _studentConfirmPasswordVisible = false;

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

  /// Shows a loading dialog with a message
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder:
          (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 75,
                    height: 75,
                    child: Lottie.asset('assets/animation/loading2.json'),
                  ),
                  SizedBox(height: 12),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// Shows a success dialog
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

  /// Handles error dialog
  void _handleErrorDialog({required String title, required String message}) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(); // Close loading dialog
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 35),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              content: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
      );
    }
  }

  /// Handles student creation via API
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

    await Future.delayed(const Duration(seconds: 2));

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
          message:
              response.statusCode >= 500
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
        widget.onStudentAdded?.call();
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  "Student created successfully!",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: 20, left: 20, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            duration: Duration(seconds: 2),
          ),
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

  Future<void> _addClass() async {
    final className = classNameController.text.trim();
    final section = classSectionController.text.trim();
    final gradeLevel = gradeLevelController.text.trim();
    final schoolYear = schoolYearController.text.trim();

    if (className.isEmpty ||
        section.isEmpty ||
        gradeLevel.isEmpty ||
        schoolYear.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill in all fields")));
      return;
    }

    setState(() => _isLoading = true);
    _showLoadingDialog("Creating class...");
    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await ApiService.createClass({
        'class_name': className,
        'section': section,
        'grade_level': gradeLevel,
        'school_year': schoolYear,
      });

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        _handleErrorDialog(
          title: 'Server Error',
          message: 'Invalid server response format.',
        );
        return;
      }

      if (response.statusCode == 201) {
        Navigator.of(context).pop(); // Close loading dialog
        await _showSuccessDialog('Class created!');
        if (mounted) {
          setState(() => _isLoading = false);
        }

        widget.onClassAdded?.call(); // ✅ refresh class count
        Navigator.of(context).pop(); // Close dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  "Class created successfully!",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: 20, left: 20, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _handleErrorDialog(
          title: 'Create Class Failed',
          message: data['message'] ?? 'An error occurred.',
        );
      }
    } catch (e) {
      _handleErrorDialog(
        title: 'Error',
        message: 'Failed to create class. Please try again.',
      );
    }
  }

  /// Builds a password field with show/hide toggle
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.07),
        prefixIcon: Icon(
          Icons.lock,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: onToggle,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      ),
      validator: validator,
    );
  }

  /// Builds a simple text field with icon and validation
  Widget _buildSimpleTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.07),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      ),
      validator: validator,
    );
  }

  /// Student creation form
  Widget _buildStudentForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSimpleTextField(
          controller: studentNameController,
          label: "Student Name",
          icon: Icons.person,
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Name is required'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildSimpleTextField(
          controller: studentLrnController,
          label: "LRN",
          icon: Icons.confirmation_number,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'LRN is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildSimpleTextField(
          controller: studentGradeController,
          label: "Grade",
          icon: Icons.grade,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            FilteringTextInputFormatter.allow(RegExp(r'^[1-6]$')),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Grade is required';
            }
            final numValue = int.tryParse(value);
            if (numValue == null || numValue < 1 || numValue > 6) {
              return 'Grade must be between 1 and 6';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildSimpleTextField(
          controller: studentSectionController,
          label: "Section",
          icon: Icons.group,
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Section is required'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildSimpleTextField(
          controller: studentUsernameController,
          label: "Username",
          icon: Icons.account_circle,
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Username is required'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: studentPasswordController,
          label: "Password",
          visible: _studentPasswordVisible,
          onToggle:
              () => setState(
                () => _studentPasswordVisible = !_studentPasswordVisible,
              ),
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Password is required'
                      : null,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: confirmStudentPasswordController,
          label: "Confirm Password",
          visible: _studentConfirmPasswordVisible,
          onToggle:
              () => setState(
                () =>
                    _studentConfirmPasswordVisible =
                        !_studentConfirmPasswordVisible,
              ),
          validator: (value) {
            if (value == null || value.trim().isEmpty)
              return 'Confirm Password is required';
            if (value != studentPasswordController.text)
              return 'Passwords do not match';
            return null;
          },
        ),
      ],
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
              ), // Icon or image based on selected tab
          SizedBox(height: 8),
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
                label: Text("Class"),
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
                  ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSimpleTextField(
                        controller: classNameController,
                        label: "Class Name",
                        icon: Icons.edit,
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Class name is required'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      _buildSimpleTextField(
                        controller: gradeLevelController,
                        label: "Grade Level",
                        icon: Icons.grade,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Grade level is required'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      _buildSimpleTextField(
                        controller: classSectionController,
                        label: "Section",
                        icon: Icons.group,
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Section is required'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      _buildSimpleTextField(
                        controller: schoolYearController,
                        label: "School Year",
                        icon: Icons.calendar_today,
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'School year is required'
                                    : null,
                      ),
                    ],
                  )
                  : _buildStudentForm(context),
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
                    print("Selected Tab: $selectedTab");
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
