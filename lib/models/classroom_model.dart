import 'dart:convert';

class Classroom {
  String? id;
  final String className;
  final String gradeLevel;
  final String section;
  final String schoolYear;
  final int studentCount;
  final String teacherId;

  final String? teacherName;
  final String? teacherEmail;
  final String? teacherPosition;
  final String? teacherAvatar;
  final String? backgroundImage;

  Classroom({
    this.id,
    required this.className,
    required this.gradeLevel,
    required this.section,
    required this.schoolYear,
    required this.studentCount,
    required this.teacherId,
    this.teacherName,
    this.teacherEmail,
    this.teacherPosition,
    this.teacherAvatar,
    this.backgroundImage,
  });

  factory Classroom.fromJson(Map<String, dynamic>? json) {
    final data = json ?? {};
    return Classroom(
      id: data['id'] ?? '',
      className: data['class_name'] ?? 'Unnamed',
      gradeLevel: data['grade_level']?.toString() ?? 'N/A',
      section: data['section'] ?? '',
      schoolYear: data['school_year']?.toString() ?? 'N/A',
      studentCount: data['student_count'] ?? 0,
      teacherId: data['teacher_id'] ?? '',
      teacherName: data['teacher_name'] ?? 'Unknown',
      teacherEmail: data['teacher_email'],
      teacherPosition: data['teacher_position'],
      teacherAvatar: data['teacher_avatar'],
      backgroundImage: data['background_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_name': className,
      'grade_level': gradeLevel,
      'section': section,
      'school_year': schoolYear,
      'student_count': studentCount,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
      'teacher_email': teacherEmail,
      'teacher_position': teacherPosition,
      'teacher_avatar': teacherAvatar,
      'background_image': backgroundImage,
    };
  }

  static String encodeList(List<Classroom> classes) =>
      json.encode(classes.map((c) => c.toJson()).toList());

  static List<Classroom> decodeList(String classesJson) =>
      (json.decode(classesJson) as List<dynamic>)
          .map((item) => Classroom.fromJson(item as Map<String, dynamic>?))
          .toList();
}
