import 'package:deped_reading_app_laravel/models/student_model.dart';
import 'package:flutter/material.dart';

// =============================================================================
// STUDENT LIST ITEM WIDGET
// =============================================================================

/// A customizable list item widget for displaying student information
/// with options to view, edit, and delete student records
class StudentListItem extends StatelessWidget {
  // ===========================================================================
  // PROPERTIES
  // ===========================================================================

  final Student student;
  final String? imageUrl;
  final VoidCallback onViewPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  const StudentListItem({
    super.key,
    required this.student,
    required this.imageUrl,
    required this.onViewPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      decoration: _buildContainerDecoration(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 18,
        ),
        leading: _buildStudentAvatar(context),
        title: _buildStudentName(context),
        subtitle: _buildStudentTags(context),
        trailing: _buildPopupMenu(context),
      ),
    );
  }

  // ===========================================================================
  // UI COMPONENT BUILDERS
  // ===========================================================================

  /// Builds the container decoration with shadow and border
  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        width: 1.5,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Theme.of(context).colorScheme.surface,
          Theme.of(context).colorScheme.surface.withOpacity(0.95),
        ],
      ),
    );
  }

  /// Builds the student avatar with network image or fallback
  Widget _buildStudentAvatar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child:
            imageUrl != null && imageUrl!.isNotEmpty
                ? _buildNetworkImage(context)
                : _buildAvatarFallback(context),
      ),
    );
  }

  /// Builds the network image with fade-in effect and error handling
  Widget _buildNetworkImage(BuildContext context) {
    return ClipOval(
      child: FadeInImage.assetNetwork(
        placeholder: 'assets/placeholder/avatar_placeholder.jpg',
        image: imageUrl!,
        imageErrorBuilder: (_, __, ___) => _buildAvatarFallback(context),
        fadeInDuration: const Duration(milliseconds: 400),
        fadeInCurve: Curves.easeOut,
        placeholderFit: BoxFit.cover,
        fit: BoxFit.cover,
        width: 60,
        height: 60,
        placeholderScale: 1.0,
        imageScale: 1.0,
      ),
    );
  }

  /// Builds the fallback avatar with student initials
  Widget _buildAvatarFallback(BuildContext context) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        student.avatarLetter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the student name text with styling
  Widget _buildStudentName(BuildContext context) {
    return Text(
      student.studentName,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 17,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the student tags (section and grade)
  Widget _buildStudentTags(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (student.studentSection != null &&
              student.studentSection!.isNotEmpty)
            _buildSectionTag(context),
          if (student.studentGrade != null && student.studentGrade!.isNotEmpty)
            _buildGradeTag(context),
        ],
      ),
    );
  }

  /// Builds the section tag with styling
  Widget _buildSectionTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        "Section: ${student.studentSection}",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Builds the grade tag with styling
  Widget _buildGradeTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        "Grade: ${student.studentGrade}",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  // ===========================================================================
  // POPUP MENU COMPONENT
  // ===========================================================================

  /// Builds the popup menu with action options
  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      onSelected: (value) => _handleMenuSelection(value),
      itemBuilder: (context) => _buildMenuItems(context),
    );
  }

  /// Handles menu item selection
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'view':
        onViewPressed();
        break;
      case 'edit':
        onEditPressed();
        break;
      case 'delete':
        onDeletePressed();
        break;
    }
  }

  /// Builds the menu items with icons and styling
  List<PopupMenuItem<String>> _buildMenuItems(BuildContext context) {
    return [
      PopupMenuItem(
        value: 'view',
        height: 40,
        child: Row(
          children: [
            Icon(
              Icons.visibility_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'View Details',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'edit',
        height: 40,
        child: Row(
          children: [
            Icon(
              Icons.edit_outlined,
              color: Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Edit Student',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'delete',
        height: 40,
        child: Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Delete',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
