import 'package:deped_reading_app_laravel/api/supabase_auth_service.dart';
import 'package:deped_reading_app_laravel/pages/admin%20pages/admin_page.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student_page.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/appbar/theme_toggle_button.dart';
import 'auth buttons widgets/login_button.dart';
import 'form fields widgets/password_text_field.dart';
import '../../widgets/navigation/page_transition.dart';
import '../auth pages/student_signup_page.dart';
import '../auth pages/teacher_signup_page.dart';
import '../auth pages/parent_signup_page.dart';
import '../parent pages/parent_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        setState(() {
          _autoValidate = true;
        });
      }
      return;
    }

    _showLoadingDialog("Logging in...");

    try {
      final result = await SupabaseAuthService.login(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );

      Navigator.of(context).pop();
      final userMap = result['user'];
      final role = result['role'] ?? 'student';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('id', userMap['id']);
      await prefs.setString('role', role);

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
      } else {
      }

      await _showSuccessAndProceedDialogs(role);

    } catch (e) {
      Navigator.of(context).pop();
      _showErrorDialog(title: 'Login Failed', message: e.toString());
      debugPrint('Login error: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder:
          (context) => Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animation/loading_rainbow.json',
                    height: 90,
                    width: 90,
                  ),
                  Text(
                    'Logging in...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.surface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _showSuccessAndProceedDialogs(String? role) async {
    await _showSuccessDialog();
    _navigateToDashboard(role);
  }

  Future<void> _showSuccessDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.all(20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Lottie.asset('assets/animation/success.json'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Login Successful!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
    );

    await Future.delayed(const Duration(milliseconds: 2100));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _navigateToDashboard(String? role) async {
    if (!mounted) return;
    debugPrint("Navigating to dashboard for role: $role");

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('id') ?? '';

    if (role == 'student') {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(page: StudentPage()),
          (route) => false,
        );
      }
    } else if (role == 'teacher') {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(page: TeacherPage()),
          (route) => false,
        );
      }
    } else if (role == 'admin') {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(page: AdminPage()),
          (route) => false,
        );
      }
    } else if (role == 'parent') {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(page: ParentDashboardPage(parentId: userId)),
          (route) => false,
        );
      }
    } else {
      debugPrint("No valid role detected.");
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 8.0,
            title: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildHeader(BuildContext context) => Column(
    children: [
      const SizedBox(height: 50),
      CircleAvatar(
        radius: 80,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Icon(
          Icons.person,
          size: 90,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        "Login",
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 80),
    ],
  );

  Widget _buildLoginForm(BuildContext context) => Form(
    key: _formKey,
    autovalidateMode:
        _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          TextFormField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: "Username/Email",
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              filled: true,
              fillColor: const Color.fromARGB(52, 158, 158, 158),
              prefixIcon: Icon(
                Icons.account_circle,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              errorStyle: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Username is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          PasswordTextField(
            labelText: "Password",
            controller: passwordController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Forgot Password?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          LoginButton(text: "Login", onPressed: login),
          const SizedBox(height: 20),
          Divider(height: 10),
          const SizedBox(height: 5),
          Text(
            "or",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 20),
              elevation: 4,
            ),
            icon: Image.asset(
              'assets/icons/graduating-student.png',
              width: 30,
              height: 30,
            ),
            label: const Text(
              "Sign up as Student",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).push(PageTransition(page: StudentSignUpPage()));
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 20),
              elevation: 4,
            ),
            icon: Image.asset(
              'assets/icons/teacher.png',
              width: 30,
              height: 30,
            ),
            label: const Text(
              "Sign up as Teacher",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).push(PageTransition(page: TeacherSignUpPage()));
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 20),
              elevation: 4,
            ),
            icon: const Icon(Icons.family_restroom, size: 30),
            label: const Text(
              "Sign up as Parent",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).push(PageTransition(page: ParentSignUpPage()));
            },
          ),
        ],
      ),
    ),
  );

  Widget _buildBackground(BuildContext context) => Stack(
    children: [
      ColorFiltered(
        colorFilter: ColorFilter.mode(
          Theme.of(context).colorScheme.primary.withOpacity(0.7),
          BlendMode.softLight,
        ),
        child: Opacity(
          opacity: 0.25,
          child: Image.asset(
            'assets/background/480681008_1020230633459316_6070422237958140538_n.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        actions: [
          ThemeToggleButton(iconColor: Theme.of(context).colorScheme.onPrimary),
        ],
      ),
      body: Stack(
        children: [
          _buildBackground(context),
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(child: _buildLoginForm(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
