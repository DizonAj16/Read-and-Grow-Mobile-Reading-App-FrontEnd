import 'package:flutter/material.dart';
import 'routes/auth_routes.dart';
import 'theme/text_theme.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          // Light theme configuration
          theme: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF2575FC), 
              secondary: Color(0xFF6A11CB), 
              surface: Colors.white, 
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
            textTheme: AppTextTheme.textTheme(context),
          ),
          // Dark theme configuration
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFF1E3A8A), 
              secondary: Color(0xFF8E24AA), 
              surface: Color(0xFF121212), 
              onPrimary: Colors.black, 
              onSurface: Colors.white, 
            ),
            textTheme: AppTextTheme.textTheme(context),
          ),
          themeMode: currentTheme, // Use the current theme mode
          initialRoute: AuthRoutes.landing, // Initial route for the app
          routes: AuthRoutes.routes, // Define app routes
        );
      },
    );
  }
}