import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/appbar/theme_toggle_button.dart';
import 'auth buttons widgets/signup_button.dart';
import 'form fields widgets/password_text_field.dart';
import '../../widgets/navigation/page_transition.dart';
import 'login_page.dart';

class ParentSignUpPage extends StatefulWidget {
  const ParentSignUpPage({super.key});

  @override
  State<ParentSignUpPage> createState() => _ParentSignUpPageState();
}

class _ParentSignUpPageState extends State<ParentSignUpPage> {
  final TextEditingController parentNameController = TextEditingController();
  final TextEditingController studentLRNController = TextEditingController();
  final TextEditingController parentUsernameController = TextEditingController();
  final TextEditingController parentPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  bool _isValidatingLRN = false;
  String? _validatedStudentName;
  String? _validatedStudentId;

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
      });
      return;
    }

    if (!RegExp(r'^\d{12}$').hasMatch(lrn.trim())) {
      setState(() {
        _validatedStudentName = null;
        _validatedStudentId = null;
      });
      return;
    }

    setState(() => _isValidatingLRN = true);

    try {
      final supabase = Supabase.instance.client;
      final studentResponse = await supabase
          .from('students')
          .select('id, student_name, student_lrn')
          .eq('student_lrn', lrn.trim())
          .maybeSingle();

      if (studentResponse != null && studentResponse['id'] != null) {
        setState(() {
          _validatedStudentName = studentResponse['student_name'] as String;
          _validatedStudentId = studentResponse['id'] as String;
        });
      } else {
        setState(() {
          _validatedStudentName = null;
          _validatedStudentId = null;
        });
      }
    } catch (e) {
      debugPrint('Error validating LRN: $e');
      setState(() {
        _validatedStudentName = null;
        _validatedStudentId = null;
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
      debugPrint('👨‍👩‍👧 [PARENT_REGISTER] Username: $trimmedUsername, Name: $trimmedName');

      // 1️⃣ Check if username already exists in users table
      final existingUser = await supabase
          .from('users')
          .select('id, role')
          .eq('username', trimmedUsername)
          .maybeSingle();

      if (existingUser != null) {
        Navigator.of(context).pop();
        debugPrint('❌ [PARENT_REGISTER] Username already exists');
        _handleErrorDialog(
          title: "Registration Failed",
          message: "Username already exists. Please choose a different username.",
        );
        return;
      }

      // 2️⃣ Create Supabase Auth account
      debugPrint('👨‍👩‍👧 [PARENT_REGISTER] Creating auth account...');
      final email = "$trimmedUsername@parent.app"; // Use a consistent email format
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
      await supabase.from('users').insert({
        'id': authUserId,
        'username': trimmedUsername,
        'password': trimmedPassword,
        'role': 'parent',
      }).select().single(); // Will throw if insertion fails

      debugPrint('✅ [PARENT_REGISTER] Users record created');

      // 4️⃣ Parse parent name into first_name and last_name
      final nameParts = trimmedName.split(' ').where((part) => part.isNotEmpty).toList();
      final firstName = nameParts.isNotEmpty ? nameParts.first : trimmedName;
      final lastName = nameParts.length > 1 
          ? nameParts.sublist(1).join(' ') 
          : firstName; // Use first name as last name if only one name provided

      debugPrint('👨‍👩‍👧 [PARENT_REGISTER] Parsed name - First: $firstName, Last: $lastName');

      // 5️⃣ Insert into public.parents table
      debugPrint('👨‍👩‍👧 [PARENT_REGISTER] Creating parents record...');
      await supabase.from('parents').insert({
        'id': authUserId,
        'first_name': firstName,
        'last_name': lastName,
        'parent_name': trimmedName, // Store full name for convenience
        'username': trimmedUsername,
        'email': email, // Use the same email as auth
      }).select().single(); // Will throw if insertion fails

      debugPrint('✅ [PARENT_REGISTER] Parents record created');

      // 6️⃣ Link parent to student via parent_student_relationships
      debugPrint('👨‍👩‍👧 [PARENT_REGISTER] Linking to student: ${_validatedStudentId}');
      try {
        await supabase.from('parent_student_relationships').insert({
          'parent_id': authUserId,
          'student_id': _validatedStudentId!,
          'relationship_type': 'parent',
        });
        debugPrint('✅ [PARENT_REGISTER] Linked to student successfully');
      } catch (relError) {
        debugPrint('⚠️ [PARENT_REGISTER] Failed to link to student (non-critical): $relError');
        // Don't fail registration if relationship insert fails - parent can still log in
      }

      debugPrint('✅ [PARENT_REGISTER] Registration completed successfully');

      if (mounted) {
        Navigator.of(context).pop();
        await _showSuccessAndProceedDialogs(
          "Registration successful! You are now linked to ${_validatedStudentName}.",
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
        errorMessage = "Username or email already exists. Please choose different credentials.";
      } else if (errorString.contains('foreign key') || errorString.contains('constraint')) {
        errorMessage = "Invalid data provided. Please check your information and try again.";
      } else if (errorString.contains('validation') || errorString.contains('required')) {
        errorMessage = "Please fill in all required fields correctly.";
      }

      _handleErrorDialog(
        title: "Registration Error",
        message: errorMessage,
      );
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

  Future<void> _showSuccessAndProceedDialogs(String message) async {
    await _showSuccessDialog(message);
    if (mounted) {
      Navigator.of(context).pushReplacement(PageTransition(page: LoginPage()));
    }
  }

  Future<void> _showSuccessDialog(String message) async {
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
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 2100));
    if (mounted) Navigator.of(context).pop();
  }

  void _handleErrorDialog({required String title, required String message}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      const SizedBox(height: 50),
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
            validator: (value) =>
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
              if (_validatedStudentId == null) {
                return 'LRN not found. Please verify the LRN is correct.';
              }
              return null;
            },
            onChanged: (value) {
              _validateLRN(value);
            },
            suffixIcon: _isValidatingLRN
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _validatedStudentId != null
                    ? Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      )
                    : studentLRNController.text.isNotEmpty
                        ? Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 24,
                          )
                        : null,
          ),
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
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
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
          const SizedBox(height: 20),
          _buildTextField(
            controller: parentUsernameController,
            label: "Username",
            icon: Icons.account_circle,
            hintText: "e.g. mariasantos",
            validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Username is required'
                    : null,
          ),
          const SizedBox(height: 20),
          PasswordTextField(
            labelText: "Password",
            controller: parentPasswordController,
            hintText: "At least 6 characters",
            validator: (value) =>
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
                  Navigator.of(context)
                      .push(PageTransition(page: LoginPage()));
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
              children: [
                _buildHeader(context),
                _buildSignUpForm(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

