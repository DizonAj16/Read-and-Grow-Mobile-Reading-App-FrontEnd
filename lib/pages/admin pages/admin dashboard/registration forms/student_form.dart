import 'package:flutter/material.dart';

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
            prefixIcon: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Name is required'
                      : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: lrnController,
          decoration: InputDecoration(
            labelText: "LRN",
            prefixIcon: Icon(
              Icons.confirmation_number,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'LRN is required'
                      : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: gradeController,
          decoration: InputDecoration(
            labelText: "Grade",
            prefixIcon: Icon(
              Icons.grade,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Grade is required'
                      : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: sectionController,
          decoration: InputDecoration(
            labelText: "Section",
            prefixIcon: Icon(
              Icons.group,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Section is required'
                      : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: usernameController,
          decoration: InputDecoration(
            labelText: "Username",
            prefixIcon: Icon(
              Icons.account_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Username is required'
                      : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          obscureText: !passwordVisible,
          decoration: InputDecoration(
            labelText: "Password",
            prefixIcon: Icon(
              Icons.lock,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => onPasswordVisibilityChanged(!passwordVisible),
            ),
          ),
          validator:
              (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Password is required'
                      : null,
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: !confirmPasswordVisible,
          decoration: InputDecoration(
            labelText: "Confirm Password",
            prefixIcon: Icon(
              Icons.lock,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(
                confirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed:
                  () => onConfirmPasswordVisibilityChanged(
                    !confirmPasswordVisible,
                  ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty)
              return 'Confirm Password is required';
            if (value != passwordController.text)
              return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }
}
