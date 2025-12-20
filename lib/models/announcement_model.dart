// models/announcement_model.dart
import 'package:flutter/material.dart';

class Announcement {
  final String id;
  final String classRoomId;
  final String teacherId;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? teacherName;
  final String? teacherProfilePicture;
  final String? imageUrl; // Add this field for image support
  final DateTime? updatedAt; // Add this for update tracking

  Announcement({
    required this.id,
    required this.classRoomId,
    required this.teacherId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.teacherName,
    this.teacherProfilePicture,
    this.imageUrl, // Add this
    this.updatedAt, // Add this
  });

factory Announcement.fromJson(Map<String, dynamic> json) {
  // Safely handle image_url which could be null, empty string, or a valid URL
  final dynamic imageUrlData = json['image_url'];
  String? imageUrl;
  
  if (imageUrlData is String && imageUrlData.isNotEmpty) {
    imageUrl = imageUrlData;
  } else {
    imageUrl = null;
  }
  
  debugPrint('📝 Parsing announcement image_url: $imageUrlData -> $imageUrl');

  return Announcement(
    id: json['id'] as String,
    classRoomId: json['class_room_id'] as String,
    teacherId: json['teacher_id'] as String,
    title: json['title'] as String,
    content: json['content'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String),
    teacherName: json['teacher']?['teacher_name'] as String?,
    teacherProfilePicture: json['teacher']?['profile_picture'] as String?,
    imageUrl: imageUrl,
    updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at'] as String) 
        : null,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_room_id': classRoomId,
      'teacher_id': teacherId,
      'title': title,
      'content': content,
      'image_url': imageUrl, // Add this
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(), // Add this
    };
  }

  // Add this method for formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Add this method for showing "Edited" text
  String get displayDate {
    if (updatedAt != null && updatedAt!.isAfter(createdAt)) {
      return '$formattedDate • Edited';
    }
    return formattedDate;
  }
}