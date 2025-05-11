import 'package:flutter/material.dart';
import '../main.dart';

class ThemeToggleButton extends StatelessWidget {
  final Color? iconColor;

  const ThemeToggleButton({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        themeNotifier.value == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
        color: iconColor ?? Theme.of(context).iconTheme.color,
      ),
      onPressed: () {
        themeNotifier.value = themeNotifier.value == ThemeMode.light
            ? ThemeMode.dark
            : ThemeMode.light;
      },
    );
  }
}
