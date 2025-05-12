import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes/auth_routes.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures plugins are initialized
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
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme.copyWith(
                headlineLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                headlineMedium: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                headlineSmall: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
                bodyLarge: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
                bodyMedium: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
                bodySmall: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.black45,
                ),
              ),
            ),
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
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme.copyWith(
                headlineLarge: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                headlineMedium: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
                headlineSmall: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white60,
                ),
                bodyLarge: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
                bodyMedium: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white60,
                ),
                bodySmall: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          themeMode: currentTheme, // Use the current theme mode
          initialRoute: AuthRoutes.landing, // Initial route for the app
          routes: AuthRoutes.routes, // Define app routes
        );
      },
    );
  }
}