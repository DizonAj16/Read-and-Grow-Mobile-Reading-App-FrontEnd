import 'package:flutter/material.dart';
import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/models/classroom_model.dart';
import 'package:lottie/lottie.dart';

class EditClassBottomModal extends StatefulWidget {
  final Classroom classroom;
  final VoidCallback onClassUpdated;

  const EditClassBottomModal({
    super.key,
    required this.classroom,
    required this.onClassUpdated,
  });

  @override
  State<EditClassBottomModal> createState() => _EditClassBottomModalState();
}

class _EditClassBottomModalState extends State<EditClassBottomModal> {
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
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.edit_rounded,
                  color: primaryColor,
                  size: 32,
                  shadows: [
                    Shadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Text(
                  "Edit Class",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              context: context,
              controller: _classNameController,
              label: "Class Name",
              icon: Icons.class_,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              context: context,
              controller: _sectionController,
              label: "Section",
              icon: Icons.groups,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              context: context,
              controller: _schoolYearController,
              label: "School Year (e.g., 2024-2025)",
              icon: Icons.calendar_today,
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
              icon: Icon(Icons.arrow_drop_down, color: primaryColor),
              dropdownColor: surfaceColor,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      Icons.cancel_outlined,
                      size: 22,
                      color: primaryColor,
                    ),
                    label: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: primaryColor.withOpacity(0.05),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.save_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                    label: Text(
                      "Save Changes",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      shadowColor: primaryColor.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7), size: 22),
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

    _loadingStartTime = DateTime.now();
    _showLoading();

    try {
      final updateFuture = ClassroomService.updateClass(
        classId: widget.classroom.id!,
        body: {
          'class_name': newClassName,
          'grade_level': _selectedGrade.toString(),
          'section': newSection,
          'school_year': newSchoolYear,
        },
      );
      final minDelayFuture = Future.delayed(const Duration(seconds: 3));

      await Future.wait([updateFuture, minDelayFuture]);

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close modal
        widget.onClassUpdated();
        _showSuccess("Class updated successfully!");
      }
    } catch (e) {
      final elapsed = DateTime.now().difference(_loadingStartTime!);
      if (elapsed < const Duration(seconds: 3)) {
        await Future.delayed(const Duration(seconds: 3) - elapsed);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        _showError('Failed to update class: ${e.toString()}');
      }
    }
  }

  void _showLoading() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder:
          (context) => WillPopScope(
        onWillPop: () async => false,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'assets/animation/edit.json',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              Text(
                "Updating Class...",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(
                    backgroundColor:
                    Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                    minHeight: 4,
                  ),
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
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
