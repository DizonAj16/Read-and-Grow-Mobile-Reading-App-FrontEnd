import 'package:flutter/material.dart';
import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/models/classroom.dart';
import 'package:lottie/lottie.dart';

class EditClassDialog extends StatefulWidget {
  final Classroom classroom;
  final VoidCallback onClassUpdated;

  const EditClassDialog({
    super.key,
    required this.classroom,
    required this.onClassUpdated,
  });

  @override
  State<EditClassDialog> createState() => _EditClassDialogState();
}

class _EditClassDialogState extends State<EditClassDialog> {
  late TextEditingController _classNameController;
  late TextEditingController _sectionController;
  late TextEditingController _schoolYearController;
  int? _selectedGrade;
  DateTime? _loadingStartTime;

  @override
  void initState() {
    super.initState();
    _classNameController = TextEditingController(
      text: widget.classroom.className,
    );
    _sectionController = TextEditingController(text: widget.classroom.section);
    _schoolYearController = TextEditingController(
      text: widget.classroom.schoolYear,
    );
    _selectedGrade = int.tryParse(widget.classroom.gradeLevel);
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _sectionController.dispose();
    _schoolYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gradeLevels = [1, 2, 3, 4, 5];
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.edit, color: primaryColor, size: 30),
          const SizedBox(width: 8),
          Text(
            "Edit Class",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              context: context,
              controller: _classNameController,
              label: "Class Name",
            ),
            const SizedBox(height: 12),
            _buildTextField(
              context: context,
              controller: _sectionController,
              label: "Section",
            ),
            const SizedBox(height: 12),
            _buildTextField(
              context: context,
              controller: _schoolYearController,
              label: "School Year (e.g., 2024-2025)",
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _selectedGrade,
              decoration: _buildInputDecoration(context, "Grade Level"),
              items:
                  gradeLevels
                      .map(
                        (grade) => DropdownMenuItem(
                          value: grade,
                          child: Text("Grade $grade"),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _selectedGrade = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.cancel),
          onPressed: () => Navigator.pop(context),
          label: const Text("Cancel"),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          onPressed: _handleSave,
          label: const Text("Save"),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: primaryColor.withOpacity(0.07),
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
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 18,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(BuildContext context, String label) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: primaryColor.withOpacity(0.07),
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
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
    );
  }

  Future<void> _handleSave() async {
    final newClassName = _classNameController.text.trim();
    final newSection = _sectionController.text.trim();
    final newSchoolYear = _schoolYearController.text.trim();

    if (newClassName.isEmpty ||
        newSection.isEmpty ||
        newSchoolYear.isEmpty ||
        _selectedGrade == null) {
      _showError("All fields are required.");
      return;
    }

    final yearRegex = RegExp(r'^\d{4}-\d{4}$');
    if (!yearRegex.hasMatch(newSchoolYear)) {
      _showError("Invalid school year format (e.g., 2024-2025).");
      return;
    }

    if (_selectedGrade! < 1 || _selectedGrade! > 12) {
      _showError("Grade level must be between 1 and 12.");
      return;
    }

    _loadingStartTime = DateTime.now();
    _showLoading();

    try {
      final response = await ClassroomService.updateClass(
        classId: widget.classroom.id!,
        body: {
          'class_name': newClassName,
          'grade_level': _selectedGrade.toString(),
          'section': newSection,
          'school_year': newSchoolYear,
        },
      );

      // Ensure loading shows for at least 2 seconds
      await _ensureMinimumLoadingTime();

      if (response.statusCode == 200) {
        widget.onClassUpdated();
        if (mounted) {
          Navigator.pop(context); // Close dialog
          _showSuccess("Class updated successfully!");
        }
      } else {
        if (mounted)
          _showError("Failed to update class: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) _showError("Error: $e");
    } finally {
      if (mounted) Navigator.pop(context); // Close loading
    }
  }

  Future<void> _ensureMinimumLoadingTime() async {
    if (_loadingStartTime != null) {
      final elapsed = DateTime.now().difference(_loadingStartTime!);
      final remaining = const Duration(seconds: 3) - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animation/edit.json',
                    width: 100,
                    height: 100,
                  ),
                  Text(
                    "Updating Class...",
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red[400]),
    );
  }

  void _showSuccess(String message) {
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
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
