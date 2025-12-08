import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/material_model.dart';
import '../utils/validators.dart';
import '../utils/data_validators.dart';
import '../utils/database_helpers.dart';
import '../utils/file_validator.dart';

class MaterialService {
  static final supabase = Supabase.instance.client;

  static Future<bool> uploadMaterialFile({
    required File file,
    required String materialTitle,
    required String classroomId,
    String? materialType,
    String? description,
    double sizeLimitMB = FileValidator.defaultMaxSizeMB,
  }) async {
    try {
      debugPrint('📦 [UPLOAD_MATERIAL] Starting material upload');
      debugPrint('📦 [UPLOAD_MATERIAL] Title: $materialTitle, Class: $classroomId, Type: $materialType');

      // 1️⃣ Validate user authentication
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ [UPLOAD_MATERIAL] No logged in teacher');
        throw Exception("No logged in teacher");
      }

      debugPrint('✅ [UPLOAD_MATERIAL] User authenticated: ${user.id}');

      // 2️⃣ Validate inputs
      if (materialTitle.trim().isEmpty) {
        debugPrint('❌ [UPLOAD_MATERIAL] Material title is empty');
        throw Exception("Material title is required");
      }

      if (classroomId.isEmpty || !Validators.isValidUUID(classroomId)) {
        debugPrint('❌ [UPLOAD_MATERIAL] Invalid classroom ID: $classroomId');
        throw Exception("Invalid classroom ID");
      }

      // 3️⃣ Validate file exists and check size
      if (!await file.exists()) {
        debugPrint('❌ [UPLOAD_MATERIAL] File does not exist: ${file.path}');
        throw Exception("File does not exist");
      }

      final sizeValidation =
          await validateFileSize(file, limitMB: sizeLimitMB);
      if (!sizeValidation.isValid) {
        debugPrint(
          '❌ [UPLOAD_MATERIAL] File size validation failed: ${sizeValidation.getDetailedInfo()}',
        );
        throw FileSizeLimitException(
          FileValidator.backendLimitMessage(sizeLimitMB),
          actualSizeMB: sizeValidation.actualSizeMB,
          limitMB: sizeLimitMB,
        );
      }

      final fileSize = await file.length();
      debugPrint('📦 [UPLOAD_MATERIAL] File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');

      // Build material data (without file_url initially - will be added after upload)
      final materialData = <String, dynamic>{
        'material_title': materialTitle.trim(),
        'class_room_id': classroomId,
        'uploaded_by': user.id,
      };

      if (materialType != null && materialType.isNotEmpty) {
        materialData['material_type'] = materialType;
      }

      if (description != null && description.trim().isNotEmpty) {
        materialData['description'] = description.trim();
      }

      // Validate basic material data (skip file_url validation for now)
      // We'll validate the complete data including file_url after upload
      if (materialData['material_title'] == null || (materialData['material_title'] as String).trim().isEmpty) {
        debugPrint('❌ [UPLOAD_MATERIAL] Material title is required');
        throw Exception("Material title is required");
      }

      if (materialData['class_room_id'] == null || (materialData['class_room_id'] as String).isEmpty) {
        debugPrint('❌ [UPLOAD_MATERIAL] Classroom ID is required');
        throw Exception("Classroom ID is required");
      }

      if (!Validators.isValidUUID(materialData['class_room_id'] as String)) {
        debugPrint('❌ [UPLOAD_MATERIAL] Invalid classroom ID format');
        throw Exception("Invalid classroom ID format");
      }

      debugPrint('✅ [UPLOAD_MATERIAL] Initial data validation passed');

      // Get original filename and extension
      final originalFileName = file.uri.pathSegments.last;
      final fileExtension = originalFileName.split('.').last.toLowerCase();
      
      // Validate file extension
      final allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'mp4', 'mp3'];
      if (!allowedExtensions.contains(fileExtension)) {
        throw Exception('File type not allowed. Allowed types: ${allowedExtensions.join(', ')}');
      }

      // Create unique filename without bucket prefix (bucket name is specified in .from())
      // Store in materials bucket root with folder structure: materials/classroomId/timestamp-filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedFileName = originalFileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final fileName = "$classroomId/$timestamp-$sanitizedFileName";

      // Determine content type based on extension
      String? contentType;
      switch (fileExtension) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'mp4':
          contentType = 'video/mp4';
          break;
        case 'mp3':
          contentType = 'audio/mpeg';
          break;
      }

      // 6️⃣ Read file bytes
      debugPrint('📦 [UPLOAD_MATERIAL] Reading file bytes...');
      final fileBytes = await file.readAsBytes();
      debugPrint('✅ [UPLOAD_MATERIAL] Read ${fileBytes.length} bytes');

      // 7️⃣ Upload to Supabase Storage
      debugPrint('📦 [UPLOAD_MATERIAL] Uploading to storage bucket "materials" with path: $fileName');
      await supabase.storage.from('materials').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: contentType,
        ),
      );

      debugPrint('✅ [UPLOAD_MATERIAL] File uploaded to storage successfully');

      // 8️⃣ Get public URL
      final publicUrl = supabase.storage.from('materials').getPublicUrl(fileName);
      
      if (publicUrl.isEmpty) {
        debugPrint('❌ [UPLOAD_MATERIAL] Failed to get public URL');
        throw Exception("Failed to get file URL");
      }

      debugPrint('✅ [UPLOAD_MATERIAL] Public URL: $publicUrl');

      // 9️⃣ Update material data with file URL and metadata
      final finalMaterialData = Map<String, dynamic>.from(materialData);
      finalMaterialData['material_file_url'] = publicUrl;
      finalMaterialData['file_size'] = fileSize.toString();
      finalMaterialData['file_extension'] = fileExtension;

      // Validate final data with file URL
      final finalValidationErrors = DataValidators.validateMaterialData(finalMaterialData);
      if (DataValidators.hasErrors(finalValidationErrors)) {
        debugPrint('❌ [UPLOAD_MATERIAL] Final material data validation failed: ${DataValidators.getErrorMessage(finalValidationErrors)}');
        
        // Clean up uploaded file
        try {
          debugPrint('🧹 [UPLOAD_MATERIAL] Cleaning up uploaded file due to validation error...');
          await supabase.storage.from('materials').remove([fileName]);
          debugPrint('✅ [UPLOAD_MATERIAL] File cleaned up successfully');
        } catch (cleanupError) {
          debugPrint("⚠️ [UPLOAD_MATERIAL] Error cleaning up file: $cleanupError");
        }
        
        throw Exception(DataValidators.getErrorMessage(finalValidationErrors));
      }

      // 🔟 Insert material record into database
      debugPrint('📦 [UPLOAD_MATERIAL] Saving material record to database...');
      final insertResult = await DatabaseHelpers.safeInsert(
        supabase: supabase,
        table: 'materials',
        data: finalMaterialData,
      );

      if (insertResult == null || insertResult.containsKey('error')) {
        debugPrint('❌ [UPLOAD_MATERIAL] Failed to save material record: ${insertResult?['error']}');
        
        // Try to clean up uploaded file
        try {
          debugPrint('🧹 [UPLOAD_MATERIAL] Attempting to clean up uploaded file...');
          await supabase.storage.from('materials').remove([fileName]);
          debugPrint('✅ [UPLOAD_MATERIAL] File cleaned up successfully');
        } catch (cleanupError) {
          debugPrint("⚠️ [UPLOAD_MATERIAL] Error cleaning up file: $cleanupError");
        }
        
        throw Exception(insertResult?['error'] ?? 'Failed to save material record');
      }

      debugPrint('✅ [UPLOAD_MATERIAL] Material uploaded successfully - ID: ${insertResult['id']}');
      return true;
    } on FileSizeLimitException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint("❌ [UPLOAD_MATERIAL] Error uploading material: $e");
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<List<MaterialModel>> getClassroomMaterials(String classId) async {
    try {
      // Validate class ID
      if (classId.isEmpty || !Validators.isValidUUID(classId)) {
        print("Invalid class ID: $classId");
        return [];
      }

      final response = await DatabaseHelpers.safeGetList(
        supabase: supabase,
        table: 'materials',
        filters: {'class_room_id': classId},
        orderBy: 'created_at',
        ascending: false,
      );

      print("📥 Raw response: ${response.length} materials");

      final materials = <MaterialModel>[];
      for (var json in response) {
        try {
          materials.add(MaterialModel.fromJson(Map<String, dynamic>.from(json)));
        } catch (e) {
          print("Error parsing material: $e");
          // Continue with other materials
        }
      }

      return materials;
    } catch (e) {
      print("Error fetching classroom materials: $e");
      return [];
    }
  }

  static Future<List<MaterialModel>> fetchStudentMaterials() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        print("No logged in student");
        return [];
      }

      if (user.id.isEmpty) {
        print("Invalid user ID");
        return [];
      }

      final enrollments = await DatabaseHelpers.safeGetList(
        supabase: supabase,
        table: 'student_enrollments',
        filters: {'student_id': user.id},
      );

      if (enrollments.isEmpty) return [];

      final classIds = enrollments
          .map((e) => DatabaseHelpers.safeStringFromResult(e, 'class_room_id'))
          .where((id) => id.isNotEmpty && Validators.isValidUUID(id))
          .toList();

      if (classIds.isEmpty) return [];

      // Fetch materials for all classes
      final allMaterials = <MaterialModel>[];
      for (final classId in classIds) {
        try {
          final materials = await getClassroomMaterials(classId);
          allMaterials.addAll(materials);
        } catch (e) {
          print("Error fetching materials for class $classId: $e");
          // Continue with other classes
        }
      }

      return allMaterials;
    } catch (e) {
      print("Error fetching student materials: $e");
      return [];
    }
  }

  static Future<bool> deleteMaterial(int materialId) async {
    try {
      if (materialId <= 0) {
        print("Invalid material ID: $materialId");
        return false;
      }

      final material = await DatabaseHelpers.safeGetSingle(
        supabase: supabase,
        table: 'materials',
        filters: {'id': materialId},
      );

      if (material == null) {
        print("Material not found: $materialId");
        return false;
      }

      final fileUrl = DatabaseHelpers.safeStringFromResult(material, 'material_file_url');
      
      // Try to delete file from storage if URL contains path
      if (fileUrl.isNotEmpty && fileUrl.contains("materials/")) {
        try {
          final path = fileUrl.split("/").last;
          if (path.isNotEmpty) {
            await supabase.storage.from('materials').remove([path]);
          }
        } catch (storageError) {
          print("Error deleting file from storage: $storageError");
          // Continue with database deletion even if storage deletion fails
        }
      }

      final deleteSuccess = await DatabaseHelpers.safeDelete(
        supabase: supabase,
        table: 'materials',
        id: materialId.toString(),
      );

      return deleteSuccess;
    } catch (e) {
      print("Error deleting material: $e");
      return false;
    }
  }

  static Future<List<MaterialModel>> getMaterialsByType(
      String classId, String type) async {
    try {
      // Validate class ID
      if (classId.isEmpty || !Validators.isValidUUID(classId)) {
        print("Invalid class ID: $classId");
        return [];
      }

      final response = await DatabaseHelpers.safeGetList(
        supabase: supabase,
        table: 'materials',
        filters: {
          'class_room_id': classId,
          'material_type': type,
        },
        orderBy: 'created_at',
        ascending: false,
      );

      final materials = <MaterialModel>[];
      for (var json in response) {
        try {
          materials.add(MaterialModel.fromJson(Map<String, dynamic>.from(json)));
        } catch (e) {
          print("Error parsing material: $e");
          // Continue with other materials
        }
      }

      return materials;
    } catch (e) {
      print("Error fetching materials by type: $e");
      return [];
    }
  }
}
