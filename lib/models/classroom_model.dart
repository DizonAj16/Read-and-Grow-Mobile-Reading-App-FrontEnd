import 'dart:convert';

class Classroom {
  int? id;
  final String className;
  final String gradeLevel;
  final String section;
  final String schoolYear;
  final int studentCount;
  final int teacherId;

  final String? teacherName;
  final String? teacherEmail;      // ✅ NEW
  final String? teacherPosition;   // ✅ NEW
  final String? teacherAvatar;     // ✅ NEW
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

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] ?? 0,
      className: json['class_name'] ?? 'Unnamed',
      gradeLevel: json['grade_level']?.toString() ?? 'N/A',
      section: json['section'] ?? '',
      schoolYear: json['school_year']?.toString() ?? 'N/A',
      studentCount: json['student_count'] ?? 0,
      teacherId: json['teacher_id'] ?? 0,
      teacherName: json['teacher_name'] ?? 'Unknown',
      teacherEmail: json['teacher_email'],          // ✅
      teacherPosition: json['teacher_position'],    // ✅
      teacherAvatar: json['teacher_avatar'],        // ✅
      backgroundImage: json['background_image'],
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
          .map((item) => Classroom.fromJson(item))
          .toList();
}
