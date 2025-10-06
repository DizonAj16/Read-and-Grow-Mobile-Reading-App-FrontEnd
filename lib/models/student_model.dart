import 'package:shared_preferences/shared_preferences.dart';

class Student {
  final String id; // student_id (UUID)
  final String? userId; // user_id (UUID) from users table
  final String studentName;
  final String? studentLrn;
  final String? studentGrade;
  final String? studentSection;
  final String? username;
  final String avatarLetter;
  final String? profilePicture;
  final String? classRoomId; // UUID of class
  final String? currentReadingLevelId;

  /// Track completed tasks (0 to 13)
  final int completedTasks;

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
    this.classRoomId,
    this.completedTasks = 0,
    this.currentReadingLevelId,
  }) : avatarLetter =
      avatarLetter ??
          (studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S');

  Student copyWith({
    String? id,
    String? userId,
    String? studentName,
    String? studentLrn,
    String? studentGrade,
    String? studentSection,
    String? username,
    String? avatarLetter,
    String? profilePicture,
    String? classRoomId,
    int? completedTasks,
    String? currentReadingLevelId,
  }) {
    return Student(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      studentName: studentName ?? this.studentName,
      studentLrn: studentLrn ?? this.studentLrn,
      studentGrade: studentGrade ?? this.studentGrade,
      studentSection: studentSection ?? this.studentSection,
      username: username ?? this.username,
      avatarLetter: avatarLetter ?? this.avatarLetter,
      profilePicture: profilePicture ?? this.profilePicture,
      classRoomId: classRoomId ?? this.classRoomId,
      completedTasks: completedTasks ?? this.completedTasks,
        currentReadingLevelId : currentReadingLevelId ?? this.currentReadingLevelId,
    );
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    final name = json['student_name'] ?? '';
    return Student(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      studentName: name,
      studentLrn: json['student_lrn'] as String?,
      studentGrade: json['student_grade'] as String?,
      studentSection: json['student_section'] as String?,
      username: json['username'] as String?,
      avatarLetter: name.isNotEmpty ? name[0].toUpperCase() : 'S',
      profilePicture: json['profile_picture'] as String?,
      classRoomId: json['class_room_id'] as String?,
      completedTasks: json['completed_tasks'] as int? ?? 0,
        currentReadingLevelId: json['current_reading_level_id'] as String?
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
    'class_room_id': classRoomId,
    'profile_picture': profilePicture,
    'completed_tasks': completedTasks,
    'current_reading_level_id': currentReadingLevelId,
  };

  static Future<Student> fromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('student_name') ?? '';
    return Student(
      id: prefs.getString('student_id') ?? '',
      userId: prefs.getString('user_id'),
      studentName: name,
      studentLrn: prefs.getString('student_lrn'),
      studentGrade: prefs.getString('student_grade'),
      studentSection: prefs.getString('student_section'),
      username: prefs.getString('username'),
      avatarLetter: name.isNotEmpty ? name[0].toUpperCase() : 'S',
      profilePicture: prefs.getString('profile_picture'),
      classRoomId: prefs.getString('class_room_id'),
      completedTasks: int.tryParse(prefs.getString('completed_tasks') ?? '') ?? 0,
        currentReadingLevelId: prefs.getString('current_reading_level_id') ?? '',
    );
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_id', id);
    if (userId != null) await prefs.setString('user_id', userId!);
    await prefs.setString('student_name', studentName);
    if (studentLrn != null) await prefs.setString('student_lrn', studentLrn!);
    if (studentGrade != null) await prefs.setString('student_grade', studentGrade!);
    if (studentSection != null) await prefs.setString('student_section', studentSection!);
    if (username != null) await prefs.setString('username', username!);
    if (profilePicture != null) await prefs.setString('profile_picture', profilePicture!);
    if (classRoomId != null) await prefs.setString('class_room_id', classRoomId!);
    await prefs.setString('completed_tasks', completedTasks.toString());
  }
}
