class PdfMaterial {
  final int id;
  final String title;
  final String url;
  final int? classId;
  final int? teacherId;
  final String? teacherName; // <-- NEW
  final DateTime? uploadedAt;

  PdfMaterial({
    required this.id,
    required this.title,
    required this.url,
    this.classId,
    this.teacherId,
    this.teacherName, // <-- NEW
    this.uploadedAt,
  });

  factory PdfMaterial.fromJson(Map<String, dynamic> json) {
    return PdfMaterial(
      id: json['id'],
      title: json['pdf_title'] ?? '',
      url: json['pdf_file_url'] ?? '',
      classId: json['class_room_id'],
      teacherId: json['teacher_id'],
      teacherName: json['teacher_name'], // <-- NEW
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pdf_title': title,
      'pdf_file_url': url,
      'class_room_id': classId,
      'teacher_id': teacherId,
      'teacher_name': teacherName, // <-- NEW
      'uploaded_at': uploadedAt?.toIso8601String(),
    };
  }
}
