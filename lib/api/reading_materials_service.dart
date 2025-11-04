import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/validators.dart';
import '../utils/database_helpers.dart';

class ReadingMaterial {
  final String id;
  final String levelId;
  final String title;
  final String? description;
  final String fileUrl;
  final String uploadedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? levelNumber;

  ReadingMaterial({
    required this.id,
    required this.levelId,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
    this.levelNumber,
  });

  factory ReadingMaterial.fromJson(Map<String, dynamic> json) {
    return ReadingMaterial(
      id: json['id'] as String,
      levelId: json['level_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String,
      uploadedBy: json['uploaded_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      levelNumber: json['level_number'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level_id': levelId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'level_number': levelNumber,
    };
  }
}

class ReadingMaterialsService {
  static final supabase = Supabase.instance.client;

  /// Upload a new reading material (Teacher only)
  static Future<Map<String, dynamic>?> uploadReadingMaterial({
    required File file,
    required String title,
    required String levelId,
    String? description,
  }) async {
    try {
      debugPrint('📚 [READING_MATERIAL] Starting upload - Title: $title, Level: $levelId');

      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ [READING_MATERIAL] No authenticated user');
        return {'error': 'User not authenticated'};
      }

      // 1️⃣ Validate inputs
      if (title.trim().isEmpty) {
        return {'error': 'Material title is required'};
      }

      if (levelId.isEmpty || !Validators.isValidUUID(levelId)) {
        return {'error': 'Invalid reading level ID'};
      }

      // 2️⃣ Verify reading level exists
      final levelExists = await supabase
          .from('reading_levels')
          .select('id, level_number')
          .eq('id', levelId)
          .maybeSingle();

      if (levelExists == null) {
        debugPrint('❌ [READING_MATERIAL] Reading level not found: $levelId');
        return {'error': 'Reading level not found'};
      }

      // 3️⃣ Validate file
      if (!await file.exists()) {
        return {'error': 'File does not exist'};
      }

      final fileSize = await file.length();
      const maxSize = 50 * 1024 * 1024; // 50MB
      if (fileSize > maxSize) {
        return {'error': 'File size exceeds 50MB limit'};
      }

      final fileExtension = file.path.split('.').last.toLowerCase();
      if (fileExtension != 'pdf') {
        return {'error': 'Only PDF files are allowed for reading materials'};
      }

      debugPrint('✅ [READING_MATERIAL] File validation passed - Size: ${fileSize / 1024 / 1024}MB');

      // 4️⃣ Upload to Supabase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedTitle = title.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final fileName = "reading_materials/$levelId/${timestamp}_$sanitizedTitle.$fileExtension";

      debugPrint('📚 [READING_MATERIAL] Uploading to storage: $fileName');

      final fileBytes = await file.readAsBytes();
      await supabase.storage.from('materials').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'application/pdf',
        ),
      );

      debugPrint('✅ [READING_MATERIAL] File uploaded to storage');

      // 5️⃣ Get public URL
      final publicUrl = supabase.storage.from('materials').getPublicUrl(fileName);
      if (publicUrl.isEmpty) {
        return {'error': 'Failed to get file URL'};
      }

      debugPrint('✅ [READING_MATERIAL] Public URL: $publicUrl');

      // 6️⃣ Insert into reading_materials table
      final materialData = {
        'level_id': levelId,
        'title': title.trim(),
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
        'file_url': publicUrl,
        'uploaded_by': user.id,
      };

      debugPrint('📚 [READING_MATERIAL] Saving to database...');
      final insertResult = await DatabaseHelpers.safeInsert(
        supabase: supabase,
        table: 'reading_materials',
        data: materialData,
      );

      if (insertResult == null || insertResult.containsKey('error')) {
        debugPrint('❌ [READING_MATERIAL] Database insert failed: ${insertResult?['error']}');
        
        // Cleanup uploaded file
        try {
          await supabase.storage.from('materials').remove([fileName]);
        } catch (e) {
          debugPrint('⚠️ [READING_MATERIAL] Failed to cleanup file: $e');
        }
        
        return insertResult ?? {'error': 'Failed to save material record'};
      }

      debugPrint('✅ [READING_MATERIAL] Material saved successfully - ID: ${insertResult['id']}');
      
      // 7️⃣ Sync to task_materials for all tasks in this reading level
      try {
        debugPrint('📚 [READING_MATERIAL] Syncing to reading tasks...');
        
        // Find all tasks with this reading_level_id
        final tasksRes = await supabase
            .from('tasks')
            .select('id')
            .eq('reading_level_id', levelId);
        
        if (tasksRes.isNotEmpty) {
          final taskIds = (tasksRes as List)
              .map((t) => t['id'] as String?)
              .whereType<String>()
              .where((id) => Validators.isValidUUID(id))
              .toList();
          
          debugPrint('📚 [READING_MATERIAL] Found ${taskIds.length} tasks for level $levelId');
          
          // Insert material into task_materials for each task
          for (final taskId in taskIds) {
            try {
              await DatabaseHelpers.safeInsert(
                supabase: supabase,
                table: 'task_materials',
                data: {
                  'task_id': taskId,
                  'material_title': title.trim(),
                  if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
                  'material_file_path': fileName, // Store the storage path, not the full URL
                  'material_type': 'pdf',
                },
              );
              debugPrint('✅ [READING_MATERIAL] Synced to task: $taskId');
            } catch (taskError) {
              debugPrint('⚠️ [READING_MATERIAL] Failed to sync to task $taskId: $taskError');
              // Continue with other tasks even if one fails
            }
          }
          
          debugPrint('✅ [READING_MATERIAL] Material synced to ${taskIds.length} tasks');
        } else {
          debugPrint('ℹ️ [READING_MATERIAL] No tasks found for level $levelId - skipping sync');
        }
      } catch (syncError) {
        debugPrint('⚠️ [READING_MATERIAL] Error syncing to tasks (non-critical): $syncError');
        // Don't fail the upload if sync fails - material is already saved
      }
      
      return insertResult;
    } catch (e, stackTrace) {
      debugPrint('❌ [READING_MATERIAL] Error uploading material: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'error': 'Failed to upload material: ${e.toString()}'};
    }
  }

  /// Get all reading materials (Teacher view - all materials)
  static Future<List<ReadingMaterial>> getAllReadingMaterials() async {
    try {
      debugPrint('📚 [READING_MATERIAL] Fetching all materials');

      final response = await supabase
          .from('reading_materials')
          .select('''
            *,
            reading_levels(level_number)
          ''')
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final data = Map<String, dynamic>.from(json);
        final levelData = data['reading_levels'] as Map<String, dynamic>?;
        return ReadingMaterial.fromJson({
          ...data,
          'level_number': levelData?['level_number'],
        });
      }).toList();
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching materials: $e');
      return [];
    }
  }

  /// Get reading materials for a specific level (Student view)
  static Future<List<ReadingMaterial>> getReadingMaterialsByLevel(String levelId) async {
    try {
      debugPrint('📚 [READING_MATERIAL] Fetching materials for level: $levelId');

      final response = await supabase
          .from('reading_materials')
          .select('''
            *,
            reading_levels(level_number)
          ''')
          .eq('level_id', levelId)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final data = Map<String, dynamic>.from(json);
        final levelData = data['reading_levels'] as Map<String, dynamic>?;
        return ReadingMaterial.fromJson({
          ...data,
          'level_number': levelData?['level_number'],
        });
      }).toList();
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching materials by level: $e');
      return [];
    }
  }

  /// Get reading materials for student's current level
  static Future<List<ReadingMaterial>> getReadingMaterialsForStudent(String studentId) async {
    try {
      debugPrint('📚 [READING_MATERIAL] Fetching materials for student: $studentId');

      // Get student's current reading level
      final studentResponse = await supabase
          .from('students')
          .select('current_reading_level_id')
          .eq('id', studentId)
          .maybeSingle();

      if (studentResponse == null || studentResponse['current_reading_level_id'] == null) {
        debugPrint('⚠️ [READING_MATERIAL] Student has no reading level assigned');
        return [];
      }

      final levelId = studentResponse['current_reading_level_id'] as String;
      return await getReadingMaterialsByLevel(levelId);
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching student materials: $e');
      return [];
    }
  }

  /// Update reading material (Teacher only)
  static Future<bool> updateReadingMaterial({
    required String materialId,
    String? title,
    String? description,
    String? levelId,
  }) async {
    try {
      debugPrint('📚 [READING_MATERIAL] Updating material: $materialId');

      final updateData = <String, dynamic>{};
      if (title != null && title.trim().isNotEmpty) {
        updateData['title'] = title.trim();
      }
      if (description != null) {
        updateData['description'] = description.trim().isEmpty ? null : description.trim();
      }
      if (levelId != null && Validators.isValidUUID(levelId)) {
        updateData['level_id'] = levelId;
      }

      if (updateData.isEmpty) {
        return true; // Nothing to update
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      await supabase
          .from('reading_materials')
          .update(updateData)
          .eq('id', materialId);

      debugPrint('✅ [READING_MATERIAL] Material updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error updating material: $e');
      return false;
    }
  }

  /// Delete reading material (Teacher only)
  static Future<bool> deleteReadingMaterial(String materialId) async {
    try {
      debugPrint('📚 [READING_MATERIAL] Deleting material: $materialId');

      // Get material to find file URL and title for syncing deletion
      final material = await supabase
          .from('reading_materials')
          .select('file_url, title, level_id')
          .eq('id', materialId)
          .maybeSingle();

      String? filePath;
      String? materialTitle;
      String? levelId;

      if (material != null) {
        final fileUrl = material['file_url'] as String?;
        materialTitle = material['title'] as String?;
        levelId = material['level_id'] as String?;
        
        if (fileUrl != null && fileUrl.contains('materials/reading_materials/')) {
          // Extract file path from URL
          try {
            final uri = Uri.parse(fileUrl);
            final pathSegments = uri.pathSegments;
            final materialIndex = pathSegments.indexOf('materials');
            if (materialIndex >= 0 && materialIndex < pathSegments.length - 1) {
              filePath = pathSegments.sublist(materialIndex + 1).join('/');
              await supabase.storage.from('materials').remove([filePath]);
              debugPrint('✅ [READING_MATERIAL] File deleted from storage');
            }
          } catch (e) {
            debugPrint('⚠️ [READING_MATERIAL] Failed to delete file from storage: $e');
          }
        }
      }

      // Delete from task_materials (sync deletion to reading tasks)
      try {
        debugPrint('📚 [READING_MATERIAL] Removing from reading tasks...');
        
        if (filePath != null || materialTitle != null) {
          // Find and delete matching task_materials
          // Match by file_path if available, otherwise by material_title
          final taskMaterialsQuery = supabase
              .from('task_materials')
              .select('id')
              .eq('material_type', 'pdf');
          
          if (filePath != null) {
            // Try matching by file path first
            final matchingByPath = await taskMaterialsQuery
                .eq('material_file_path', filePath)
                .limit(100); // Get all matches
            
            if (matchingByPath.isNotEmpty) {
              final ids = (matchingByPath as List)
                  .map((tm) => tm['id'] as String?)
                  .whereType<String>()
                  .toList();
              
              if (ids.isNotEmpty) {
                await supabase
                    .from('task_materials')
                    .delete()
                    .inFilter('id', ids);
                debugPrint('✅ [READING_MATERIAL] Removed ${ids.length} materials from tasks (by path)');
              }
            }
          }
          
          // Also try matching by title if file path didn't work or as additional check
          if (materialTitle != null && levelId != null) {
            // Get all tasks for this level
            final tasksRes = await supabase
                .from('tasks')
                .select('id')
                .eq('reading_level_id', levelId);
            
            if (tasksRes.isNotEmpty) {
              final taskIds = (tasksRes as List)
                  .map((t) => t['id'] as String?)
                  .whereType<String>()
                  .where((id) => Validators.isValidUUID(id))
                  .toList();
              
              // Delete task_materials with matching title for these tasks
              for (final taskId in taskIds) {
                try {
                  await supabase
                      .from('task_materials')
                      .delete()
                      .eq('task_id', taskId)
                      .eq('material_title', materialTitle)
                      .eq('material_type', 'pdf');
                } catch (e) {
                  debugPrint('⚠️ [READING_MATERIAL] Failed to delete from task $taskId: $e');
                }
              }
              debugPrint('✅ [READING_MATERIAL] Removed materials from ${taskIds.length} tasks (by title)');
            }
          }
        }
      } catch (syncError) {
        debugPrint('⚠️ [READING_MATERIAL] Error syncing deletion to tasks (non-critical): $syncError');
        // Continue with deletion even if sync fails
      }

      // Delete database record
      await supabase.from('reading_materials').delete().eq('id', materialId);

      debugPrint('✅ [READING_MATERIAL] Material deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error deleting material: $e');
      return false;
    }
  }

  /// Get all reading levels for dropdown
  static Future<List<Map<String, dynamic>>> getAllReadingLevels() async {
    try {
      final response = await supabase
          .from('reading_levels')
          .select('id, level_number, title')
          .order('level_number', ascending: true);

      return (response as List).map((json) => Map<String, dynamic>.from(json)).toList();
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching reading levels: $e');
      return [];
    }
  }

  /// Get student submissions for a reading material
  static Future<List<Map<String, dynamic>>> getSubmissionsForMaterial(String materialId) async {
    try {
      debugPrint('📚 [READING_MATERIAL] Fetching submissions for material: $materialId');

      // Get recordings linked to this material
      // Note: We'll need to link recordings to materials via a material_id field
      // For now, we'll check if task_id matches or add material_id to student_recordings
      final response = await supabase
          .from('student_recordings')
          .select('''
            *,
            students(student_name, username)
          ''')
          .eq('task_id', materialId) // Assuming material_id is stored in task_id for now
          .order('created_at', ascending: false);

      return (response as List).map((json) => Map<String, dynamic>.from(json)).toList();
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching submissions: $e');
      return [];
    }
  }

  /// Submit student recording for a reading material
  static Future<Map<String, dynamic>?> submitReadingRecording({
    required String studentId,
    required String materialId,
    required String recordingFilePath,
  }) async {
    try {
      debugPrint('📚 [READING_MATERIAL] Submitting recording - Student: $studentId, Material: $materialId');

      final file = File(recordingFilePath);
      if (!await file.exists()) {
        return {'error': 'Recording file does not exist'};
      }

      // Upload recording to storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'student_recordings/$studentId/${materialId}_$timestamp.m4a';

      debugPrint('📚 [READING_MATERIAL] Uploading recording: $fileName');

      final fileBytes = await file.readAsBytes();
      await supabase.storage.from('student_voice').uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'audio/m4a',
        ),
      );

      final publicUrl = supabase.storage.from('student_voice').getPublicUrl(fileName);

      // Insert into student_recordings
      // Note: task_id has FK constraint to tasks table, so we set it to NULL for materials
      // and store material_id in teacher_comments as JSON metadata
      final recordingData = {
        'student_id': studentId,
        'task_id': null, // NULL because material_id doesn't exist in tasks table
        'recording_url': publicUrl,
        'file_url': publicUrl,
        'recorded_at': DateTime.now().toIso8601String(),
        'needs_grading': true,
        'teacher_comments': '{"material_id": "$materialId", "type": "reading_material"}', // Store material_id as metadata
      };

      final insertResult = await DatabaseHelpers.safeInsert(
        supabase: supabase,
        table: 'student_recordings',
        data: recordingData,
      );

      if (insertResult == null || insertResult.containsKey('error')) {
        return insertResult ?? {'error': 'Failed to save recording'};
      }

      debugPrint('✅ [READING_MATERIAL] Recording submitted successfully');
      return insertResult;
    } catch (e, stackTrace) {
      debugPrint('❌ [READING_MATERIAL] Error submitting recording: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'error': 'Failed to submit recording: ${e.toString()}'};
    }
  }

  /// Check if student has submitted recording for a material
  static Future<Map<String, dynamic>?> getStudentSubmission({
    required String studentId,
    required String materialId,
  }) async {
    try {
      // Query by looking for material_id in teacher_comments JSON
      // Also check file_path pattern as backup
      final response = await supabase
          .from('student_recordings')
          .select('*')
          .eq('student_id', studentId)
          .isFilter('task_id', null) // task_id is NULL for materials
          .like('teacher_comments', '%"material_id": "$materialId"%')
          .maybeSingle();

      // If not found, try backup query by file path pattern
      if (response == null) {
        final backupResponse = await supabase
            .from('student_recordings')
            .select('*')
            .eq('student_id', studentId)
            .isFilter('task_id', null)
            .like('file_url', '%$materialId%')
            .maybeSingle();
        
        if (backupResponse != null) {
          return Map<String, dynamic>.from(backupResponse);
        }
      }

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching student submission: $e');
      return null;
    }
  }
}

