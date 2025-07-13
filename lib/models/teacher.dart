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

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: _parseInt(map['teacher_id']),
      userId: _parseInt(map['user_id']),
      name: map['teacher_name'] ?? 'Teacher',
      position: map['teacher_position'],
      email: map['teacher_email'],
      username: map['username'],
      profilePicture: map['profile_picture'],
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
    );
  }

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher.fromMap(json);
  }

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

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNameKey, name);
    await prefs.setString(_kPositionKey, position ?? '');
    await prefs.setString(_kEmailKey, email ?? '');
    await prefs.setString(_kUsernameKey, username ?? '');
    await prefs.setString(_kProfilePictureKey, profilePicture ?? '');
    await prefs.setString(_kCreatedAtKey, createdAt?.toIso8601String() ?? '');
    await prefs.setString(_kUpdatedAtKey, updatedAt?.toIso8601String() ?? '');
    if (userId != null) await prefs.setString(_kUserIdKey, userId.toString());
    if (id != null) await prefs.setInt(_kTeacherIdKey, id!);
  }

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

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
