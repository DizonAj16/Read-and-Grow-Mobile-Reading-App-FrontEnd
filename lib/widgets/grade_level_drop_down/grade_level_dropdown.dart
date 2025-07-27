import 'package:flutter/material.dart';

class GradeLevelDropDown extends StatelessWidget {
  final Function(String?) onChanged;
  final String? value;

  const GradeLevelDropDown({Key? key, required this.onChanged, this.value})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: "Grade Level",
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        prefixIcon: Icon(
          Icons.grade,
          color: Theme.of(context).colorScheme.primary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator:
          (value) =>
              value == null || value.isEmpty ? 'Grade level is required' : null,
      items: List.generate(6, (index) {
        final grade = (index + 1).toString();
        return DropdownMenuItem<String>(
          value: grade,
          child: Text('Grade $grade'),
        );
      }),
    );
  }
}
