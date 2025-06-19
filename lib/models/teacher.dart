import 'package:shared_preferences/shared_preferences.dart';

class Teacher {
  final int? id;         // teacher_id
  final int? userId;     // user_id from users table
  final String name;
  final String? position;
  final String? email;
  final String? username;

  Teacher({
    this.id,
    this.userId,
    required this.name,
    this.position,
    this.email,
    this.username,
  });

  // Factory to create Teacher from SharedPreferences
  static Future<Teacher> fromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return Teacher(
      id: prefs.getInt('teacher_id'),
      userId: int.tryParse(prefs.getString('user_id') ?? ''),
      name: prefs.getString('teacher_name') ?? 'Teacher',
      position: prefs.getString('teacher_position'),
      email: prefs.getString('teacher_email'),
      username: prefs.getString('username'),
    );
  }

  // Factory to create Teacher from a Map (API response)
  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['teacher_id'] is int ? map['teacher_id'] : int.tryParse(map['teacher_id']?.toString() ?? ''),
      userId: map['user_id'] is int
          ? map['user_id']
          : int.tryParse(map['user_id']?.toString() ?? ''),
      name: map['teacher_name'] ?? 'Teacher',
      position: map['teacher_position'],
      email: map['teacher_email'],
      username: map['username'],
    );
  }

  // Factory to create Teacher from JSON (for API list)
  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['teacher_id'] is int ? json['teacher_id'] : int.tryParse(json['teacher_id']?.toString() ?? ''),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.tryParse(json['user_id']?.toString() ?? ''),
      name: json['teacher_name'] ?? 'Teacher',
      position: json['teacher_position'],
      email: json['teacher_email'],
      username: json['username'],
    );
  }

  Map<String, dynamic> toJson() => {
    'teacher_id': id,
    'user_id': userId,
    'teacher_name': name,
    'teacher_position': position,
    'teacher_email': email,
    'username': username,
  };
}
