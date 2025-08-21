class MaterialModel {
  final int id;
  final int classRoomId;
  final int teacherId;
  final String materialTitle;
  final String materialFileUrl;
  final String materialType;
  final String? description;
  final String? fileIcon;
  final String? fileSize;
  final DateTime uploadedAt;
  final String teacherName;

  MaterialModel({
    required this.id,
    required this.classRoomId,
    required this.teacherId,
    required this.materialTitle,
    required this.materialFileUrl,
    required this.materialType,
    this.description,
    this.fileIcon,
    this.fileSize,
    required this.uploadedAt,
    required this.teacherName,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] ?? 0,
      classRoomId: json['class_room_id'] ?? 0,
      teacherId: json['teacher_id'] ?? 0,
      materialTitle: json['material_title'] ?? '',
      materialFileUrl: json['material_file_url'] ?? '',
      materialType: json['material_type'] ?? 'pdf',
      description: json['description'],
      fileIcon: json['file_icon'],
      fileSize: json['file_size'],
      uploadedAt: DateTime.parse(json['uploaded_at'] ?? DateTime.now().toString()),
      teacherName: json['teacher_name'] ?? 'Unknown Teacher',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_room_id': classRoomId,
      'teacher_id': teacherId,
      'material_title': materialTitle,
      'material_file_url': materialFileUrl,
      'material_type': materialType,
      'description': description,
      'file_icon': fileIcon,
      'file_size': fileSize,
      'uploaded_at': uploadedAt.toIso8601String(),
      'teacher_name': teacherName,
    };
  }

  // Optional: CopyWith method for easier updates
  MaterialModel copyWith({
    int? id,
    int? classRoomId,
    int? teacherId,
    String? materialTitle,
    String? materialFileUrl,
    String? materialType,
    String? description,
    String? fileIcon,
    String? fileSize,
    DateTime? uploadedAt,
    String? teacherName,
  }) {
    return MaterialModel(
      id: id ?? this.id,
      classRoomId: classRoomId ?? this.classRoomId,
      teacherId: teacherId ?? this.teacherId,
      materialTitle: materialTitle ?? this.materialTitle,
      materialFileUrl: materialFileUrl ?? this.materialFileUrl,
      materialType: materialType ?? this.materialType,
      description: description ?? this.description,
      fileIcon: fileIcon ?? this.fileIcon,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      teacherName: teacherName ?? this.teacherName,
    );
  }
}