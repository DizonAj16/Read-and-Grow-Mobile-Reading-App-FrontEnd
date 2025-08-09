import 'package:deped_reading_app_laravel/api/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../widgets/appbar/theme_toggle_button.dart';
import 'auth buttons widgets/login_button.dart';
import 'form fields widgets/password_text_field.dart';
import 'form fields widgets/email_text_field.dart';
import '../admin pages/admin_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/navigation/page_transition.dart';

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

  /// Shows a loading dialog with a custom message.
  /// Used during async operations like login.
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Replace CircularProgressIndicator with Lottie
                  Lottie.asset(
                    'assets/animation/loading2.json',
                    width: 75,
                    height: 75,
                    repeat: true,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// Shows a success dialog for login.
  /// Waits for a few seconds before closing.
  Future<void> _showSuccessDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 35),
                SizedBox(width: 8),
                const Text('Success'),
              ],
            ),
            content: const Text('Login successful!'),
          ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  /// Shows a dialog indicating the user is being redirected to the admin dashboard.
  /// Waits for a few seconds before closing.
  Future<void> _showProceedingDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔁 Replace the loader with your Lottie animation
                  Lottie.asset(
                    'assets/animation/loading2.json', // Adjust this to your actual path
                    width: 75,
                    height: 75,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Proceeding to Admin Dashboard...",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  /// Shows an error dialog with a title and message.
  /// Used for displaying validation, login, or storage errors.
  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 35),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  /// Handles the admin login process:
  /// - Validates the form.
  /// - Shows a loading dialog.
  /// - Calls the API for login.
  /// - Handles response, including two-step security code if required.
  /// - Stores token/role and navigates to dashboard on success.
  /// - Shows appropriate dialogs for errors or success.
  Future<void> _handleLogin() async {
    if (!mounted) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      setState(() {
        _autoValidate = true;
      });
      return;
    }

    _showLoadingDialog("Logging in...");

    try {
      final response = await AuthService.adminLogin({
        'login': _emailController.text.trim(),
        'password': _passwordController.text,
        'admin_security_code': '', // Step 1: no code yet
      });

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (response['step'] == 2) {
        await _showSecurityCodeDialog(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else if (response['success'] == true) {
        try {
          final prefs = await SharedPreferences.getInstance();
          if (response['token'] != null)
            await prefs.setString('token', response['token'].toString());
          await prefs.setString('role', 'admin');
        } catch (_) {}
        await _showSuccessDialog();
        await _showProceedingDialog();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(page: AdminPage()),
          (route) => false,
        );
      } else {
        _showErrorDialog(
          title: 'Login Failed',
          message: response['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog if open
        _showErrorDialog(
          title: 'Error',
          message: 'An error occurred. Please try again.',
        );
      }
    }
  }

  /// Shows a dialog for entering the admin security code (step 2 of login).
  /// Handles verification and navigation on success.
  Future<void> _showSecurityCodeDialog(String email, String password) async {
    final TextEditingController _codeController = TextEditingController();
    String? dialogError;
    bool dialogLoading = false;

    final rootContext = context;

    await showDialog(
      context: rootContext,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: const Text("Admin Security Code"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: "Security Code",
                      ),
                      obscureText: true,
                    ),
                    if (dialogError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (dialogLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed:
                        dialogLoading ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed:
                        dialogLoading
                            ? null
                            : () async {
                              setState(() => dialogLoading = true);
                              final response = await AuthService.adminLogin({
                                'login': email,
                                'password': password,
                                'admin_security_code': _codeController.text,
                              });
                              setState(() => dialogLoading = false);
                              if (response['success'] == true) {
                                try {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  if (response['token'] != null)
                                    await prefs.setString(
                                      'token',
                                      response['token'].toString(),
                                    );
                                  await prefs.setString('role', 'admin');
                                } catch (_) {}
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context); // Close dialog safely
                                }
                                await _showSuccessDialog();
                                await _showProceedingDialog();
                                if (!mounted) return;
                                Navigator.of(rootContext).pushAndRemoveUntil(
                                  PageTransition(page: AdminPage()),
                                  (route) => false,
                                );
                              } else {
                                setState(
                                  () =>
                                      dialogError =
                                          response['message'] ?? "Login failed",
                                );
                              }
                            },
                    child: const Text("Verify"),
                  ),
                ],
              ),
        );
      },
    );
  }

  /// Builds the header section with avatar and title for the admin login page.
  Widget _buildHeader(BuildContext context) => Column(
    children: [
      const SizedBox(height: 50),
      CircleAvatar(
        radius: 80,
        backgroundColor: Colors.white,
        child: Icon(
          Icons.admin_panel_settings,
          size: 90,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        "Admin Login",
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 80),
    ],
  );

  /// Builds the background with a gradient overlay.
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

  /// Builds the login form with email/username, password, and login button.
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
          EmailTextField(
            labelText: "Admin Email/Username",
            controller: _emailController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          PasswordTextField(
            labelText: "Password",
            controller: _passwordController,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          LoginButton(text: "Login", onPressed: _handleLogin),
        ],
      ),
    ),
  );

  /// Main build method for the admin login page.
  /// Assembles the app bar, background, header, and login form.
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
