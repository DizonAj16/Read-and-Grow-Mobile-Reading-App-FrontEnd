import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/material_model.dart';

class MaterialService {
  static final supabase = Supabase.instance.client;

  /// Upload a material file to Supabase Storage + insert metadata in `materials` table
  static Future<bool> uploadMaterialFile({
    required File file,
    required String materialTitle,
    required String classroomId,
    String? materialType,
    String? description,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("No logged in teacher");
      }

      final fileName =
          "materials/$classroomId-${DateTime.now().millisecondsSinceEpoch}-${file.uri.pathSegments.last}";

      // Upload file to Supabase Storage bucket
      await supabase.storage.from('materials').uploadBinary(
        fileName,
        await file.readAsBytes(),
        fileOptions: const FileOptions(upsert: true),
      );

      // Get public URL
      final publicUrl = supabase.storage.from('materials').getPublicUrl(fileName);

      // Insert metadata into Supabase table
      await supabase.from('materials').insert({
        'material_title': materialTitle,
        'class_room_id': classroomId, // ✅ matches your schema
        'material_type': materialType,
        'description': description,
        'material_file_url': publicUrl,
        'uploaded_by': user.id,
      });

      return true;
    } catch (e) {
      print("Error uploading material: $e");
      return false;
    }
  }

  /// Get all materials for a specific class
  static Future<List<MaterialModel>> getClassroomMaterials(String classId) async {
    try {
      final response = await supabase
          .from('materials')
          .select()
          .eq('class_room_id', classId);

      print("📥 Raw response: $response"); // This will already be a List<dynamic>
      if (response.isNotEmpty) {
        print("📦 Parsed list length: ${response.length}");
        print("🔑 First item keys: ${(response[0] as Map).keys}");
      }

      return (response as List<dynamic>)
          .map((json) => MaterialModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print("Error fetching classroom materials: $e");
      return [];
    }
  }

  /// Get all materials accessible to a student (via student_enrollments)
  static Future<List<MaterialModel>> fetchStudentMaterials() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("No logged in student");

      // ✅ get enrolled classes from student_enrollments
      final enrollments = await supabase
          .from('student_enrollments')
          .select('class_room_id')
          .eq('student_id', user.id);

      if (enrollments.isEmpty) return [];

      final classIds = enrollments.map((e) => e['class_room_id']).toList();

      final response = await supabase
          .from('materials')
          .select()
          .inFilter('class_room_id', classIds);


      final List<dynamic> list = response ?? [];
      return list
          .map((json) => MaterialModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print("Error fetching student materials: $e");
      return [];
    }
  }

  /// Delete a material (both storage + db record)
  static Future<bool> deleteMaterial(int materialId) async {
    try {
      // Get material info first
      final material = await supabase
          .from('materials')
          .select()
          .eq('id', materialId)
          .maybeSingle();

      if (material == null) return false;

      final fileUrl = material['material_file_url'];
      if (fileUrl != null && fileUrl.toString().contains("materials/")) {
        final path = fileUrl.split("/").last;
        await supabase.storage.from('materials').remove([path]);
      }

      await supabase.from('materials').delete().eq('id', materialId);

      return true;
    } catch (e) {
      print("Error deleting material: $e");
      return false;
    }
  }

  /// Filter materials by type inside a class
  static Future<List<MaterialModel>> getMaterialsByType(
      String classId, String type) async {
    try {
      final response = await supabase
          .from('materials')
          .select()
          .eq('class_room_id', classId) // ✅ fixed column
          .eq('material_type', type);

      final List<dynamic> list = response ?? [];
      return list
          .map((json) => MaterialModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print("Error fetching materials by type: $e");
      return [];
    }
  }
}
