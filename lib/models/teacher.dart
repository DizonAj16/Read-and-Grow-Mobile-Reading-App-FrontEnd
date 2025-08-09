import 'package:shared_preferences/shared_preferences.dart';

class Teacher {
  final int? id;
  final int? userId;
  final String name;
  final String? position;
  final String? email;
  final String? username;
  String? profilePicture;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const String _kTeacherIdKey = 'teacher_id';
  static const String _kUserIdKey = 'user_id';
  static const String _kNameKey = 'teacher_name';
  static const String _kPositionKey = 'teacher_position';
  static const String _kEmailKey = 'teacher_email';
  static const String _kUsernameKey = 'username';
  static const String _kProfilePictureKey = 'profile_picture';
  static const String _kCreatedAtKey = 'created_at';
  static const String _kUpdatedAtKey = 'updated_at';

  Teacher({
    this.id,
    this.userId,
    required this.name,
    this.position,
    this.email,
    this.username,
    this.profilePicture,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor for empty/default Teacher
  factory Teacher.empty() => Teacher(
        id: 0,
        userId: 0,
        name: 'Teacher',
        position: '',
        email: '',
        username: '',
        profilePicture: null,
        createdAt: null,
        updatedAt: null,
      );

  /// Create a Teacher object from SharedPreferences
  static Future<Teacher> fromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return Teacher(
      id: prefs.getInt(_kTeacherIdKey),
      userId: int.tryParse(prefs.getString(_kUserIdKey) ?? ''),
      name: prefs.getString(_kNameKey) ?? 'Teacher',
      position: prefs.getString(_kPositionKey),
      email: prefs.getString(_kEmailKey),
      username: prefs.getString(_kUsernameKey),
      profilePicture: prefs.getString(_kProfilePictureKey),
      createdAt: DateTime.tryParse(prefs.getString(_kCreatedAtKey) ?? ''),
      updatedAt: DateTime.tryParse(prefs.getString(_kUpdatedAtKey) ?? ''),
    );
  }

  /// Create a Teacher object from JSON or Map
  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: _parseInt(json['teacher_id']),
      userId: _parseInt(json['user_id']),
      name: json['teacher_name'] ?? 'Teacher',
      position: json['teacher_position'],
      email: json['teacher_email'],
      username: json['username'],
      profilePicture: json['profile_picture'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'teacher_id': id,
        'user_id': userId,
        'teacher_name': name,
        'teacher_position': position,
        'teacher_email': email,
        'username': username,
        'profile_picture': profilePicture,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  /// Save Teacher object to SharedPreferences
  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNameKey, name);
    await prefs.setString(_kPositionKey, position ?? '');
    await prefs.setString(_kEmailKey, email ?? '');
    await prefs.setString(_kUsernameKey, username ?? '');
    await prefs.setString(_kProfilePictureKey, profilePicture ?? '');
    await prefs.setString(
        _kCreatedAtKey, createdAt?.toIso8601String() ?? '');
    await prefs.setString(
        _kUpdatedAtKey, updatedAt?.toIso8601String() ?? '');
    if (userId != null) await prefs.setString(_kUserIdKey, userId.toString());
    if (id != null) await prefs.setInt(_kTeacherIdKey, id!);
  }

  /// Clear Teacher data from SharedPreferences
  static Future<void> clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTeacherIdKey);
    await prefs.remove(_kUserIdKey);
    await prefs.remove(_kNameKey);
    await prefs.remove(_kPositionKey);
    await prefs.remove(_kEmailKey);
    await prefs.remove(_kUsernameKey);
    await prefs.remove(_kProfilePictureKey);
    await prefs.remove(_kCreatedAtKey);
    await prefs.remove(_kUpdatedAtKey);
  }

  /// Helper to safely parse integers
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}