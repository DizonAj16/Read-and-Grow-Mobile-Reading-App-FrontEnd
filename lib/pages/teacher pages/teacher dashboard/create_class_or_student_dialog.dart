// changes on grade textfield now used dropdown selected for ez access//

import 'dart:convert';

import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class CreateClassOrStudentDialog extends StatefulWidget {
  final VoidCallback? onClassAdded;
  final VoidCallback? onStudentAdded;

  const CreateClassOrStudentDialog({
    this.onClassAdded,
    this.onStudentAdded,
    Key? key,
  }) : super(key: key);

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

  // Controllers
  final classNameController = TextEditingController();
  final classSectionController = TextEditingController();
  final gradeLevelController = TextEditingController();
  final schoolYearController = TextEditingController();
  final studentNameController = TextEditingController();
  final studentLrnController = TextEditingController();
  final studentGradeController = TextEditingController();
  final studentSectionController = TextEditingController();
  final studentUsernameController = TextEditingController();
  final studentPasswordController = TextEditingController();
  final confirmStudentPasswordController = TextEditingController();

  @override
  void dispose() {
    classNameController.dispose();
    classSectionController.dispose();
    gradeLevelController.dispose();
    schoolYearController.dispose();
    studentNameController.dispose();
    studentLrnController.dispose();
    studentGradeController.dispose();
    studentSectionController.dispose();
    studentUsernameController.dispose();
    studentPasswordController.dispose();
    confirmStudentPasswordController.dispose();
    super.dispose();
  }

  Widget _buildGradeLevelDropdown({
    required String label,
    required TextEditingController controller,
  }) {
    return DropdownButtonFormField<String>(
      value: controller.text.isNotEmpty ? controller.text : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.07),
        prefixIcon: Icon(
          Icons.grade,
          color: Theme.of(context).colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      ),
      items:
          List.generate(6, (i) => (i + 1).toString())
              .map((g) => DropdownMenuItem(value: g, child: Text('Grade $g')))
              .toList(),
      onChanged: (val) => setState(() => controller.text = val ?? ''),
      validator:
          (val) => val == null || val.isEmpty ? 'Grade is required' : null,
    );
  }

  Widget _buildSimpleField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.07),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      ),
    );
  }

  Future<void> _addClass() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }
    setState(() => _isLoading = true);
    _showLoading('Creating class...');
    await Future.delayed(Duration(seconds: 1));
    try {
      final resp = await ApiService.createClass({
        'class_name': classNameController.text,
        'grade_level': gradeLevelController.text,
        'section': classSectionController.text,
        'school_year': schoolYearController.text,
      });
      final data = jsonDecode(resp.body);
      if (resp.statusCode == 201) {
        Navigator.of(context).pop();
        await _showSuccess(data['message'] ?? 'Class created');
        widget.onClassAdded?.call();
        Navigator.of(context).pop();
      } else {
        _showError('Create Class Failed', data['message'] ?? '');
      }
    } catch (e) {
      _showError('Error', 'Failed to create class');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }
    setState(() => _isLoading = true);
    _showLoading('Creating student account...');
    await Future.delayed(Duration(seconds: 1));
    try {
      final resp = await ApiService.registerStudent({
        'student_name': studentNameController.text,
        'student_lrn': studentLrnController.text,
        'student_grade': studentGradeController.text,
        'student_section': studentSectionController.text,
        'student_username': studentUsernameController.text,
        'student_password': studentPasswordController.text,
        'student_password_confirmation': confirmStudentPasswordController.text,
      });
      final data = jsonDecode(resp.body);
      if (resp.statusCode == 201) {
        Navigator.of(context).pop();
        await _showSuccess(data['message'] ?? 'Student created');
        widget.onStudentAdded?.call();
        Navigator.of(context).pop();
      } else {
        _showError('Registration Failed', data['message'] ?? '');
      }
    } catch (e) {
      _showError('Error', 'Failed to create student');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLoading(String msg) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (_) => Center(
            child: Lottie.asset(
              'assets/animation/loading2.json',
              width: 75,
              height: 75,
            ),
          ),
    );
  }

  Future<void> _showSuccess(String msg) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (_) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animation/success.json',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 16),
                Text(
                  msg,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
    );
    await Future.delayed(Duration(seconds: 2));
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _showError(String title, String msg) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildClassForm() => Column(
    children: [
      _buildSimpleField(
        controller: classNameController,
        label: 'Class Name',
        icon: Icons.edit,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      _buildGradeLevelDropdown(
        label: 'Grade Level',
        controller: gradeLevelController,
      ),
      const SizedBox(height: 16),
      _buildSimpleField(
        controller: classSectionController,
        label: 'Section',
        icon: Icons.group,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      _buildSimpleField(
        controller: schoolYearController,
        label: 'School Year',
        icon: Icons.calendar_today,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      ),
    ],
  );

  Widget _buildStudentForm() => Column(
    children: [
      _buildSimpleField(
        controller: studentNameController,
        label: 'Student Name',
        icon: Icons.person,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      _buildSimpleField(
        controller: studentLrnController,
        label: 'LRN',
        icon: Icons.confirmation_number,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      _buildGradeLevelDropdown(
        label: 'Grade Level',
        controller: studentGradeController,
      ),
      const SizedBox(height: 16),
      _buildSimpleField(
        controller: studentSectionController,
        label: 'Section',
        icon: Icons.group,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      _buildSimpleField(
        controller: studentUsernameController,
        label: 'Username',
        icon: Icons.account_circle,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      _buildSimpleField(
        controller: studentPasswordController,
        label: 'Password',
        icon: Icons.lock,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        obscure: !_studentPasswordVisible,
        suffixIcon: IconButton(
          icon: Icon(
            _studentPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed:
              () => setState(
                () => _studentPasswordVisible = !_studentPasswordVisible,
              ),
        ),
      ),
      const SizedBox(height: 16),
      _buildSimpleField(
        controller: confirmStudentPasswordController,
        label: 'Confirm Password',
        icon: Icons.lock,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          if (v != studentPasswordController.text)
            return 'Passwords do not match';
          return null;
        },
        obscure: !_studentConfirmPasswordVisible,
        suffixIcon: IconButton(
          icon: Icon(
            _studentConfirmPasswordVisible
                ? Icons.visibility
                : Icons.visibility_off,
          ),
          onPressed:
              () => setState(
                () =>
                    _studentConfirmPasswordVisible =
                        !_studentConfirmPasswordVisible,
              ),
        ),
      ),
    ],
  );

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
            selectedTab == 0 ? 'Create New Class' : 'Create Student Account',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const Divider(thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Class'),
                selected: selectedTab == 0,
                onSelected: (_) => setState(() => selectedTab = 0),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('Student'),
                selected: selectedTab == 1,
                onSelected: (_) => setState(() => selectedTab = 1),
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
          child: selectedTab == 0 ? _buildClassForm() : _buildStudentForm(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
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
          child: Text(_isLoading ? 'Submitting...' : 'Create'),
        ),
      ],
    );
  }
}
