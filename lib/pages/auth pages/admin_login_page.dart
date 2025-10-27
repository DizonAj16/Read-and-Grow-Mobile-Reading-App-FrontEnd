import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/appbar/theme_toggle_button.dart';
import '../../widgets/navigation/page_transition.dart';
import '../student pages/student_dashboard_page.dart';
import '../parent pages/parent_dashboard_page.dart';
import 'auth buttons widgets/login_button.dart';
import 'form fields widgets/password_text_field.dart';
import 'form fields widgets/email_text_field.dart';
import '../admin pages/admin_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  final supabase = Supabase.instance.client;

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/animation/loading2.json', width: 75, height: 75, repeat: true),
              const SizedBox(height: 24),
              Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSuccessDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 35),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text('Login successful!'),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showProceedingDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/animation/loading2.json', width: 75, height: 75),
              const SizedBox(height: 24),
              Text(
                "Proceeding to Admin Dashboard...",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 35),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  Future<void> _handleLogin() async {
    if (!mounted) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    _showLoadingDialog("Logging in...");

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.session != null && response.user != null) {
        final userId = response.user!.id;
        final roleRes = await supabase
            .from('users')
            .select('role')
            .eq('id', userId)
            .maybeSingle();

        final role = roleRes?['role'] ?? 'student';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', userId);
        await prefs.setString('role', role);

        if (!mounted) return;
        Navigator.of(context).pop();
        await _showSuccessDialog();

        if (role == 'parent') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => ParentDashboardPage(parentId: userId),
            ),
            (route) => false,
          );
        }
        else if (role == 'admin') {
          await _showProceedingDialog();
          Navigator.of(context).pushAndRemoveUntil(
            PageTransition(page: const AdminPage()),
                (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const StudentDashboardPage()),
                (route) => false,
          );
        }
      } else {
        Navigator.of(context).pop();
        _showErrorDialog(title: 'Login Failed', message: "Invalid credentials");
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(title: 'Error', message: e.toString());
      }
    }
  }


  Widget _buildHeader(BuildContext context) => Column(
    children: [
      const SizedBox(height: 50),
      CircleAvatar(
        radius: 80,
        backgroundColor: Colors.white,
        child: Icon(Icons.admin_panel_settings,
            size: 90, color: Theme.of(context).colorScheme.primary),
      ),
      const SizedBox(height: 5),
      Text("Admin Login",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
      const SizedBox(height: 80),
    ],
  );

  Widget _buildBackground(BuildContext context) => Container(
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
  );

  Widget _buildLoginForm(BuildContext context) => Form(
    key: _formKey,
    autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
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
          EmailTextField(
            labelText: "Admin Email",
            controller: _emailController,
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Email is required' : null,
          ),
          const SizedBox(height: 20),
          PasswordTextField(
            labelText: "Password",
            controller: _passwordController,
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Password is required' : null,
          ),
          const SizedBox(height: 20),
          LoginButton(text: "Login", onPressed: _handleLogin),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [ThemeToggleButton(iconColor: Colors.white)],
      ),
      body: Stack(
        children: [
          _buildBackground(context),
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
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
