import 'package:flutter/material.dart';

/// Success dialog widget.

class SuccessDialog extends StatelessWidget {
  final String message;
  const SuccessDialog({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 35),
          SizedBox(width: 8),
          const Text('Success'),
        ],
      ),
      content: Text(message),
    );
  }
}
