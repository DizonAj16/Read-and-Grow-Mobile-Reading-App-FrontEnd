import 'package:flutter/material.dart';

class ClassInfoPage extends StatelessWidget {
  final Map<String, dynamic> classDetails;

  const ClassInfoPage({super.key, required this.classDetails});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "📚 Class Information",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
          ),
          const SizedBox(height: 16),

          // ✅ Class Name
          _infoBox(
            context,
            icon: Icons.class_,
            label: "Class Name",
            value: classDetails['class_name'],
            color: colorScheme.primary,
          ),

          // ✅ Grade Level
          _infoBox(
            context,
            icon: Icons.grade,
            label: "Grade Level",
            value: classDetails['grade_level'],
            color: Colors.blueAccent,
          ),

          // ✅ Section
          _infoBox(
            context,
            icon: Icons.group,
            label: "Section",
            value: classDetails['section'] ?? "N/A",
            color: Colors.teal,
          ),

          // ✅ Students Count
          _infoBox(
            context,
            icon: Icons.people_alt,
            label: "Students",
            value: "${classDetails['student_count']}",
            color: Colors.deepPurple,
          ),

          // ✅ Teacher Name
          _infoBox(
            context,
            icon: Icons.person,
            label: "Teacher",
            value: classDetails['teacher_name'] ?? 'N/A',
            color: Colors.orangeAccent,
          ),

          // ✅ Classroom Code (NEW)
          _infoBox(
            context,
            icon: Icons.vpn_key, // Key icon to represent code
            label: "Classroom Code",
            value: classDetails['classroom_code'] ?? "N/A",
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _infoBox(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: onSurface,
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
