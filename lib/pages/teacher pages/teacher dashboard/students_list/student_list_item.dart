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
  final VoidCallback? onAssignLevelPressed;

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
    this.onAssignLevelPressed,
  });

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      decoration: _buildContainerDecoration(context),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 14,
        ),
        leading: _buildStudentAvatar(context),
        title: _buildStudentName(context),
        subtitle: _buildStudentTags(context),
        trailing: _buildPopupMenu(context),
        dense: true, // Added to make the list tile more compact
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
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 6,
          spreadRadius: 1,
          offset: const Offset(0, 3),
        ),
      ],
      border: Border.all(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        width: 1.0,
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
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 24, // Slightly smaller avatar
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
        fadeInDuration: const Duration(milliseconds: 300),
        fadeInCurve: Curves.easeOut,
        placeholderFit: BoxFit.cover,
        fit: BoxFit.cover,
        width: 48,
        height: 48,
        placeholderScale: 1.0,
        imageScale: 1.0,
      ),
    );
  }

  /// Builds the fallback avatar with student initials
  Widget _buildAvatarFallback(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        student.avatarLetter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600, // Slightly less bold
          fontSize: 16, // Smaller font size
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 1,
              offset: const Offset(0.5, 0.5),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the student name text with smaller styling
  Widget _buildStudentName(BuildContext context) {
    return Text(
      student.studentName,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 14, // Smaller font size
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.1,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the student tags (section and grade)
  Widget _buildStudentTags(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 3,
        children: [
          if (student.studentGrade != null && student.studentGrade!.isNotEmpty)
            _buildGradeTag(context),
          if (student.studentSection != null &&
              student.studentSection!.isNotEmpty)
            _buildSectionTag(context),
        ],
      ),
    );
  }

  /// Builds the section tag with smaller styling
  Widget _buildSectionTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // Smaller padding
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10), // Slightly smaller radius
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          width: 0.8,
        ),
      ),
      child: Text(
        "Sec: ${student.studentSection}", // Shorter label
        style: TextStyle(
          fontSize: 10, // Smaller font size
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Builds the grade tag with smaller styling
  Widget _buildGradeTag(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // Smaller padding
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10), // Slightly smaller radius
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          width: 0.8,
        ),
      ),
      child: Text(
        "Gr: ${student.studentGrade}", // Shorter label
        style: TextStyle(
          fontSize: 10, // Smaller font size
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.primary,
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
        size: 20, // Smaller icon
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
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
      case 'assign_level':
        if (onAssignLevelPressed != null) onAssignLevelPressed!();
        break;
      case 'delete':
        onDeletePressed();
        break;
    }
  }

  /// Builds the menu items with smaller icons and text
  List<PopupMenuItem<String>> _buildMenuItems(BuildContext context) {
    return [
      PopupMenuItem(
        value: 'view',
        height: 34, // Smaller height
        child: Row(
          children: [
            Icon(
              Icons.visibility_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 18, // Smaller icon
            ),
            const SizedBox(width: 10), // Smaller spacing
            Text(
              'View',
              style: TextStyle(
                // Shorter label
                fontSize: 12, // Smaller font size
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'edit',
        height: 34, // Smaller height
        child: Row(
          children: [
            Icon(
              Icons.edit_outlined,
              color: Theme.of(context).colorScheme.secondary,
              size: 18, // Smaller icon
            ),
            const SizedBox(width: 10), // Smaller spacing
            Text(
              'Edit',
              style: TextStyle(
                // Shorter label
                fontSize: 12, // Smaller font size
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'assign_level',
        height: 34, // Smaller height
        child: Row(
          children: [
            Icon(
              Icons.star_rate_rounded,
              color: Colors.amber,
              size: 18, // Smaller icon
            ),
            const SizedBox(width: 10), // Smaller spacing
            Text(
              'Assign Level',
              style: TextStyle(
                // Shorter label
                fontSize: 12, // Smaller font size
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'delete',
        height: 34, // Smaller height
        child: Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 18, // Smaller icon
            ),
            const SizedBox(width: 10), // Smaller spacing
            Text(
              'Delete',
              style: TextStyle(
                fontSize: 12, // Smaller font size
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
