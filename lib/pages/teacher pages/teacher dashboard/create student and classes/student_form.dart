import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'form_field_builders.dart';

class StudentForm extends StatelessWidget {
  final TextEditingController studentNameController;
  final TextEditingController studentLrnController;
  final TextEditingController studentSectionController;
  final TextEditingController studentGradeController;
  final TextEditingController studentUsernameController;
  final TextEditingController studentPasswordController;
  final TextEditingController confirmStudentPasswordController;
  final bool studentPasswordVisible;
  final bool studentConfirmPasswordVisible;
  final VoidCallback onPasswordToggle;
  final VoidCallback onConfirmPasswordToggle;

  const StudentForm({
    super.key,
    required this.studentNameController,
    required this.studentLrnController,
    required this.studentSectionController,
    required this.studentGradeController,
    required this.studentUsernameController,
    required this.studentPasswordController,
    required this.confirmStudentPasswordController,
    required this.studentPasswordVisible,
    required this.studentConfirmPasswordVisible,
    required this.onPasswordToggle,
    required this.onConfirmPasswordToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FormFieldBuilders.buildSimpleTextField(
          context: context,
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
        FormFieldBuilders.buildSimpleTextField(
          context: context,
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
        DropdownButtonFormField<String>(
          value:
              studentGradeController.text.isNotEmpty
                  ? studentGradeController.text
                  : null,
          decoration: InputDecoration(
            labelText: 'Grade',
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
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 18,
            ),
          ),
          items: List.generate(5, (index) {
            final grade = (index + 1).toString();
            return DropdownMenuItem<String>(
              value: grade,
              child: Text('Grade $grade'),
            );
          }),
          onChanged: (value) {
            studentGradeController.text = value!;
          },
          validator:
              (value) =>
                  value == null || value.isEmpty ? 'Grade is required' : null,
        ),

        const SizedBox(height: 16),
        FormFieldBuilders.buildSimpleTextField(
          context: context,
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
        FormFieldBuilders.buildSimpleTextField(
          context: context,
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
        FormFieldBuilders.buildPasswordField(
          context: context,
          controller: studentPasswordController,
          label: "Password",
          visible: studentPasswordVisible,
          onToggle: onPasswordToggle,
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Password is required'
                      : null,
        ),
        const SizedBox(height: 16),
        FormFieldBuilders.buildPasswordField(
          context: context,
          controller: confirmStudentPasswordController,
          label: "Confirm Password",
          visible: studentConfirmPasswordVisible,
          onToggle: onConfirmPasswordToggle,
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
      ],
    );
  }
}
