import 'package:flutter/material.dart';
import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:lottie/lottie.dart';

class DeleteClassDialog extends StatelessWidget {
  final int classId;
  final VoidCallback onClassDeleted;

  const DeleteClassDialog({
    super.key,
    required this.classId,
    required this.onClassDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: primaryColor, size: 30),
          const SizedBox(width: 8),
          Text(
            "Confirm Delete",
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      content: Text(
        "Are you sure you want to delete this class?",
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.cancel, size: 18),
          label: const Text("Cancel"),
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_forever, size: 18),
          onPressed: () => _handleDelete(context),
          label: const Text("Delete"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final loadingStartTime = DateTime.now();
    _showLoading(context);

    try {
      await ClassroomService.deleteClass(classId);

      // Ensure loading shows for at least 2 seconds
      final elapsed = DateTime.now().difference(loadingStartTime);
      final remaining = const Duration(seconds: 2) - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close dialog
        onClassDeleted();
        _showSuccess(context, "Class deleted successfully!");
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        _showError(context, 'Failed to delete class: $e');
      }
    }
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animation/delete.json',
                    width: 100,
                    height: 100,
                  ),
                  Text(
                    "Deleting Class...",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 8,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
