import 'package:deped_reading_app_laravel/models/student.dart';
import 'package:flutter/material.dart';

class StudentInfoDialog extends StatelessWidget {
  final Student student;
  final String? profileUrl;
  final ColorScheme colorScheme;

  const StudentInfoDialog({
    super.key,
    required this.student,
    required this.profileUrl,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.95),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_pin_rounded, color: colorScheme.primary, size: 36),
          const SizedBox(width: 10),
          Text(
            'Student Profile',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: colorScheme.primary,
            backgroundImage:
                profileUrl != null ? NetworkImage(profileUrl!) : null,
            child:
                profileUrl == null
                    ? Text(
                      student.avatarLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 54,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 12),
          Text(
            student.studentName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            student.username ?? "-",
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoBox(context),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close, color: colorScheme.primary),
          label: Text(
            'Close',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          _infoRow(
            context: context,
            icon: Icons.confirmation_num_rounded,
            label: 'LRN',
            value: student.studentLrn ?? "-",
            color: colorScheme.onSurface,
          ),
          const SizedBox(height: 10),
          _infoRow(
            context: context,
            icon: Icons.school_rounded,
            label: 'Grade',
            value: student.studentGrade ?? "-",
            color: colorScheme.onSurface,
          ),
          const SizedBox(height: 10),
          _infoRow(
            context: context,
            icon: Icons.group_rounded,
            label: 'Section',
            value: student.studentSection ?? "-",
            color: colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required BuildContext context, // Add context parameter
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 16, color: color.withOpacity(0.9)),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
