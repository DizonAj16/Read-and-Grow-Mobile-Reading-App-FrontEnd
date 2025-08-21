import 'package:flutter/material.dart';

// =============================================================================
// STUDENT EDIT DIALOG
// =============================================================================

/// A dialog for editing student information with form validation
/// and grade level selection dropdown
class StudentEditDialog extends StatefulWidget {
  // ===========================================================================
  // PROPERTIES
  // ===========================================================================

  final TextEditingController nameController;
  final TextEditingController lrnController;
  final TextEditingController gradeController;
  final TextEditingController sectionController;
  final TextEditingController usernameController;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  const StudentEditDialog({
    super.key,
    required this.nameController,
    required this.lrnController,
    required this.gradeController,
    required this.sectionController,
    required this.usernameController,
  });

  @override
  State<StudentEditDialog> createState() => _StudentEditDialogState();
}

class _StudentEditDialogState extends State<StudentEditDialog> {
  // ===========================================================================
  // STATE VARIABLES
  // ===========================================================================

  final Map<String, String> gradeMap = {
    '1': 'Grade 1',
    '2': 'Grade 2',
    '3': 'Grade 3',
    '4': 'Grade 4',
    '5': 'Grade 5',
  };

  String? selectedGradeKey;
  final _formKey = GlobalKey<FormState>();

  // ===========================================================================
  // LIFECYCLE METHODS
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    selectedGradeKey = _matchGradeKey(widget.gradeController.text);
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  /// Matches the grade text to a key in the grade map
  /// Extracts numeric value from stored grade text
  String _matchGradeKey(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    final key = match?.group(0) ?? '1';
    return gradeMap.containsKey(key) ? key : '1';
  }

  /// Validates required fields before submission
  bool _validateForm() {
    if (_formKey.currentState?.validate() ?? false) {
      return true;
    }
    return false;
  }

  /// Handles form submission with validation
  void _handleSubmit() {
    if (_validateForm()) {
      widget.gradeController.text = selectedGradeKey!;
      Navigator.pop(context, true);
    }
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      insetPadding: const EdgeInsets.all(20), // Add padding from screen edges
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: mediaQuery.size.height * 0.7, // 60% of screen height max
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min, // Important for dynamic sizing
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                _buildHeader(theme),
                const SizedBox(height: 20),

                // Scrollable form content
                Expanded(child: _buildScrollableFormContent(colorScheme)),

                // Fixed action buttons at bottom
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // UI COMPONENT BUILDERS
  // ===========================================================================

  /// Builds the dialog header with title
  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(Icons.edit_rounded, color: theme.colorScheme.primary, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Edit Student Information',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Builds scrollable form content
  Widget _buildScrollableFormContent(ColorScheme colorScheme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInputField(
            context: context,
            label: 'Full Name',
            controller: widget.nameController,
            validator: _validateName,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            context: context,
            label: 'LRN (Learner Reference Number)',
            controller: widget.lrnController,
            validator: _validateLRN,
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildGradeDropdown(context),
          const SizedBox(height: 16),
          _buildInputField(
            context: context,
            label: 'Section',
            controller: widget.sectionController,
            validator: _validateSection,
            icon: Icons.class_rounded,
          ),
          const SizedBox(height: 16),
          _buildInputField(
            context: context,
            label: 'Username',
            controller: widget.usernameController,
            validator: _validateUsername,
            icon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 8), // Extra space at bottom for scrolling
        ],
      ),
    );
  }

  /// Builds the action buttons (Cancel and Update)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildCancelButton(),
          const SizedBox(width: 12),
          _buildUpdateButton(),
        ],
      ),
    );
  }

  /// Builds the cancel button
  Widget _buildCancelButton() {
    return TextButton.icon(
      onPressed: () => Navigator.pop(context, false),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.cancel_outlined, size: 20),
      label: const Text('Cancel'),
    );
  }

  /// Builds the update button
  Widget _buildUpdateButton() {
    return ElevatedButton.icon(
      onPressed: _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      ),
      icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
      label: const Text('Update'),
    );
  }

  // ===========================================================================
  // FORM FIELD VALIDATORS
  // ===========================================================================

  /// Validates student name field
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter student name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validates LRN field
  String? _validateLRN(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter LRN';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'LRN must contain only numbers';
    }
    if (value.length != 12) {
      return 'LRN must be 12 digits';
    }
    return null;
  }

  /// Validates section field
  String? _validateSection(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter section';
    }
    return null;
  }

  /// Validates username field
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers and underscores';
    }
    return null;
  }

  // ===========================================================================
  // FORM FIELD BUILDERS
  // ===========================================================================

  /// Builds a styled text input field with validation
  Widget _buildInputField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        prefixIcon: Icon(icon, color: colorScheme.primary.withOpacity(0.7)),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      style: TextStyle(color: colorScheme.onSurface, fontSize: 18),
    );
  }

  /// Builds the grade level dropdown selector
  Widget _buildGradeDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      value: selectedGradeKey,
      decoration: InputDecoration(
        labelText: 'Grade Level',
        labelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        prefixIcon: Icon(
          Icons.school_rounded,
          color: colorScheme.primary.withOpacity(0.7),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
      items:
          gradeMap.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 18),
              ),
            );
          }).toList(),
      onChanged: (value) {
        setState(() {
          selectedGradeKey = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a grade level';
        }
        return null;
      },
      style: TextStyle(color: colorScheme.onSurface, fontSize: 15),
      dropdownColor: colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.primary),
    );
  }
}
