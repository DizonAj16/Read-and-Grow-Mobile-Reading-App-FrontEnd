import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routes/auth_routes.dart';

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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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
          theme: buildLightTheme(context),
          darkTheme: buildDarkTheme(context),
          themeMode: currentTheme,
          initialRoute: AuthRoutes.landing,
          routes: AuthRoutes.routes,
        );
      },
    );
  }
}