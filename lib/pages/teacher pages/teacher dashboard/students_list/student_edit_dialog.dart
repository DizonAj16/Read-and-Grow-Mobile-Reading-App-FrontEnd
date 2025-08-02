import 'package:flutter/material.dart';

class StudentEditDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController lrnController;
  final TextEditingController gradeController;
  final TextEditingController sectionController;
  final TextEditingController usernameController;

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
  final Map<String, String> gradeMap = {
    '1': 'Grade 1',
    '2': 'Grade 2',
    '3': 'Grade 3',
    '4': 'Grade 4',
    '5': 'Grade 5',
  };

  String? selectedGradeKey;

  @override
  void initState() {
    super.initState();
    selectedGradeKey = _matchGradeKey(widget.gradeController.text);
  }

  String _matchGradeKey(String value) {
    // Try to extract just the digit if full text was saved
    final match = RegExp(r'\d+').firstMatch(value);
    final key = match?.group(0) ?? '1';
    return gradeMap.containsKey(key) ? key : '1';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '✏️ Edit Student',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInputField(context, 'Name', widget.nameController),
            _buildInputField(context, 'LRN', widget.lrnController),
            _buildGradeDropdown(context),
            _buildInputField(context, 'Section', widget.sectionController),
            _buildInputField(context, 'Username', widget.usernameController),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            // Set only the numeric grade value
            widget.gradeController.text = selectedGradeKey!;
            Navigator.pop(context, true);
          },
          icon: const Icon(Icons.check),
          label: const Text('Update'),
        ),
      ],
    );
  }

  Widget _buildInputField(
    BuildContext context,
    String label,
    TextEditingController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: colorScheme.primary.withOpacity(0.07),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildGradeDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedGradeKey,
        decoration: InputDecoration(
          labelText: 'Grade',
          labelStyle: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: colorScheme.primary.withOpacity(0.07),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 18,
          ),
        ),
        items: gradeMap.entries.map((entry) {
          return DropdownMenuItem<String>(
            value: entry.key,
            child: Text(entry.value),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedGradeKey = value;
          });
        },
      ),
    );
  }
}
