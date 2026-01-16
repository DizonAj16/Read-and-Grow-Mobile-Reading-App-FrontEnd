import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../widgets/appbar/theme_toggle_button.dart';
import '../auth buttons widgets/signup_button.dart';
import '../form fields widgets/password_text_field.dart';
import '../../../widgets/navigation/page_transition.dart';
import 'student_login_page.dart';

class StudentSignUpPage extends StatefulWidget {
  const StudentSignUpPage({super.key});

  @override
  State<StudentSignUpPage> createState() => _StudentSignUpPageState();
}

class _StudentSignUpPageState extends State<StudentSignUpPage> {
  final TextEditingController studentNameController = TextEditingController();
  final TextEditingController studentLRNController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();
  final TextEditingController studentUsernameController =
      TextEditingController();
  final TextEditingController studentPasswordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;

  final List<String> _grades = ['1', '2', '3', '4', '5'];

  // Store the Not Set reading level ID
  String? _notSetReadingLevelId;

  @override
  void initState() {
    super.initState();
    // Fetch the Not Set reading level ID on initialization
    _fetchNotSetReadingLevelId();
  }

  Future<void> _fetchNotSetReadingLevelId() async {
    try {
      final supabase = Supabase.instance.client;

      // Query the reading_levels table for level 0 (Not Set)
      final result =
          await supabase
              .from('reading_levels')
              .select('id')
              .eq('level_number', 0)
              .maybeSingle();

      if (result != null) {
        setState(() {
          _notSetReadingLevelId = result['id'] as String;
        });
        debugPrint('📚 Found Not Set reading level ID: $_notSetReadingLevelId');
      } else {
        debugPrint('⚠️ Could not find Not Set reading level (level 0)');
      }
    } catch (e) {
      debugPrint('❌ Error fetching reading level ID: $e');
    }
  }

  @override
  void dispose() {
    studentNameController.dispose();
    studentLRNController.dispose();
    sectionController.dispose();
    gradeController.dispose();
    studentUsernameController.dispose();
    studentPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> registerStudent() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    _showLoadingDialog("Creating your account...");

    try {
      final supabase = Supabase.instance.client;

      final trimmedUsername = studentUsernameController.text.trim();
      final trimmedPassword = studentPasswordController.text.trim();
      final trimmedName = studentNameController.text.trim();
      final trimmedLRN = studentLRNController.text.trim();
      final trimmedGrade = gradeController.text.trim();
      final trimmedSection = sectionController.text.trim();

      // ✅ IMPORTANT: @student.app is automatically appended in the backend
      // Students only need to enter their username
      final authEmail = "$trimmedUsername@student.app";

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

      // 2️⃣ Check if LRN already exists
      final existingLRN =
          await supabase
              .from('students')
              .select('id')
              .eq('student_lrn', trimmedLRN)
              .maybeSingle();

      if (existingLRN != null) {
        Navigator.of(context).pop();
        _handleErrorDialog(
          title: "Registration Failed",
          message: "LRN already registered. Please use a different LRN.",
        );
        return;
      }

      // 3️⃣ Create Supabase Auth account (using username-based email format)
      final authResponse = await supabase.auth.signUp(
        email: authEmail,
        password: trimmedPassword,
        data: {"username": trimmedUsername, "name": trimmedName},
      );

      if (authResponse.user == null) {
        Navigator.of(context).pop();
        _handleErrorDialog(
          title: "Registration Failed",
          message: "Could not create authentication account. Please try again.",
        );
        return;
      }

      final userId = authResponse.user!.id;

      try {
        // 4️⃣ Insert into users table with role='student'
        await supabase.from('users').insert({
          'id': userId,
          'username': trimmedUsername,
          'password': trimmedPassword,
          'role': 'student',
        });

        // 5️⃣ Insert into students table with Not Set reading level
        // If we couldn't fetch the reading level ID, we'll still create the student
        // The database constraint will handle the foreign key or allow null
        final studentData = {
          'id': userId,
          'username': trimmedUsername,
          'student_name': trimmedName,
          'student_lrn': trimmedLRN,
          'student_grade': trimmedGrade.isNotEmpty ? trimmedGrade : null,
          'student_section': trimmedSection.isNotEmpty ? trimmedSection : null,
          'reading_level_updated_at': DateTime.now().toIso8601String(),
        };

        // Add reading level ID if available
        if (_notSetReadingLevelId != null &&
            _notSetReadingLevelId!.isNotEmpty) {
          studentData['current_reading_level_id'] = _notSetReadingLevelId;
          debugPrint(
            '✅ Setting reading level to Not Set (ID: $_notSetReadingLevelId)',
          );
        } else {
          debugPrint('⚠️ No reading level ID available, leaving as null');
        }

        await supabase.from('students').insert(studentData);

        // Debug: Verify the student was created with correct reading level
        if (_notSetReadingLevelId != null) {
          final verifyResult =
              await supabase
                  .from('students')
                  .select('current_reading_level_id')
                  .eq('id', userId)
                  .maybeSingle();

          if (verifyResult != null) {
            final readingLevelId = verifyResult['current_reading_level_id'];
            debugPrint('✅ Verified student reading level ID: $readingLevelId');
          }
        }

        if (mounted) {
          Navigator.of(context).pop();
          // Show login information dialog first
          await _showLoginInformationDialog(
            username: trimmedUsername,
            email: authEmail,
            password: trimmedPassword,
          );
        }
      } catch (insertError) {
        debugPrint('❌ Error inserting student data: $insertError');

        // Rollback: Delete auth user and users record if student insert failed
        try {
          await supabase.from('users').delete().eq('id', userId);
          await supabase.auth.admin.deleteUser(userId);
        } catch (rollbackError) {
          debugPrint('⚠️ Rollback error: $rollbackError');
        }

        if (mounted) {
          Navigator.of(context).pop();
          _handleErrorDialog(
            title: "Registration Failed",
            message: "Failed to complete registration. Please try again.",
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop();
      String errorMessage =
          "An error occurred during registration. Please try again.";
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('duplicate') || errorString.contains('unique')) {
        errorMessage =
            "Username or LRN already exists. Please use different credentials.";
      } else if (errorString.contains('foreign key') ||
          errorString.contains('constraint')) {
        errorMessage = "Invalid data provided. Please check your information.";
      } else if (errorString.contains('reading_level')) {
        errorMessage =
            "There was an issue setting your reading level. Please contact support.";
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
                  if (_notSetReadingLevelId == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Setting up reading level...",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.8),
                      ),
                    ),
                  ],
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
                          icon: Icons.person,
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

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Important Instructions:",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInstructionItem(
                          "1. Use the email and password above to log in",
                          context,
                        ),
                        _buildInstructionItem(
                          "2. You cannot change your email format (@student.app is fixed)",
                          context,
                        ),
                        _buildInstructionItem(
                          "3. Save this information in a secure place",
                          context,
                        ),
                        _buildInstructionItem(
                          "4. Contact your teacher if you forget your password",
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
                        "Proceed to Login",
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
          padding: const EdgeInsets.all(6),
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
      ).pushReplacement(PageTransition(page: const StudentLoginPage()));
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
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 30),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildHeader(BuildContext context) => Column(
    children: [
      const SizedBox(height: 40),
      // Instruction banner for @student.app
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
                    "@student.app is automatically added in the backend.\nJust enter your username for login!",
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
        child: Image.asset('assets/icons/graduating-student.png', width: 115),
      ),
      const SizedBox(height: 10),
      Text(
        "Student Sign Up",
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
          "Create your account to start your reading journey",
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
            controller: studentNameController,
            label: "Full Name",
            icon: Icons.person,
            hintText: "e.g. Maria Santos",
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Full Name is required'
                        : null,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: studentLRNController,
            label: "LRN",
            icon: Icons.confirmation_number,
            hintText: "e.g. 123456789012",
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'LRN is required';
              }
              if (!RegExp(r'^\d{12}$').hasMatch(value.trim())) {
                return 'LRN must be exactly 12 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value:
                gradeController.text.isNotEmpty ? gradeController.text : null,
            items:
                _grades
                    .map(
                      (grade) => DropdownMenuItem(
                        value: grade,
                        child: Text("Grade $grade"),
                      ),
                    )
                    .toList(),
            onChanged: (value) {
              setState(() => gradeController.text = value ?? '');
            },
            validator:
                (value) =>
                    value == null || value.isEmpty ? 'Grade is required' : null,
            decoration: _dropdownDecoration(context),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: sectionController,
            label: "Section",
            icon: Icons.group,
            hintText: "e.g. Section A",
            validator:
                (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Section is required'
                        : null,
          ),
          const SizedBox(height: 20),
          // Enhanced Username field with @student.app instruction
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: studentUsernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  hintText: "Enter your username (no @student.app needed)",
                  prefixIcon: Icon(
                    Icons.account_circle,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(52, 158, 158, 158),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username is required';
                  }

                  String input = value.trim();
                  if (input.contains('@')) {
                    if (input.endsWith('@student.app')) {
                      return 'Do not include @student.app. Just enter your username.';
                    }
                    return 'Just enter your username. "@student.app" is added automatically.';
                  }

                  // Check for valid username format
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
                      "@student.app will be automatically added by the system",
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
            controller: studentPasswordController,
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
              if (value != studentPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          // Login format explanation box
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
                      "How login works:",
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
                  "You enter: mariasantos\nYou login with: mariasantos@student.app",
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
          // Show reading level info
          if (_notSetReadingLevelId != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Your reading level will be set to 'Not Set' initially",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: _notSetReadingLevelId != null ? 10 : 0),
          SignUpButton(text: "Sign Up", onPressed: registerStudent),
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
                  ).push(PageTransition(page: const StudentLoginPage()));
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

  InputDecoration _dropdownDecoration(BuildContext context) => InputDecoration(
    labelText: "Grade",
    hintText: "Select your grade",
    hintStyle: TextStyle(
      fontStyle: FontStyle.italic,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    ),
    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
    filled: true,
    fillColor: const Color.fromARGB(52, 158, 158, 158),
    prefixIcon: Icon(
      Icons.grade,
      color: Theme.of(context).colorScheme.onSurface,
    ),
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
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
        hintStyle: TextStyle(
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        filled: true,
        fillColor: const Color.fromARGB(52, 158, 158, 158),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
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
