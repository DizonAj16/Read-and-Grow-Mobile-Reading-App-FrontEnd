import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseAuthService {
  static final _supabase = Supabase.instance.client;

  /// Login with email + password using Supabase Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Login failed. No user returned.');
    }

    // Store role separately from your public.users table
    final roleRow = await _supabase
        .from('users')
        .select('role')
        .eq('id', user.id) // link via Supabase auth.uid
        .maybeSingle();

    final role = roleRow?['role'] ?? 'student';

    // Save locally (like old code did)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
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

    // Fetch extra fields (like role, username) from your `users` table
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
