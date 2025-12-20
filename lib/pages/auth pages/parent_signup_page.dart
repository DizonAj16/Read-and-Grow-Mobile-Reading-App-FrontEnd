import 'package:deped_reading_app_laravel/pages/auth%20pages/parent_login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/appbar/theme_toggle_button.dart';
import 'auth buttons widgets/signup_button.dart';
import 'form fields widgets/password_text_field.dart';
import '../../widgets/navigation/page_transition.dart';

class ParentSignUpPage extends StatefulWidget {
  const ParentSignUpPage({super.key});

  @override
  State<ParentSignUpPage> createState() => _ParentSignUpPageState();
}

class _ParentSignUpPageState extends State<ParentSignUpPage> {
  final TextEditingController parentNameController = TextEditingController();
  final TextEditingController studentLRNController = TextEditingController();
  final TextEditingController parentUsernameController =
      TextEditingController();
  final TextEditingController parentPasswordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  bool _isValidatingLRN = false;
  String? _validatedStudentName;
  String? _validatedStudentId;
  bool _isLRNNotFound = false; // New flag to track LRN not found state

  @override
  void dispose() {
    parentNameController.dispose();
    studentLRNController.dispose();
    parentUsernameController.dispose();
    parentPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateLRN(String lrn) async {
    if (lrn.trim().isEmpty) {
      setState(() {
        _validatedStudentName = null;
        _validatedStudentId = null;
        _isLRNNotFound = false;
      });
      return;
    }

    // Only validate if LRN is exactly 12 digits
    if (!RegExp(r'^\d{12}$').hasMatch(lrn.trim())) {
      setState(() {
        _validatedStudentName = null;
        _validatedStudentId = null;
        _isLRNNotFound = false;
      });
      return;
    }

    setState(() {
      _isValidatingLRN = true;
      _isLRNNotFound = false;
    });

    try {
      final supabase = Supabase.instance.client;
      final studentResponse =
          await supabase
              .from('students')
              .select('id, student_name, student_lrn')
              .eq('student_lrn', lrn.trim())
              .maybeSingle();

      if (studentResponse != null && studentResponse['id'] != null) {
        setState(() {
          _validatedStudentName = studentResponse['student_name'] as String;
          _validatedStudentId = studentResponse['id'] as String;
          _isLRNNotFound = false;
        });
      } else {
        setState(() {
          _validatedStudentName = null;
          _validatedStudentId = null;
          _isLRNNotFound = true; // Set not found flag
        });
      }
    } catch (e) {
      debugPrint('Error validating LRN: $e');
      setState(() {
        _validatedStudentName = null;
        _validatedStudentId = null;
        _isLRNNotFound = false;
      });
    } finally {
      setState(() => _isValidatingLRN = false);
    }
  }

  Future<void> registerParent() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    // Validate LRN before proceeding
    if (_validatedStudentId == null || _validatedStudentName == null) {
      _handleErrorDialog(
        title: "Invalid LRN",
        message: "Please enter a valid student LRN that exists in the system.",
      );
      return;
    }

    _showLoadingDialog("Creating your account...");

    String? authUserId; // Track auth user ID for rollback

    try {
      final supabase = Supabase.instance.client;
      final trimmedUsername = parentUsernameController.text.trim();
      final trimmedPassword = parentPasswordController.text.trim();
      final trimmedName = parentNameController.text.trim();

      debugPrint('👨‍👩‍👧 [PARENT_REGISTER] Starting parent registration');
      debugPrint(
        '👨‍👩‍👧 [PARENT_REGISTER] Username: $trimmedUsername, Name: $trimmedName',
      );

      // 1️⃣ Check if username already exists in users table
      final existingUser =
          await supabase
              .from('users')
              .select('id, role')
              .eq('username', trimmedUsername)
              .maybeSingle();

      if (existingUser != null) {
        Navigator.of(context).pop();
        debugPrint('❌ [PARENT_REGISTER] Username already exists');
        _handleErrorDialog(
          title: "Registration Failed",
          message:
              "Username already exists. Please choose a different username.",
        );
        return;
      }

      // 2️⃣ Create Supabase Auth account
      debugPrint('👨‍👩‍👧 [PARENT_REGISTER] Creating auth account...');
      final email =
          "$trimmedUsername@parent.app"; // NOTE: "@parent.app" is automatically appended to username for email
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: trimmedPassword,
      );

      if (authResponse.user == null) {
        Navigator.of(context).pop();
        debugPrint('❌ [PARENT_REGISTER] Auth account creation failed');
        _handleErrorDialog(
          title: "Registration Failed",
          message: "Could not create authentication account. Please try again.",
        );
        return;
      }

      authUserId = authResponse.user!.id;
      debugPrint('✅ [PARENT_REGISTER] Auth account created: $authUserId');

      // 3️⃣ Insert into public.users table
      debugPrint('👨‍👩‍👧 [PARENT_REGISTER] Creating users record...');
      await supabase
          .from('users')
          .insert({
            'id': authUserId,
            'username': trimmedUsername,
            'password': trimmedPassword,
            'role': 'parent',
          })
          .select()
          .single(); // Will throw if insertion fails

      debugPrint('✅ [PARENT_REGISTER] Users record created');

      // 4️⃣ Parse parent name into first_name and last_name
      final nameParts =
          trimmedName.split(' ').where((part) => part.isNotEmpty).toList();
      final firstName = nameParts.isNotEmpty ? nameParts.first : trimmedName;
      final lastName =
          nameParts.length > 1
              ? nameParts.sublist(1).join(' ')
              : firstName; // Use first name as last name if only one name provided

      debugPrint(
        '👨‍👩‍👧 [PARENT_REGISTER] Parsed name - First: $firstName, Last: $lastName',
      );

      // 5️⃣ Insert into public.parents table
      debugPrint('👨‍👩‍👧 [PARENT_REGISTER] Creating parents record...');
      await supabase
          .from('parents')
          .insert({
            'id': authUserId,
            'first_name': firstName,
            'last_name': lastName,
            'parent_name': trimmedName, // Store full name for convenience
            'username': trimmedUsername,
            'email': email, // Use the same email as auth (username@parent.app)
          })
          .select()
          .single(); // Will throw if insertion fails

      debugPrint('✅ [PARENT_REGISTER] Parents record created');

      // 6️⃣ Link parent to student via parent_student_relationships
      debugPrint(
        '👨‍👩‍👧 [PARENT_REGISTER] Linking to student: ${_validatedStudentId}',
      );
      try {
        await supabase.from('parent_student_relationships').insert({
          'parent_id': authUserId,
          'student_id': _validatedStudentId!,
          'relationship_type': 'parent',
        });
        debugPrint('✅ [PARENT_REGISTER] Linked to student successfully');
      } catch (relError) {
        debugPrint(
          '⚠️ [PARENT_REGISTER] Failed to link to student (non-critical): $relError',
        );
        // Don't fail registration if relationship insert fails - parent can still log in
      }

      debugPrint('✅ [PARENT_REGISTER] Registration completed successfully');

      if (mounted) {
        Navigator.of(context).pop();
        // Show login information dialog with credentials
        await _showLoginInformationDialog(
          username: trimmedUsername,
          email: email,
          password: trimmedPassword,
          studentName: _validatedStudentName!,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [PARENT_REGISTER] Registration error: $e');
      debugPrint('Stack trace: $stackTrace');

      // Attempt rollback if we have an auth user ID
      if (authUserId != null) {
        try {
          debugPrint('🧹 [PARENT_REGISTER] Attempting rollback...');
          final supabase = Supabase.instance.client;

          // Delete parent record if exists
          try {
            await supabase.from('parents').delete().eq('id', authUserId);
          } catch (e) {
            debugPrint('⚠️ [PARENT_REGISTER] Rollback parents: $e');
          }

          // Delete user record if exists
          try {
            await supabase.from('users').delete().eq('id', authUserId);
          } catch (e) {
            debugPrint('⚠️ [PARENT_REGISTER] Rollback users: $e');
          }

          // Delete auth user (admin required)
          try {
            await supabase.auth.admin.deleteUser(authUserId);
          } catch (e) {
            debugPrint('⚠️ [PARENT_REGISTER] Rollback auth: $e');
          }
        } catch (rollbackError) {
          debugPrint('❌ [PARENT_REGISTER] Rollback failed: $rollbackError');
        }
      }

      Navigator.of(context).pop();

      // Provide user-friendly error message
      String errorMessage = "Failed to sign up. Please try again.";
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('duplicate') || errorString.contains('unique')) {
        errorMessage =
            "Username or email already exists. Please choose different credentials.";
      } else if (errorString.contains('foreign key') ||
          errorString.contains('constraint')) {
        errorMessage =
            "Invalid data provided. Please check your information and try again.";
      } else if (errorString.contains('validation') ||
          errorString.contains('required')) {
        errorMessage = "Please fill in all required fields correctly.";
      }

      _handleErrorDialog(title: "Registration Error", message: errorMessage);
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
    required String studentName,
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

                  // Linked Student Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.school, color: Colors.purple, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Linked Student",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.purple[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                studentName,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.bold,
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
                          "1. You are now linked to $studentName",
                          context,
                        ),
                        _buildInstructionItem(
                          "2. Save your login credentials in a secure place",
                          context,
                        ),
                        _buildInstructionItem(
                          "3. Use the email and password above to login",
                          context,
                        ),
                        _buildInstructionItem(
                          "4. You cannot change your email format (@parent.app is fixed)",
                          context,
                        ),
                        _buildInstructionItem(
                          "5. You can monitor your child's progress in the parent dashboard",
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.grey[600], size: 20),
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
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Text(
                  value,
                  style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                ),
              ),
            ],
          ),
        ),
      ],
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
      ).pushReplacement(PageTransition(page: ParentLoginPage()));
    }
  }

  Future<void> _showBriefSuccessDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder:
          (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animation/success.json',
                    height: 80,
                    width: 80,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Redirecting to Login...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context).pop();
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
      // Instruction banner for @parent.app
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
                    "@parent.app is automatically added in the backend.\nJust enter your username for login!",
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
        child: Icon(
          Icons.family_restroom,
          size: 90,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        "Parent Sign Up",
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 80),
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
            controller: parentNameController,
            label: "Parent Full Name",
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
            label: "Student LRN",
            icon: Icons.confirmation_number,
            hintText: "e.g. 123456789012",
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Student LRN is required';
              }
              if (!RegExp(r'^\d{12}$').hasMatch(value.trim())) {
                return 'LRN must be exactly 12 digits';
              }
              if (_validatedStudentId == null && _isLRNNotFound) {
                return 'No student found with this LRN';
              }
              return null;
            },
            onChanged: (value) {
              _validateLRN(value);
            },
            suffixIcon:
                _isValidatingLRN
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : _validatedStudentId != null
                    ? Icon(Icons.check_circle, color: Colors.green, size: 24)
                    : _isLRNNotFound
                    ? Icon(Icons.error_outline, color: Colors.red, size: 24)
                    : studentLRNController.text.isNotEmpty &&
                        !RegExp(
                          r'^\d{12}$',
                        ).hasMatch(studentLRNController.text.trim())
                    ? Icon(Icons.error, color: Colors.red, size: 24)
                    : null,
          ),
          // Student found indicator
          if (_validatedStudentName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Student found: $_validatedStudentName',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // No student found indicator (only when LRN is 12 digits and not found)
          if (_isLRNNotFound &&
              studentLRNController.text.trim().length == 12) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No student found with this LRN',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Enhanced Username field with @parent.app instruction
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: parentUsernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  hintText: "Enter your username (no @parent.app needed)",
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
                    if (input.endsWith('@parent.app')) {
                      return 'Do not include @parent.app. Just enter your username.';
                    }
                    return 'Just enter your username. "@parent.app" is added automatically.';
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
                      "@parent.app will be automatically added by the system",
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
                  "You enter: mariasantos\nYou login with: mariasantos@parent.app",
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
          PasswordTextField(
            labelText: "Password",
            controller: parentPasswordController,
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
              if (value != parentPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          SignUpButton(text: "Sign Up", onPressed: registerParent),
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
                  ).push(PageTransition(page: ParentLoginPage()));
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
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
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
        suffixIcon: suffixIcon,
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
