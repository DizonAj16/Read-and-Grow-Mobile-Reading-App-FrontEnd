import 'package:deped_reading_app_laravel/models/student_model.dart';
import 'package:flutter/material.dart';

import '../../../../api/tol.dart';

// =============================================================================
// STUDENT INFO DIALOG
// =============================================================================

/// A dialog that displays comprehensive student profile information
/// including personal details, academic information, and profile image
class StudentInfoDialog extends StatelessWidget {
  // ===========================================================================
  // PROPERTIES
  // ===========================================================================

  final Student student;
  final String? profileUrl;
  final ColorScheme colorScheme;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  const StudentInfoDialog({
    super.key,
    required this.student,
    required this.profileUrl,
    required this.colorScheme,
  });

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.97),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildProfileImage(context),
            const SizedBox(height: 16),
            _buildStudentName(context),
            const SizedBox(height: 4),
            _buildUsername(context),
            const SizedBox(height: 24),
            _buildInfoBox(context),
            const SizedBox(height: 24),
            _buildCloseButton(context),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // UI COMPONENT BUILDERS
  // ===========================================================================

  /// Builds the dialog header with title and icon
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.person_pin_rounded, color: colorScheme.primary, size: 32),
        const SizedBox(width: 12),
        Text(
          'Student Profile',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ],
    );
  }

  /// Builds the student profile image or avatar fallback
  Widget _buildProfileImage(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circle
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withOpacity(0.1),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.3),
              width: 3,
            ),
          ),
        ),
        // Profile image or avatar
        CircleAvatar(
          radius: 56,
          backgroundColor: colorScheme.primary.withOpacity(0.9),
          backgroundImage:
              profileUrl != null && profileUrl!.isNotEmpty
                  ? NetworkImage(profileUrl!)
                  : null,
          child:
              profileUrl == null || profileUrl!.isEmpty
                  ? Text(
                    student.avatarLetter,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  )
                  : null,
        ),
      ],
    );
  }

  /// Builds the student name text
  Widget _buildStudentName(BuildContext context) {
    return Text(
      student.studentName,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        fontSize: 20,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the username text
  Widget _buildUsername(BuildContext context) {
    return Text(
      student.username != null ? "@${student.username}" : "-",
      style: TextStyle(
        fontSize: 15,
        color: colorScheme.onSurface.withOpacity(0.7),
        fontStyle: student.username == null ? FontStyle.italic : null,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Builds the information box with student details
  Widget _buildInfoBox(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        children: [
          _infoRow(
            context: context,
            icon: Icons.confirmation_num_rounded,
            label: 'LRN',
            value: student.studentLrn ?? "Not provided",
            color: colorScheme.onSurface,
          ),
          const SizedBox(height: 16),
          _infoRow(
            context: context,
            icon: Icons.school_rounded,
            label: 'Grade Level',
            value: student.studentGrade ?? "Not assigned",
            color: colorScheme.onSurface,
          ),
          const SizedBox(height: 16),
          _infoRow(
            context: context,
            icon: Icons.group_rounded,
            label: 'Section',
            value: student.studentSection ?? "Not assigned",
            color: colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  /// Builds a single information row with icon and text
  Widget _infoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon container with background
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 16),
        // Information text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              // Value
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the close button at the bottom
  Widget _buildCloseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StudentVoiceAssessmentPage(
                assignmentId: '148d01c7-67d3-4c40-9414-21beb4e3531c',
                student: student,
                profileUrl: profileUrl,
                colorScheme: colorScheme, recordingFilePath: 'https://zrcynmiiduwrtlcyzvzi.supabase.co/storage/v1/object/public/student_voice/TERROR%20JR%20-%203%20STRIKES%20(%20LYRICS%20VIDEO%20).mp3',
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          shadowColor: colorScheme.primary.withOpacity(0.3),
        ),
        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: const Text(
          'Close Profile',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
