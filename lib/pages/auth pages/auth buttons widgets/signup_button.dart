import 'package:flutter/material.dart';

// SignUpButton is a styled elevated button for sign up actions
class SignUpButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SignUpButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(vertical: 20),
        elevation: 3,
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2.0),
      ),
    );
  }
}
