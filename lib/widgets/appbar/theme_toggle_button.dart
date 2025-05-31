import 'package:flutter/material.dart';
// Import the theme notifier from main.dart for theme switching
import '../../main.dart';

// ThemeToggleButton toggles between light and dark mode for the app
class ThemeToggleButton extends StatelessWidget {
  final Color? iconColor;

  const ThemeToggleButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      // Icon changes based on current theme mode
      icon: Icon(
        themeNotifier.value == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
        color: iconColor ?? Theme.of(context).iconTheme.color,
      ),
      onPressed: () {
        // Toggle theme mode on press
        themeNotifier.value = themeNotifier.value == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light;
      },
    );
  }
}
