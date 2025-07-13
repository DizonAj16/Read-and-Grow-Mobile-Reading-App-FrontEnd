import 'package:shared_preferences/shared_preferences.dart';

class Student {
  final int id; // student_id
  final int? userId; // user_id from users table
  final String studentName;
  final String? studentLrn;
  final String? studentGrade;
  final String? studentSection;
  final String? username;
  final String avatarLetter;
  final String? profilePicture;

  Student({
    required this.id,
    this.userId,
    required this.studentName,
    this.studentLrn,
    this.studentGrade,
    this.studentSection,
    this.username,
    String? avatarLetter,
    this.profilePicture,
  }) : avatarLetter =
           avatarLetter ??
           (studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S');

  factory Student.fromJson(Map<String, dynamic> json) {
    final name = json['student_name'] ?? '';
    return Student(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      userId:
          json['user_id'] is int
              ? json['user_id']
              : int.tryParse(json['user_id']?.toString() ?? ''),
      studentName: name,
      studentLrn: json['student_lrn'],
      studentGrade: json['student_grade']?.toString(),
      studentSection: json['student_section']?.toString(),
      username: json['username'],
      avatarLetter: name.isNotEmpty ? name[0].toUpperCase() : 'S',
      profilePicture: json['profile_picture'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'student_name': studentName,
    'student_lrn': studentLrn,
    'student_grade': studentGrade,
    'student_section': studentSection,
    'username': username,
    'avatarLetter': avatarLetter,
  };

  static Future<Student> fromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('student_name') ?? '';
    return Student(
      id: int.tryParse(prefs.getString('student_id') ?? '') ?? 0,
      userId: int.tryParse(prefs.getString('user_id') ?? ''),
      studentName: name,
      studentLrn: prefs.getString('student_lrn'),
      studentGrade: prefs.getString('student_grade'),
      studentSection: prefs.getString('student_section'),
      username: prefs.getString('username'),
      avatarLetter: name.isNotEmpty ? name[0].toUpperCase() : 'S',
      profilePicture: prefs.getString('profile_picture'),
    );
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (id != 0) await prefs.setString('student_id', id.toString());
    if (userId != null) await prefs.setString('user_id', userId.toString());
    if (studentName.isNotEmpty)
      await prefs.setString('student_name', studentName);
    if (studentLrn != null) await prefs.setString('student_lrn', studentLrn!);
    if (studentGrade != null)
      await prefs.setString('student_grade', studentGrade!);
    if (studentSection != null)
      await prefs.setString('student_section', studentSection!);
    if (username != null) await prefs.setString('username', username!);
    if (profilePicture != null)
      await prefs.setString('profile_picture', profilePicture!);
  }
}
