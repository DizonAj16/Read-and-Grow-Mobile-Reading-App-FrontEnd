import 'package:flutter/material.dart';

class AppTextTheme {
  static TextTheme textTheme(BuildContext context) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onBackground,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
      ),
    );
  }
}
