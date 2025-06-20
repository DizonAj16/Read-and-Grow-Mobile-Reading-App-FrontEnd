import 'package:flutter/material.dart';

/// Error dialog widget.

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  const ErrorDialog({super.key, required this.title, required this.message});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error, color: Colors.red, size: 35),
          SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
