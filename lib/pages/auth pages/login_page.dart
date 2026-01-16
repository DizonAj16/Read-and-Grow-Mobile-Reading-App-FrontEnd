import 'package:deped_reading_app_laravel/api/supabase_auth_service.dart';
import 'package:deped_reading_app_laravel/pages/admin%20pages/admin_page.dart';
import 'package:deped_reading_app_laravel/pages/auth%20pages/auth%20buttons%20widgets/login_button.dart';
import 'package:deped_reading_app_laravel/pages/auth%20pages/form%20fields%20widgets/password_text_field.dart';
import 'package:deped_reading_app_laravel/pages/auth%20pages/parent/parent_signup_page.dart';
import 'package:deped_reading_app_laravel/pages/auth%20pages/student/student_signup_page.dart';
import 'package:deped_reading_app_laravel/pages/auth%20pages/teacher/teacher_signup_page.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student_page.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher_page.dart';
import 'package:deped_reading_app_laravel/pages/parent%20pages/parent_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/appbar/theme_toggle_button.dart';
import '../../widgets/navigation/page_transition.dart';


enum LoginType {
  universal,
  student,
  teacher,
  parent,
  admin,
}

class LoginPage extends StatefulWidget {
  final LoginType loginType;
  
  const LoginPage({
    super.key,
    this.loginType = LoginType.universal,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  // Role-specific configurations
  final Map<LoginType, Map<String, dynamic>> _roleConfigs = {
    LoginType.universal: {
      'title': 'Login',
      'subtitle': 'Sign in to your account',
      'icon': Icons.login,
      'iconAsset': null,
      'iconSize': 90,
      'backgroundColor': Colors.blue,
      'inputLabel': 'Username or Email',
      'inputHint': 'Enter username or email',
      'inputIcon': Icons.account_circle,
      'validationMessage': 'Username or email is required',
      'showSignupButtons': true,
      'acceptedFormats': ['username', 'username@student.app', 'username@gmail.com', 'username@parent.app'],
    },
    LoginType.student: {
      'title': 'Student Login',
      'subtitle': 'Welcome back! Sign in to continue your reading journey',
      'icon': Icons.school,
      'iconAsset': 'assets/icons/graduating-student.png',
      'iconSize': 120,
      'backgroundColor': Colors.blue,
      'inputLabel': 'Username or Email',
      'inputHint': 'username OR username@student.app',
      'inputIcon': Icons.account_circle,
      'validationMessage': 'Username or email is required',
      'showSignupButtons': true,
      'acceptedFormats': ['username', 'username@student.app'],
    },
    LoginType.teacher: {
      'title': 'Teacher Login',
      'subtitle': 'Welcome back! Sign in to manage your classes and students',
      'icon': Icons.person,
      'iconAsset': 'assets/icons/teacher.png',
      'iconSize': 120,
      'backgroundColor': Colors.green,
      'inputLabel': 'Email Address',
      'inputHint': 'username@gmail.com',
      'inputIcon': Icons.email,
      'validationMessage': 'Email is required',
      'showSignupButtons': true,
      'acceptedFormats': ['username@gmail.com'],
    },
    LoginType.parent: {
      'title': 'Parent Login',
      'subtitle': "Sign in to monitor your child's reading progress",
      'icon': Icons.family_restroom,
      'iconAsset': null,
      'iconSize': 90,
      'backgroundColor': Colors.purple,
      'inputLabel': 'Email',
      'inputHint': 'username@parent.app',
      'inputIcon': Icons.email,
      'validationMessage': 'Email is required',
      'showSignupButtons': false,
      'acceptedFormats': ['username@parent.app'],
    },
    LoginType.admin: {
      'title': 'Admin Login',
      'subtitle': 'Welcome back! Sign in to manage the system',
      'icon': Icons.admin_panel_settings,
      'iconAsset': null,
      'iconSize': 90,
      'backgroundColor': Colors.red,
      'inputLabel': 'Admin Email',
      'inputHint': 'Enter admin email address',
      'inputIcon': Icons.email,
      'validationMessage': 'Email is required',
      'showSignupButtons': false,
      'acceptedFormats': ['email@domain.com'],
    },
  };

  Map<String, dynamic> get _config => _roleConfigs[widget.loginType] ?? _roleConfigs[LoginType.universal]!;

  String? _inputValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _config['validationMessage'];
    }
    
    final input = value.trim();
    
    // Special validation for teacher login
    if (widget.loginType == LoginType.teacher) {
      if (!input.contains('@')) {
        return 'Please enter a valid email address';
      }
      if (!input.endsWith('@gmail.com')) {
        return 'Email should end with @gmail.com';
      }
    }
    
    // Special validation for parent login
    if (widget.loginType == LoginType.parent) {
      if (!input.contains('@')) {
        return 'Include "@parent.app" after your username';
      }
      if (!input.endsWith('@parent.app')) {
        return 'Email should end with @parent.app';
      }
    }
    
    // Special validation for admin login
    if (widget.loginType == LoginType.admin) {
      if (!input.contains('@')) {
        return 'Please enter a valid email address';
      }
    }
    
    return null;
  }

  Future<void> _login() async {
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
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      Navigator.of(context).pop();
      final userMap = result['user'];
      final role = result['role'] ?? 'student';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('id', userMap['id']);
      await prefs.setString('role', role);

      await _showSuccessAndProceedDialogs(role);

    } catch (e) {
      Navigator.of(context).pop();
      final errorMessage = e.toString();
      
      // Check if it's an approval-related error
      if (errorMessage.contains('pending approval')) {
        _showErrorDialog(
          title: 'Account Pending Approval',
          message: 'Your teacher account is pending approval from an administrator. Please contact your administrator to approve your account before you can log in.',
        );
      } else if (errorMessage.contains('deactivated') || errorMessage.contains('inactive')) {
        _showErrorDialog(
          title: 'Account Deactivated',
          message: 'Your teacher account has been deactivated. Please contact an administrator for assistance.',
        );
      } else if (errorMessage.contains('not active')) {
        _showErrorDialog(
          title: 'Account Not Active',
          message: 'Your teacher account is not active. Please contact an administrator for assistance.',
        );
      } else {
        _showErrorDialog(
          title: 'Login Failed',
          message: errorMessage.replaceAll('Exception: ', '').replaceAll('Exception', ''),
        );
      }
      debugPrint('Login error: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                message,
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
      builder: (context) => AlertDialog(
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

    await Future.delayed(const Duration(milliseconds: 2000));
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
          PageTransition(page: const StudentPage()),
          (route) => false,
        );
      }
    } else if (role == 'teacher') {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(page: const TeacherPage()),
          (route) => false,
        );
      }
    } else if (role == 'admin') {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(page: const AdminPage()),
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
      builder: (context) => AlertDialog(
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
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

  Widget _buildHeader(BuildContext context) {
    final config = _config;
    
    return Column(
      children: [
        const SizedBox(height: 40),
        
        // Instruction banner (show only for specific login types)
        if (widget.loginType != LoginType.universal && widget.loginType != LoginType.admin)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Login Instruction",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getInstructionText(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        
        SizedBox(height: widget.loginType != LoginType.universal && widget.loginType != LoginType.admin ? 30 : 50),
        
        // Icon/Image
        CircleAvatar(
          radius: 80,
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          child: config['iconAsset'] != null
              ? Image.asset(
                  config['iconAsset'],
                  width: config['iconSize']?.toDouble(),
                  height: config['iconSize']?.toDouble(),
                  fit: BoxFit.contain,
                )
              : Icon(
                  config['icon'],
                  size: config['iconSize']?.toDouble(),
                  color: Theme.of(context).colorScheme.primary,
                ),
        ),
        
        const SizedBox(height: 10),
        
        // Title
        Text(
          config['title'],
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            config['subtitle'],
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 60),
      ],
    );
  }

  String _getInstructionText() {
    switch (widget.loginType) {
      case LoginType.student:
        return "Enter username OR username@student.app";
      case LoginType.teacher:
        return "Use your email address format:\nusername@gmail.com";
      case LoginType.parent:
        return "Use your username with '@parent.app'\ne.g. juandelacruz@parent.app";
      default:
        return "";
    }
  }

  Widget _buildLoginForm(BuildContext context) {
    final config = _config;
    
    return Form(
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
            
            // Username/Email field
            TextFormField(
              controller: _usernameController,
              keyboardType: widget.loginType == LoginType.teacher || 
                          widget.loginType == LoginType.parent || 
                          widget.loginType == LoginType.admin
                  ? TextInputType.emailAddress
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: config['inputLabel'],
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                filled: true,
                fillColor: const Color.fromARGB(52, 158, 158, 158),
                prefixIcon: Icon(
                  config['inputIcon'],
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                errorStyle: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                hintText: config['inputHint'],
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
              validator: _inputValidator,
            ),
            
            // Helper text
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 12),
              child: Text(
                _getHelperText(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Password field
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
            
            const SizedBox(height: 10),
            
            // Forgot password (placeholder)
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
            
            // Login button
            LoginButton(text: "Login", onPressed: _login),
            
            // Signup section (only for universal, student, and teacher)
            if (config['showSignupButtons'] == true) ...[
              const SizedBox(height: 20),
              const Divider(
                height: 10,
                color: Colors.grey,
              ),
              const SizedBox(height: 5),
              const Text(
                "or",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              
              // Instruction
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: const Text(
                  "Don't have an account? Sign up below based on your role:",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Student signup button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  elevation: 4,
                ),
                icon: Image.asset(
                  'assets/icons/graduating-student.png',
                  width: 30,
                  height: 30,
                ),
                label: const Text(
                  "Sign up as Student",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    PageTransition(page: const StudentSignUpPage()),
                  );
                },
              ),
              
              const SizedBox(height: 10),
              
              // Teacher signup button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  elevation: 4,
                ),
                icon: Image.asset(
                  'assets/icons/teacher.png',
                  width: 30,
                  height: 30,
                ),
                label: const Text(
                  "Sign up as Teacher",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    PageTransition(page: const TeacherSignUpPage()),
                  );
                },
              ),
              
              const SizedBox(height: 10),
              
              // Parent signup button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  elevation: 4,
                ),
                icon: const Icon(Icons.family_restroom, size: 28),
                label: const Text(
                  "Sign up as Parent",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    PageTransition(page: const ParentSignUpPage()),
                  );
                },
              ),
            ],
            
            // Additional help text
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getHelpTitle(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getHelpText(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHelperText() {
    switch (widget.loginType) {
      case LoginType.student:
        return "Accepted formats: username OR username@student.app";
      case LoginType.teacher:
        return "Format: username@gmail.com";
      case LoginType.parent:
        return "Format: username@parent.app";
      case LoginType.admin:
        return "Enter your admin email address";
      default:
        return "Enter your username or email";
    }
  }

  String _getHelpTitle() {
    switch (widget.loginType) {
      case LoginType.student:
        return "Need help logging in?";
      case LoginType.teacher:
        return "Example: juandelacruz@gmail.com";
      case LoginType.parent:
        return "Need help?";
      case LoginType.admin:
        return "Security Note:";
      default:
        return "Need help logging in?";
    }
  }

  String _getHelpText() {
    switch (widget.loginType) {
      case LoginType.student:
        return "• Try username only (e.g., juandelacruz)\n• OR add @student.app (e.g., juandelacruz@student.app)";
      case LoginType.teacher:
        return "Contact your administrator if you forgot your email.";
      case LoginType.parent:
        return "Contact your school administrator for login credentials.";
      case LoginType.admin:
        return "Admin access is restricted to authorized personnel only.";
      default:
        return "Try username or email format based on your role.";
    }
  }

  Widget _buildBackground(BuildContext context) {
    return Stack(
      children: [
        // Background image (only for universal, student, teacher)
        if (widget.loginType == LoginType.universal || 
            widget.loginType == LoginType.student || 
            widget.loginType == LoginType.teacher)
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
        
        // Gradient overlay
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
  }

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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}