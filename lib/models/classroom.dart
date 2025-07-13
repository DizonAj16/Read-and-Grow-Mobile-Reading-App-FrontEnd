import 'dart:convert';

class Classroom {
  int? id;
  final String className;
  final String gradeLevel;
  final String section;
  final String schoolYear; // ✅ New field
  final int studentCount;
  final int teacherId;
  final String? teacherName; // ✅ Optional field

  Classroom({
    this.id,
    required this.className,
    required this.gradeLevel,
    required this.section,
    required this.schoolYear, // ✅ Add to constructor
    required this.studentCount,
    required this.teacherId,
    this.teacherName,
  });

  // ✅ Create Classroom from JSON
  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'] ?? 0,
      className: json['class_name'] ?? 'Unnamed',
      gradeLevel:
          json['grade_level']?.toString() ?? 'N/A', // 👈 force to String
      section: json['section'] ?? '',
      schoolYear:
          json['school_year']?.toString() ?? 'N/A', // 👈 force to String too
      studentCount: json['student_count'] ?? 0,
      teacherId: json['teacher_id'] ?? 0,
      teacherName: json['teacher_name'] ?? 'Unknown',
    );
  }

  // ✅ Convert Classroom to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_name': className,
      'grade_level': gradeLevel,
      'section': section,
      'school_year': schoolYear, // ✅ Add this line
      'student_count': studentCount,
      'teacher_id': teacherId,
      'teacher_name': teacherName,
    };
  }

  // ✅ Encode list of classrooms to JSON string
  static String encodeList(List<Classroom> classes) =>
      json.encode(classes.map((c) => c.toJson()).toList());

  // ✅ Decode JSON string to list of classrooms
  static List<Classroom> decodeList(String classesJson) =>
      (json.decode(classesJson) as List<dynamic>)
          .map((item) => Classroom.fromJson(item))
          .toList();
}
