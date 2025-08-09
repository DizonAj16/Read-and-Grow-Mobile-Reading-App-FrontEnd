import 'package:deped_reading_app_laravel/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/auth pages/set_base_url_page.dart';
import 'pages/auth pages/landing_page.dart';

ThemeData buildLightTheme(BuildContext context) {
  return ThemeData.light().copyWith(
    colorScheme: ColorScheme.light(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
      surface: kLightSurfaceColor,
      background: kLightBackgroundColor,
      onPrimary: kLightOnPrimary,
      onSecondary: kLightOnSecondary,
      onSurface: kLightOnSurface,
      onBackground: kLightOnBackground,
      error: kPrimaryColor,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme.copyWith(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: kHeadlineMediumColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: kHeadlineSmallColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: kLightOnBackground,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: kHeadlineSmallColor,
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: kHeadlineMediumColor,
        ),
      ),
    ),
  );
}

ThemeData buildDarkTheme(BuildContext context) {
  return ThemeData.dark().copyWith(
    colorScheme: ColorScheme.dark(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
      surface: kDarkSurfaceColor,
      background: kDarkBackgroundColor,
      onPrimary: kDarkOnPrimary,
      onSecondary: kDarkOnSecondary,
      onSurface: kDarkOnSurface,
      onBackground: kDarkOnBackground,
      error: kPrimaryColor,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme.copyWith(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: kSecondaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: kPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: kHeadlineSmallColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: kDarkOnBackground,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: kHeadlineMediumColor,
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: kSecondaryColor,
        ),
      ),
    ),
  );
}

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('base_url');
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
