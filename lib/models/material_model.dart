class MaterialModel {
  final int id;
  final String classRoomId;
  final String uploadedBy;
  final String materialTitle;
  final String materialFileUrl;
  final String materialType;
  final String? description;
  final String? fileIcon;
  final String? fileSize;
  final String fileExtension;
  final DateTime createdAt;
  final String teacherName;

  MaterialModel({
    required this.id,
    required this.classRoomId,
    required this.uploadedBy,
    required this.materialTitle,
    required this.materialFileUrl,
    required this.materialType,
    this.description,
    this.fileIcon,
    this.fileSize,
    required this.fileExtension,
    required this.createdAt,
    required this.teacherName,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'] ?? 0,
      classRoomId: json['class_room_id'] ?? '',
      uploadedBy: json['uploaded_by'] ?? '',
      materialTitle: json['material_title'] ?? '',
      materialFileUrl: json['material_file_url'] ?? '',
      materialType: json['material_type'] ?? 'pdf',
      description: json['description'],
      fileIcon: json['file_icon'],
      fileSize: json['file_size'] is int ? json['file_size'] : null,
      fileExtension: json['file_extension'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
      teacherName: json['teacher_name'] ?? 'Unknown Teacher',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_room_id': classRoomId,
      'uploaded_by': uploadedBy,
      'material_title': materialTitle,
      'material_file_url': materialFileUrl,
      'material_type': materialType,
      'description': description,
      'file_icon': fileIcon,
      'file_size': fileSize,
      'file_extension': fileExtension,
      'created_at': createdAt.toIso8601String(),
      'teacher_name': teacherName,
    };
  }
}
