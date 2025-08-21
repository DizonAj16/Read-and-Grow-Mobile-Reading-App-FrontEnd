import 'package:flutter/material.dart';

// =============================================================================
// STUDENT DELETE DIALOG
// =============================================================================

/// A confirmation dialog for deleting student records
/// Provides visual feedback and requires explicit user confirmation
/// to prevent accidental deletions
class StudentDeleteDialog extends StatelessWidget {
  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  const StudentDeleteDialog({super.key});

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildContent(context),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // UI COMPONENT BUILDERS
  // ===========================================================================

  /// Builds the dialog header with warning icon and title
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Warning icon with container for better visual impact
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.error,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        // Title text
        Expanded(
          child: Text(
            "Confirm Deletion",
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Builds the dialog content with warning message
  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main warning message
        Text(
          "Are you sure you want to delete this student?",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.9),
            fontSize: 16,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        // Additional warning details
        Text(
          "This action cannot be undone. All student data, including progress and records, will be permanently removed from the system.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        // Visual separator
        Divider(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
          thickness: 1,
          height: 1,
        ),
      ],
    );
  }

  /// Builds the action buttons (Cancel and Delete)
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Cancel button
        _buildCancelButton(context),
        const SizedBox(width: 12),
        // Delete button
        _buildDeleteButton(context),
      ],
    );
  }

  /// Builds the cancel button with outlined style
  Widget _buildCancelButton(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: () => Navigator.of(context).pop(false),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.5),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.transparent,
      ),
      icon: Icon(
        Icons.cancel_outlined,
        color: theme.colorScheme.primary,
        size: 20,
      ),
      label: Text(
        'Cancel',
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Builds the delete button with warning color scheme
  Widget _buildDeleteButton(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton.icon(
      onPressed: () => Navigator.of(context).pop(true),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: theme.colorScheme.error.withOpacity(0.3),
        // Hover and focus effects
      ),
      icon: const Icon(Icons.delete_forever_rounded, size: 20),
      label: const Text(
        'Delete',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
