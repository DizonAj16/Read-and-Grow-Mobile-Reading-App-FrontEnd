import 'package:flutter/material.dart';

// LoginButton is a styled elevated button for login/sign up actions
class LoginButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  // Button for login or sign up actions
  const LoginButton({
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
      // Button label with bold styling
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2.0),
      ),
    );
  }
}
