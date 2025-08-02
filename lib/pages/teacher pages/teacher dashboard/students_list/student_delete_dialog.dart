import 'package:flutter/material.dart';

class StudentDeleteDialog extends StatelessWidget {
  const StudentDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
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
        "Are you sure you want to delete this Student?",
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: [
        TextButton.icon(
          icon: Icon(
            Icons.cancel,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: const Text('Cancel'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
          label: const Text(
            'Delete',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}