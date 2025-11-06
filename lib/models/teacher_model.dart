import 'package:shared_preferences/shared_preferences.dart';

class Teacher {
  final int? id;
  final int? userId;
  final String name;
  final String? position;
  final String? email;
  final String? username;
  String? profilePicture;
  final bool? isApproved;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const String _kTeacherIdKey = 'teacher_id';
  static const String _kUserIdKey = 'id';
  static const String _kNameKey = 'teacher_name';
  static const String _kPositionKey = 'teacher_position';
  static const String _kEmailKey = 'teacher_email';
  static const String _kUsernameKey = 'username';
  static const String _kProfilePictureKey = 'profile_picture';
  static const String _kIsApprovedKey = 'is_approved';
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
    this.isApproved,
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
        isApproved: false,
        createdAt: null,
        updatedAt: null,
      );

  /// Create a Teacher object from SharedPreferences
  static Future<Teacher> fromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
      return Teacher(
        id: _parseInt(prefs.getString(_kTeacherIdKey)),
        userId: _parseInt(prefs.getString(_kUserIdKey)),
        name: prefs.getString(_kNameKey) ?? 'Teacher',
        position: prefs.getString(_kPositionKey),
        email: prefs.getString(_kEmailKey),
        username: prefs.getString(_kUsernameKey),
        profilePicture: prefs.getString(_kProfilePictureKey),
        isApproved: prefs.getBool(_kIsApprovedKey),
        createdAt: DateTime.tryParse(prefs.getString(_kCreatedAtKey) ?? ''),
        updatedAt: DateTime.tryParse(prefs.getString(_kUpdatedAtKey) ?? ''),
      );
  }

  /// Create a Teacher object from JSON or Map - handles both API response formats
  factory Teacher.fromJson(Map<String, dynamic> json) {
    final hasUserProfileStructure = json.containsKey('user') && json.containsKey('profile');
    
    if (hasUserProfileStructure) {
      final userData = json['user'] ?? {};
      final profileData = json['profile'] ?? {};
      
      return Teacher(
        id: _parseInt(profileData['id']),
        userId: _parseInt(userData['id']),
        name: profileData['teacher_name'] ?? 'Teacher',
        position: profileData['teacher_position'],
        email: profileData['teacher_email'],
        username: userData['username'] ?? profileData['username'],
        profilePicture: profileData['profile_picture'],
        isApproved: profileData['is_approved'] as bool?,
        createdAt: profileData['created_at'] != null
            ? DateTime.tryParse(profileData['created_at'])
            : null,
        updatedAt: profileData['updated_at'] != null
            ? DateTime.tryParse(profileData['updated_at'])
            : null,
      );
    } else {
      // Handle both UUID (string) and integer IDs
      final idValue = json['id'] ?? json['teacher_id'];
      final parsedId = idValue is int ? idValue : _parseInt(idValue?.toString());
      
      return Teacher(
        id: parsedId,
        userId: parsedId,
        name: json['teacher_name'] ?? 'Teacher',
        position: json['teacher_position'],
        email: json['teacher_email'],
        username: json['username'],
        profilePicture: json['profile_picture'],
        isApproved: json['is_approved'] == null ? false : (json['is_approved'] as bool? ?? false),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );
    }
  }

  /// Convert to JSON for storage (flattened structure)
  Map<String, dynamic> toJson() => {
        'teacher_id': id,
        'id': userId,
        'teacher_name': name,
        'teacher_position': position,
        'teacher_email': email,
        'username': username,
        'profile_picture': profilePicture,
        'is_approved': isApproved,
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
    await prefs.setBool(_kIsApprovedKey, isApproved ?? false);
    await prefs.setString(_kCreatedAtKey, createdAt?.toIso8601String() ?? '');
    await prefs.setString(_kUpdatedAtKey, updatedAt?.toIso8601String() ?? '');

    if (userId != null) {
      await prefs.setString(_kUserIdKey, userId.toString());
    }
    if (id != null) {
      await prefs.setString(_kTeacherIdKey, id.toString());
    }
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
    await prefs.remove(_kIsApprovedKey);
    await prefs.remove(_kCreatedAtKey);
    await prefs.remove(_kUpdatedAtKey);
  }

  /// Helper to safely parse integers
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  /// Getter for teacher ID (alias for id)
  int? get teacherId => id;
}