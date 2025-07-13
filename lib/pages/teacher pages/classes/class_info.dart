// lib/class_info.dart
import 'package:flutter/material.dart';

class ClassInfoPage extends StatelessWidget {
  final Map<String, dynamic> classDetails;

  const ClassInfoPage({super.key, required this.classDetails});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoTile(context, Icons.class_, "Class Name", classDetails['class_name']),
              _infoTile(context, Icons.grade, "Grade Level", classDetails['grade_level']),
              _infoTile(context, Icons.group, "Section", classDetails['section']),
              _infoTile(context, Icons.people_alt, "Students", "${classDetails['student_count']}"),
              _infoTile(context, Icons.person, "Teacher", classDetails['teacher_name'] ?? 'N/A'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(BuildContext context, IconData icon, String label, String? value) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
