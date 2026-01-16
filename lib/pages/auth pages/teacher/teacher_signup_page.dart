import 'package:deped_reading_app_laravel/pages/auth%20pages/teacher/teacher_login_page.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import '../../../widgets/appbar/theme_toggle_button.dart';
import '../auth buttons widgets/signup_button.dart';
import '../form fields widgets/password_text_field.dart';
import '../../../widgets/navigation/page_transition.dart';

class TeacherSignUpPage extends StatefulWidget {
  const TeacherSignUpPage({super.key});

  @override
  State<TeacherSignUpPage> createState() => _TeacherSignUpPageState();
}

class _TeacherSignUpPageState extends State<TeacherSignUpPage> {
  final TextEditingController teacherNameController = TextEditingController();
  final TextEditingController teacherPositionController =
      TextEditingController();
  final TextEditingController teacherEmailController = TextEditingController();
  final TextEditingController teacherUsernameController =
      TextEditingController();
  final TextEditingController teacherPasswordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  @override
  void dispose() {
    teacherNameController.dispose();
    teacherPositionController.dispose();
    teacherEmailController.dispose();
    teacherUsernameController.dispose();
    teacherPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerTeacher() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    _showLoadingDialog("Creating your account...");

    try {
      final supabase = Supabase.instance.client;

      final trimmedUsername = teacherUsernameController.text.trim();
      final trimmedPassword = teacherPasswordController.text.trim();

      // ⭐ IMPORTANT: Process email - backend automatically appends @gmail.com
      String trimmedEmail = teacherEmailController.text.trim();

      // ✅ Backend will automatically append @gmail.com if not present
      // Users only need to enter their username
      if (!trimmedEmail.contains('@')) {
        trimmedEmail = '$trimmedEmail@gmail.com';
      } else if (!trimmedEmail.endsWith('@gmail.com')) {
        // If they entered something with @ but not @gmail.com, show error
        Navigator.of(context).pop();
        _handleErrorDialog(
          title: "Email Format Error",
          message:
              "Please enter only your username (without @gmail.com).\nExample: juandelacruz",
        );
        return;
      }

      final trimmedName = teacherNameController.text.trim();
      final trimmedPosition = teacherPositionController.text.trim();

      // 1️⃣ Check if username already exists
      final existingUser =
          await supabase
              .from('users')
              .select('id')
              .eq('username', trimmedUsername)
              .maybeSingle();

      if (existingUser != null) {
        Navigator.of(context).pop();
        _handleErrorDialog(
          title: "Registration Failed",
          message:
              "Username already exists. Please choose a different username.",
        );
        return;
      }

      // 2️⃣ Check if email already exists in teachers table
      final existingEmail =
          await supabase
              .from('teachers')
              .select('id')
              .eq('teacher_email', trimmedEmail)
              .maybeSingle();

      if (existingEmail != null) {
        Navigator.of(context).pop();
        _handleErrorDialog(
          title: "Registration Failed",
          message:
              "This email is already registered. Please use a different username.",
        );
        return;
      }

      // 3️⃣ Create Supabase Auth account
      final authResponse = await supabase.auth.signUp(
        email: trimmedEmail,
        password: trimmedPassword,
        data: {
          "username": trimmedUsername,
          "name": trimmedName,
          "position": trimmedPosition,
        },
      );

      if (authResponse.user == null) {
        Navigator.of(context).pop();
        _handleErrorDialog(
          title: "Registration Failed",
          message: "Unable to create authentication account. Please try again.",
        );
        return;
      }

      final userId = authResponse.user!.id;

      try {
        // 4️⃣ Insert into users table with role='teacher'
        await supabase.from('users').insert({
          'id': userId,
          'username': trimmedUsername,
          'password': trimmedPassword,
          'role': 'teacher',
        });

        // 5️⃣ Insert into teachers table (linked via id foreign key)
        await supabase.from('teachers').insert({
          'id': userId,
          'teacher_name': trimmedName,
          'teacher_email': trimmedEmail,
          'teacher_position': trimmedPosition,
          'account_status': 'pending', // Set to pending by default
        });

        Navigator.of(context).pop();
        // Show login information dialog with credentials
        await _showLoginInformationDialog(
          username: trimmedUsername,
          email: trimmedEmail,
          password: trimmedPassword,
          position: trimmedPosition,
        );
      } catch (insertError) {
        // Rollback: Delete auth user and users record if teacher insert failed
        try {
          await supabase.from('users').delete().eq('id', userId);
          await supabase.auth.admin.deleteUser(userId);
        } catch (rollbackError) {
          debugPrint('⚠️ Rollback error: $rollbackError');
        }
        Navigator.of(context).pop();
        _handleErrorDialog(
          title: "Registration Failed",
          message: "Failed to complete registration. Please try again.",
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      String errorMessage =
          "An error occurred during registration. Please try again.";
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('duplicate') || errorString.contains('unique')) {
        errorMessage =
            "Username or email already exists. Please use different credentials.";
      } else if (errorString.contains('foreign key') ||
          errorString.contains('constraint')) {
        errorMessage = "Invalid data provided. Please check your information.";
      }
      _handleErrorDialog(title: "Error", message: errorMessage);
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

  Future<void> _showLoginInformationDialog({
    required String username,
    required String email,
    required String password,
    required String position,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    "Account Created Successfully!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Account Status Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Account Status: Pending Approval",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Your account needs admin approval before you can login.",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Important Note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Please save your login information for future use",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Information Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Email Information
                        _buildLoginInfoRow(
                          icon: Icons.email,
                          label: "Login Email",
                          value: email,
                          isImportant: true,
                          context: context,
                        ),
                        const SizedBox(height: 16),

                        // Password Information
                        _buildLoginInfoRow(
                          icon: Icons.lock,
                          label: "Password",
                          value: password,
                          isImportant: true,
                          context: context,
                        ),
                        const SizedBox(height: 16),

                        // Username Information
                        _buildLoginInfoRow(
                          icon: Icons.person_outline,
                          label: "Username",
                          value: username,
                          isImportant: false,
                          context: context,
                        ),
                        const SizedBox(height: 20),

                        // Copy Button
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: "Email: $email\nPassword: $password",
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Login information copied to clipboard!",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: Icon(Icons.copy, size: 18),
                          label: Text("Copy Login Info"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Important Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.amber[800],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Important Instructions:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInstructionItem(
                          "1. Your account is pending admin approval",
                          context,
                        ),
                        _buildInstructionItem(
                          "2. Save your login credentials in a secure place",
                          context,
                        ),
                        _buildInstructionItem(
                          "3. Use the email and password above to login after approval",
                          context,
                        ),
                        _buildInstructionItem(
                          "4. You cannot change your email format (@gmail.com is fixed)",
                          context,
                        ),
                        _buildInstructionItem(
                          "5. Contact admin if you need assistance",
                          context,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Proceed Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _proceedToLogin();
                      },
                      icon: Icon(Icons.login, size: 20),
                      label: Text(
                        "Proceed to Login Page",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }


  Widget _buildLoginInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isImportant,
    required BuildContext context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                isImportant
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color:
                isImportant
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isImportant ? Colors.yellow.withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isImportant
                            ? Colors.orange.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        isImportant ? FontWeight.bold : FontWeight.normal,
                    color:
                        isImportant
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[800],
                  ),
                ),
              ),
              if (isImportant) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "Important: Save this information",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[800],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToLogin() async {
    // Show a brief success animation before navigating
    await _showBriefSuccessDialog();
    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(PageTransition(page: const TeacherLoginPage()));
    }
  }

  Future<void> _showBriefSuccessDialog() async {
    // Create a simple success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(25),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 70),
              const SizedBox(height: 15),
              Text(
                "Success!",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Redirecting to Login...",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
        );
      },
    );

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _handleErrorDialog({required String title, required String message}) {
    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 35),
                  const SizedBox(width: 8),
                  Text(title),
                ],
              ),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) => Column(
    children: [
      const SizedBox(height: 40),
      // Instruction banner
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
                    "Important Note",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "@gmail.com is automatically added in the backend.\nJust enter your username!",
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
      const SizedBox(height: 30),
      CircleAvatar(
        radius: 80,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        child: Image.asset('assets/icons/teacher.png', width: 115),
      ),
      const SizedBox(height: 10),
      Text(
        "Teacher Sign Up",
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          "Create your account to start managing your classes",
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

  Widget _buildSignUpForm(BuildContext context) => Form(
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
          _buildTextField(
            controller: teacherNameController,
            label: "Full Name",
            icon: Icons.person,
            hintText: "e.g. Juan Dela Cruz",
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Full Name is required'
                        : null,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: teacherPositionController,
            label: "Position",
            icon: Icons.work,
            hintText: "e.g. English Teacher",
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Position is required'
                        : null,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: teacherUsernameController,
            label: "Username",
            icon: Icons.account_circle,
            hintText: "e.g. juandelacruz",
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Username is required'
                        : null,
          ),
          const SizedBox(height: 20),
          // Enhanced Email field with backend auto-append instructions
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: teacherEmailController,
                keyboardType: TextInputType.text, // Changed from email to text
                decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "Enter your username (no @gmail.com needed)",
                  prefixIcon: Icon(
                    Icons.email,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(52, 158, 158, 158),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email username is required';
                  }

                  String input = value.trim();
                  if (input.contains('@')) {
                    if (input.endsWith('@gmail.com')) {
                      return 'Do not include @gmail.com. Just enter your username.';
                    }
                    return 'Just enter your username. "@gmail.com" is added automatically.';
                  }

                  // Check for valid username format (no spaces, special chars except underscore)
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(input)) {
                    return 'Username can only contain letters, numbers, and underscores';
                  }

                  return null;
                },
              ),
              // Helper text explaining the backend auto-append
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "@gmail.com will be automatically added by the system",
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PasswordTextField(
            labelText: "Password",
            controller: teacherPasswordController,
            hintText: "At least 6 characters",
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Password is required'
                        : null,
          ),
          const SizedBox(height: 20),
          PasswordTextField(
            labelText: "Confirm Password",
            controller: confirmPasswordController,
            hintText: "Re-enter your password",
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Confirm Password is required';
              }
              if (value != teacherPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          // Email format explanation box
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "How it works:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "You enter: juandelacruz\nSystem saves: juandelacruz@gmail.com",
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SignUpButton(text: "Sign Up", onPressed: registerTeacher),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account?",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).push(PageTransition(page: const TeacherLoginPage()));
                },
                child: Text(
                  "Log In",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        filled: true,
        fillColor: const Color.fromARGB(52, 158, 158, 158),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }

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
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [_buildHeader(context), _buildSignUpForm(context)],
            ),
          ),
        ],
      ),
    );
  }
}
