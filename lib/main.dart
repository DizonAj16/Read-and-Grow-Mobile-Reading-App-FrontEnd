import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes/app_routes.dart';
import 'pages/auth pages/set_base_url_page.dart';
import 'pages/auth pages/landing_page.dart';

ThemeData buildLightTheme(BuildContext context) {
  return ThemeData.light().copyWith(
    colorScheme: ColorScheme.light(
      primary: const Color(0xFFE53935),
      secondary: const Color(0xFFFFD600),
      surface: const Color(0xFFFFFFFF),
      background: const Color(0xFFFFFFFF),
      onPrimary: const Color(0xFFFFFFFF),
      onSecondary: const Color(0xFF000000),
      onSurface: const Color(0xFF000000),
      onBackground: const Color(0xFF000000),
      error: const Color(0xFFE53935),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE53935),
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1976D2),
        ),
        headlineSmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: Color(0xFF388E3C),
        ),
        bodyLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: Color(0xFF000000),
        ),
        bodyMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF388E3C),
        ),
        bodySmall: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: Color(0xFF1976D2),
        ),
      ),
    ),
  );
}

ThemeData buildDarkTheme(BuildContext context) {
  return ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFFE53935),
      secondary: const Color(0xFFFFD600),
      surface: const Color(0xFF222222),
      background: const Color(0xFF121212),
      onPrimary: const Color(0xFFFFFFFF),
      onSecondary: const Color(0xFF000000),
      onSurface: const Color(0xFFFFFFFF),
      onBackground: const Color(0xFFFFFFFF),
      error: const Color(0xFFE53935),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme.copyWith(
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFFFFD600),
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE53935),
        ),
        headlineSmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: Color(0xFF388E3C),
        ),
        bodyLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: Color(0xFFFFFFFF),
        ),
        bodyMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFF1976D2),
        ),
        bodySmall: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: Color(0xFFFFD600),
        ),
      ),
    ),
  );
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('base_url'); // Clear previous base_url on every app start
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _hasBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('base_url') != null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(context),
          darkTheme: buildDarkTheme(context),
          themeMode: currentTheme,
          routes: AppRoutes.routes,
          home: FutureBuilder<bool>(
            future: _hasBaseUrl(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.data == true) {
                return const LandingPage();
              } else {
                return const SetBaseUrlPage();
              }
            },
          ),
        );
      },
    );
  }
}