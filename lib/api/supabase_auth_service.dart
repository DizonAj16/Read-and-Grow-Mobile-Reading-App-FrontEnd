import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseAuthService {
  static final _supabase = Supabase.instance.client;

  /// Login with email + password using Supabase Auth
  /// Supports both email and username (for students, converts username to email format)
  static Future<Map<String, dynamic>> login(String emailOrUsername, String password) async {
    String email = emailOrUsername;
    
    // If input doesn't contain @, try to convert it to email format
    if (!emailOrUsername.contains('@')) {
      // First try: assume it's a student username (format: username@student.app)
      email = '$emailOrUsername@student.app';
      
      try {
        // Try logging in with student email format
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        
        if (response.user != null) {
          // Success with student format
          final user = response.user!;
          final roleRow = await _supabase
              .from('users')
              .select('role')
              .eq('id', user.id)
              .maybeSingle();
          
          final role = roleRow?['role'] ?? 'student';
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('id', user.id);
          await prefs.setString('role', role);
          
          return {
            'user': user.toJson(),
            'role': role,
          };
        }
      } catch (e) {
        // Student format failed, try to find teacher email or use original as-is
        try {
          // Try to find teacher email
          final userCheck = await _supabase
              .from('users')
              .select('id, role')
              .eq('username', emailOrUsername)
              .maybeSingle();
          
          if (userCheck != null) {
            final role = userCheck['role'] as String?;
            if (role == 'teacher') {
              final teacherCheck = await _supabase
                  .from('teachers')
                  .select('teacher_email')
                  .eq('id', userCheck['id'])
                  .maybeSingle();
              
              if (teacherCheck != null && teacherCheck['teacher_email'] != null) {
                email = teacherCheck['teacher_email'] as String;
              }
            }
          }
        } catch (e2) {
          // If we can't find teacher email, use original input (might be admin email)
          email = emailOrUsername;
        }
      }
    }
    
    // Final attempt with determined email
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Login failed. No user returned.');
    }

    final roleRow = await _supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    final role = roleRow?['role'] ?? 'student';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id', user.id);
    await prefs.setString('role', role);

    return {
      'user': user.toJson(),
      'role': role,
    };
  }

  /// Logout with Supabase
  static Future<void> logout() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Get current session profile (from Supabase Auth + custom users table)
  static Future<Map<String, dynamic>?> getAuthProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No logged in user');
    final profile = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    return {
      'user': user.toJson(),
      'profile': profile,
    };
  }

  /// Admin login (if you want to keep it)
  static Future<Map<String, dynamic>> adminLogin(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      return {'success': false, 'message': 'Invalid credentials'};
    }

    final profile = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profile?['role'] == 'admin') {
      return {
        'success': true,
        'user': user.toJson(),
        'role': 'admin',
      };
    }

    return {
      'success': false,
      'message': 'Not an admin',
    };
  }
}
