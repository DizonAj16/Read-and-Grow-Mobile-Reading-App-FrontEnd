import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/validators.dart';
import '../utils/database_helpers.dart';
import '../utils/file_validator.dart';

class ReadingMaterial {
  final String id;
  final String title;
  final String? description;
  final String fileUrl;
  final String? audioUrl; // NEW: Add audio URL field
  final String? levelId;
  final int? levelNumber;
  final String? levelTitle;
  final DateTime createdAt;
  final String? uploadedBy;
  final String? className;
  final String? classRoomId;
  final bool? hasPrerequisite;
  final String? prerequisiteId;
  final String? prerequisiteTitle;
  final DateTime updatedAt;

  ReadingMaterial({
    required this.id,
    required this.title,
    this.description,
    required this.fileUrl,
    this.audioUrl, // NEW
    this.levelId,
    this.levelNumber,
    this.levelTitle,
    required this.createdAt,
    this.uploadedBy,
    this.className,
    this.classRoomId,
    this.hasPrerequisite,
    this.prerequisiteId,
    this.prerequisiteTitle,
    required this.updatedAt,
  });

  factory ReadingMaterial.fromJson(Map<String, dynamic> json) {
    return ReadingMaterial(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String,
      audioUrl: json['audio_url'] as String?, // NEW
      levelId: json['level_id'] as String?,
      levelNumber: json['level_number'] as int?,
      levelTitle: json['level_title'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      uploadedBy: json['uploaded_by'] as String?,
      className: json['class_name'] as String?,
      classRoomId: json['class_room_id'] as String?,
      hasPrerequisite:
          json['has_prerequisite'] as bool? ?? json['prerequisite_id'] != null,
      prerequisiteId: json['prerequisite_id'] as String?,
      prerequisiteTitle: json['prerequisite_title'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level_id': levelId,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'audio_url': audioUrl, // NEW
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'level_number': levelNumber,
      'class_name': className,
      'class_room_id': classRoomId,
      'prerequisite_id': prerequisiteId,
      'prerequisite_title': prerequisiteTitle,
    };
  }
}

class ReadingMaterialsService {
  static final supabase = Supabase.instance.client;

/// Upload a new reading material (Teacher only) - optionally assign to classroom
static Future<Map<String, dynamic>?> uploadReadingMaterial({
  required File file,
  required String title,
  required String levelId,
  String? description,
  String? classroomId,
  String? prerequisiteId,
  File? audioFile,
}) async {
  Uint8List? fileBytes;
  Uint8List? audioFileBytes;
  File? tempAudioFile;
  String? audioTempPath;

  try {
    debugPrint('=== START OF UPLOAD FUNCTION ===');
    debugPrint(
      '📚 [READING_MATERIAL] Starting upload - Title: $title, Level: $levelId, Classroom: $classroomId, Prerequisite: $prerequisiteId, Has Audio: ${audioFile != null}',
    );

    // 1️⃣ Read main file bytes with retry logic
    debugPrint('📚 [READING_MATERIAL] Reading main file from: ${file.path}');
    
    try {
      // Check if file exists
      final fileExists = await file.exists();
      debugPrint('📚 [READING_MATERIAL] Main file exists: $fileExists');
      
      if (!fileExists) {
        return {'error': 'Main file not found. Please select the file again.'};
      }
      
      fileBytes = await file.readAsBytes();
      debugPrint('📚 [READING_MATERIAL] Main file bytes loaded: ${fileBytes.length}');
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error reading main file: $e');
      return {'error': 'Failed to read main file. Please select the file again.'};
    }

    // 2️⃣ Read audio file bytes if provided
    if (audioFile != null) {
      debugPrint('📚 [READING_MATERIAL] Reading audio file from: ${audioFile.path}');
      
      try {
        final audioExists = await audioFile.exists();
        debugPrint('📚 [READING_MATERIAL] Audio file exists: $audioExists');
        
        if (audioExists) {
          audioFileBytes = await audioFile.readAsBytes();
          debugPrint('📚 [READING_MATERIAL] Audio bytes loaded: ${audioFileBytes.length}');
          
          // Create a temporary copy of the audio file to ensure it stays available
          final tempDir = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          audioTempPath = '${tempDir.path}/audio_temp_${timestamp}.m4a';
          tempAudioFile = File(audioTempPath);
          await tempAudioFile!.writeAsBytes(audioFileBytes!);
          debugPrint('📚 [READING_MATERIAL] Audio temp file created: $audioTempPath');
        } else {
          debugPrint('⚠️ [READING_MATERIAL] Audio file does not exist, continuing without audio');
        }
      } catch (e) {
        debugPrint('❌ [READING_MATERIAL] Error reading audio file: $e');
        // Don't fail the entire upload if audio reading fails
      }
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('❌ [READING_MATERIAL] No authenticated user');
      return {'error': 'User not authenticated'};
    }

    // 3️⃣ Validate inputs
    debugPrint('📚 [READING_MATERIAL] Step 1: Validating inputs');
    if (title.trim().isEmpty) {
      return {'error': 'Material title is required'};
    }

    if (levelId.isEmpty || !Validators.isValidUUID(levelId)) {
      return {'error': 'Invalid reading level ID'};
    }

    // 4️⃣ Verify reading level exists
    debugPrint('📚 [READING_MATERIAL] Step 2: Verifying reading level');
    final levelExists = await supabase
        .from('reading_levels')
        .select('id, level_number')
        .eq('id', levelId)
        .maybeSingle();

    if (levelExists == null) {
      debugPrint('❌ [READING_MATERIAL] Reading level not found: $levelId');
      return {'error': 'Reading level not found'};
    }
    debugPrint('✅ [READING_MATERIAL] Reading level verified');

    // 5️⃣ Validate prerequisite exists if provided
    if (prerequisiteId != null && prerequisiteId.isNotEmpty) {
      debugPrint('📚 [READING_MATERIAL] Step 3: Validating prerequisite');
      final prerequisiteExists = await supabase
          .from('reading_materials')
          .select('id, title, level_id')
          .eq('id', prerequisiteId)
          .maybeSingle();

      if (prerequisiteExists == null) {
        debugPrint(
          '❌ [READING_MATERIAL] Prerequisite material not found: $prerequisiteId',
        );
        return {'error': 'Prerequisite reading material not found'};
      }
      debugPrint('✅ [READING_MATERIAL] Prerequisite verified');
    }

    // 6️⃣ Validate classroom exists if classroomId is provided
    if (classroomId != null && classroomId.isNotEmpty) {
      debugPrint('📚 [READING_MATERIAL] Step 4: Validating classroom');
      final classroomExists = await supabase
          .from('class_rooms')
          .select('id, class_name')
          .eq('id', classroomId)
          .maybeSingle();

      if (classroomExists == null) {
        debugPrint('❌ [READING_MATERIAL] Classroom not found: $classroomId');
        return {'error': 'Classroom not found'};
      }
      debugPrint('✅ [READING_MATERIAL] Classroom verified');
    }

    // 7️⃣ Validate main file using the bytes
    debugPrint('📚 [READING_MATERIAL] Step 5: Validating main file');
    
    final fileExtension = file.path.split('.').last.toLowerCase();
    debugPrint('📚 [READING_MATERIAL] File extension: $fileExtension');
    final allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

    if (!allowedExtensions.contains(fileExtension)) {
      debugPrint('❌ [READING_MATERIAL] Invalid file extension');
      return {
        'error':
            'Only PDF and image files (JPG, JPEG, PNG) are allowed for reading materials',
      };
    }

    // Validate file size
    debugPrint('📚 [READING_MATERIAL] Checking file size...');
    final fileSize = fileBytes.length;
    debugPrint('📚 [READING_MATERIAL] File size: $fileSize bytes');
    
    if (fileSize == 0) {
      debugPrint('❌ [READING_MATERIAL] File is empty');
      return {'error': 'Selected file is empty'};
    }
    
    if (fileSize > 10 * 1024 * 1024) { // 10MB limit
      debugPrint('❌ [READING_MATERIAL] File is too large: ${fileSize / (1024 * 1024)} MB');
      return {'error': 'File size must be less than 10MB'};
    }

    // Determine file type and content type
    String fileType = 'pdf';
    String contentType = 'application/pdf';

    if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
      fileType = 'image';
      if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (fileExtension == 'png') {
        contentType = 'image/png';
      }
    }
    debugPrint('📚 [READING_MATERIAL] File type: $fileType, Content type: $contentType');

    // 8️⃣ Validate audio file if provided
    debugPrint('📚 [READING_MATERIAL] Step 6: Validating audio file');
    String? audioUrl;
    
    if (audioFileBytes != null && audioFileBytes.isNotEmpty) {
      final audioExtension = audioFile!.path.split('.').last.toLowerCase();
      debugPrint('📚 [READING_MATERIAL] Audio extension: $audioExtension');
      final allowedAudioExtensions = ['m4a', 'mp3', 'wav', 'aac'];

      if (!allowedAudioExtensions.contains(audioExtension)) {
        return {
          'error': 'Only M4A, MP3, WAV, and AAC audio files are allowed',
        };
      }
      
      // Validate audio file size
      final audioSize = audioFileBytes.length;
      debugPrint('📚 [READING_MATERIAL] Audio file size: $audioSize bytes');
      
      if (audioSize == 0) {
        debugPrint('⚠️ [READING_MATERIAL] Audio file is empty, skipping');
      } else if (audioSize > 5 * 1024 * 1024) { // 5MB limit for audio
        debugPrint('⚠️ [READING_MATERIAL] Audio file is too large: ${audioSize / (1024 * 1024)} MB, skipping');
      } else {
        debugPrint('✅ [READING_MATERIAL] Audio file type and size valid');
      }
    }

    // 9️⃣ Upload to Supabase Storage using bytes
    debugPrint('📚 [READING_MATERIAL] Step 7: Uploading to storage');
    final sanitizedTitle = title.trim().replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        classroomId != null
            ? "reading_materials/class_$classroomId/$levelId/${timestamp}_$sanitizedTitle.$fileExtension"
            : "reading_materials/$levelId/${timestamp}_$sanitizedTitle.$fileExtension";

    debugPrint('📚 [READING_MATERIAL] Storage path: $storagePath');

    try {
      debugPrint('📚 [READING_MATERIAL] Uploading main file to Supabase storage...');
      
      await supabase.storage
          .from('materials')
          .uploadBinary(
            storagePath,
            fileBytes!,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );
      debugPrint('✅ [READING_MATERIAL] Main file uploaded to storage');
    } catch (e, stackTrace) {
      debugPrint('❌ [READING_MATERIAL] Error uploading main file: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'error': 'Failed to upload file to storage: ${e.toString()}'};
    }

    // 🔟 Get public URL
    debugPrint('📚 [READING_MATERIAL] Step 8: Getting public URL');
    final publicUrl = supabase.storage
        .from('materials')
        .getPublicUrl(storagePath);
    debugPrint('📚 [READING_MATERIAL] Public URL: $publicUrl');

    // 1️⃣1️⃣ Upload audio file if provided
    if (audioFileBytes != null && audioFileBytes.isNotEmpty && audioFileBytes.length > 0 && audioFileBytes.length <= 5 * 1024 * 1024) {
      debugPrint('📚 [READING_MATERIAL] Step 9: Uploading audio file');
      try {
        final audioExtension = audioFile!.path.split('.').last.toLowerCase();
        final audioStoragePath =
            classroomId != null
                ? "teacher_instructions/class_$classroomId/$levelId/${timestamp}_${sanitizedTitle}_instruction.$audioExtension"
                : "teacher_instructions/$levelId/${timestamp}_${sanitizedTitle}_instruction.$audioExtension";

        debugPrint('📚 [READING_MATERIAL] Audio storage path: $audioStoragePath');
        
        await supabase.storage
            .from('materials')
            .uploadBinary(
              audioStoragePath,
              audioFileBytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: 'audio/m4a',
              ),
            );

        // Get public URL for audio
        audioUrl = supabase.storage
            .from('materials')
            .getPublicUrl(audioStoragePath);

        debugPrint('✅ [READING_MATERIAL] Audio uploaded: $audioUrl');
      } catch (e) {
        debugPrint('❌ [READING_MATERIAL] Error uploading audio: $e');
        // Don't fail the entire upload if audio fails
      }
    }

    // 1️⃣2️⃣ Insert into reading_materials table
    debugPrint('📚 [READING_MATERIAL] Step 10: Inserting into database');
    final materialData = {
      'level_id': levelId,
      'title': title.trim(),
      'file_url': publicUrl,
      'uploaded_by': user.id,
      'prerequisite_id': prerequisiteId,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (classroomId != null) 'class_room_id': classroomId,
    };

    debugPrint('📚 [READING_MATERIAL] Material data: $materialData');
    
    final insertResult = await DatabaseHelpers.safeInsert(
      supabase: supabase,
      table: 'reading_materials',
      data: materialData,
    );

    debugPrint('📚 [READING_MATERIAL] Insert result: $insertResult');

    if (insertResult == null || insertResult.containsKey('error')) {
      debugPrint(
        '❌ [READING_MATERIAL] Database insert failed: ${insertResult?['error']}',
      );

      // Cleanup uploaded files
      try {
        await supabase.storage.from('materials').remove([storagePath]);
        if (audioUrl != null) {
          final audioPath = audioUrl!.split('materials/').last;
          await supabase.storage.from('materials').remove([audioPath]);
        }
      } catch (e) {
        debugPrint('⚠️ [READING_MATERIAL] Failed to cleanup files: $e');
      }

      return insertResult ?? {'error': 'Failed to save material record'};
    }

    final materialId = insertResult['id'] as String?;
    debugPrint('✅ [READING_MATERIAL] Material saved successfully - ID: $materialId');

    // 1️⃣3️⃣ Link material to classroom if classroomId is provided
    if (classroomId != null && classroomId.isNotEmpty && materialId != null) {
      try {
        await _linkMaterialToClassroom(
          classroomId: classroomId,
          materialId: materialId,
          assignedBy: user.id,
        );
        debugPrint(
          '✅ [READING_MATERIAL] Material linked to classroom: $classroomId',
        );
      } catch (linkError) {
        debugPrint(
          '⚠️ [READING_MATERIAL] Failed to link material to classroom: $linkError',
        );
      }
    }

    // 1️⃣4️⃣ Sync to task_materials for all tasks in this reading level
    try {
      await _syncMaterialToTasks(
        materialId: materialId!,
        title: title.trim(),
        description: description,
        filePath: storagePath,
        fileType: fileType,
        levelId: levelId,
        classRoomId: classroomId,
        prerequisiteId: prerequisiteId,
        audioUrl: audioUrl,
      );
    } catch (syncError) {
      debugPrint(
        '⚠️ [READING_MATERIAL] Error syncing to tasks (non-critical): $syncError',
      );
    }

    debugPrint('=== END OF UPLOAD FUNCTION - SUCCESS ===');
    return insertResult;
  } catch (e, stackTrace) {
    debugPrint('❌ [READING_MATERIAL] Unhandled error in uploadReadingMaterial: $e');
    debugPrint('Stack trace: $stackTrace');
    return {'error': 'Unexpected error occurred: ${e.toString()}'};
  } finally {
    // Clean up temporary audio file
    if (tempAudioFile != null && await tempAudioFile!.exists()) {
      try {
        await tempAudioFile!.delete();
        debugPrint('🗑️ [READING_MATERIAL] Cleaned up temp audio file');
      } catch (e) {
        debugPrint('⚠️ [READING_MATERIAL] Error cleaning up temp audio file: $e');
      }
    }
  }
}

  /// Link a reading material to a classroom
  static Future<bool> _linkMaterialToClassroom({
    required String classroomId,
    required String materialId,
    required String assignedBy,
  }) async {
    try {
      final linkData = {
        'classroom_id': classroomId,
        'reading_material_id': materialId,
        'assigned_by': assignedBy,
      };

      await DatabaseHelpers.safeInsert(
        supabase: supabase,
        table: 'classroom_reading_materials',
        data: linkData,
      );

      return true;
    } catch (e) {
      debugPrint(
        '❌ [READING_MATERIAL] Error linking material to classroom: $e',
      );
      return false;
    }
  }

  /// Sync material to tasks (modified to include prerequisite)
  /// Sync material to tasks (modified to include prerequisite and audio)
  static Future<void> _syncMaterialToTasks({
    required String materialId,
    required String title,
    String? description,
    required String filePath,
    required String fileType,
    required String levelId,
    String? classRoomId,
    String? prerequisiteId,
    String? audioUrl, // NEW: Include audio URL
  }) async {
    try {
      debugPrint('📚 [READING_MATERIAL] Syncing to reading tasks...');

      // Find all tasks with this reading_level_id
      var tasksQuery = supabase.from('tasks').select('id');

      // If classRoomId is provided, filter tasks for that specific class
      if (classRoomId != null && classRoomId.isNotEmpty) {
        tasksQuery = tasksQuery.eq('class_room_id', classRoomId);
      }

      // Also filter by reading level
      final tasksRes = await tasksQuery.eq('reading_level_id', levelId);

      if (tasksRes.isNotEmpty) {
        final taskIds =
            (tasksRes as List)
                .map((t) => t['id'] as String?)
                .whereType<String>()
                .where((id) => Validators.isValidUUID(id))
                .toList();

        debugPrint(
          '📚 [READING_MATERIAL] Found ${taskIds.length} tasks for level $levelId, Class: $classRoomId',
        );

        // Insert material into task_materials for each task
        for (final taskId in taskIds) {
          try {
            await DatabaseHelpers.safeInsert(
              supabase: supabase,
              table: 'task_materials',
              data: {
                'task_id': taskId,
                'material_title': title,
                if (description != null && description.trim().isNotEmpty)
                  'description': description.trim(),
                'material_file_path': filePath,
                'material_type': fileType,
                if (prerequisiteId != null && prerequisiteId.isNotEmpty)
                  'prerequisite_material_id': prerequisiteId,
                if (audioUrl != null && audioUrl.isNotEmpty)
                  'audio_url': audioUrl, // NEW: Store audio URL
              },
            );
            debugPrint('✅ [READING_MATERIAL] Synced to task: $taskId');
          } catch (taskError) {
            debugPrint(
              '⚠️ [READING_MATERIAL] Failed to sync to task $taskId: $taskError',
            );
          }
        }

        debugPrint(
          '✅ [READING_MATERIAL] Material synced to ${taskIds.length} tasks',
        );
      } else {
        debugPrint(
          'ℹ️ [READING_MATERIAL] No tasks found for level $levelId, Class: $classRoomId - skipping sync',
        );
      }
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error syncing to tasks: $e');
      rethrow;
    }
  }

  /// Get all reading materials with optional classroom filter - updated to include prerequisite info
  static Future<List<ReadingMaterial>> getAllReadingMaterials({
    String? classroomId,
  }) async {
    try {
      debugPrint(
        '📚 [READING_MATERIAL] Fetching materials, Classroom: $classroomId',
      );

      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ [READING_MATERIAL] No authenticated user');
        return [];
      }

      // If classroomId is provided, get materials linked to that classroom
      if (classroomId != null && classroomId.isNotEmpty) {
        return await getReadingMaterialsByClassroom(classroomId);
      }

      // Otherwise, get all materials uploaded by current teacher with prerequisite info
      final response = await supabase
          .from('reading_materials')
          .select('''
          *,
          reading_levels(level_number, title),
          class_rooms(class_name),
          prerequisite:prerequisite_id(id, title)
        ''')
          .eq('uploaded_by', user.id)
          .order('created_at', ascending: false);

      return (response as List).map((json) {
        final data = Map<String, dynamic>.from(json);
        final levelData = data['reading_levels'] as Map<String, dynamic>?;
        final classData = data['class_rooms'] as Map<String, dynamic>?;
        final prerequisiteData = data['prerequisite'] as Map<String, dynamic>?;

        return ReadingMaterial.fromJson({
          ...data,
          'level_number': levelData?['level_number'],
          'level_title': levelData?['title'],
          'class_name': classData?['class_name'],
          'prerequisite_title': prerequisiteData?['title'],
        });
      }).toList();
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching materials: $e');
      return [];
    }
  }

  /// Get reading materials for a specific classroom - updated to include prerequisite info
  static Future<List<ReadingMaterial>> getReadingMaterialsByClassroom(
    String classroomId,
  ) async {
    try {
      debugPrint(
        '📚 [READING_MATERIAL] Fetching materials for classroom: $classroomId',
      );

      // Get materials where class_room_id matches or are linked through junction table
      final directResponse = await supabase
          .from('reading_materials')
          .select('''
          *,
          reading_levels(level_number, title),
          class_rooms(class_name),
          prerequisite:prerequisite_id(id, title)
        ''')
          .eq('class_room_id', classroomId)
          .order('created_at', ascending: false);

      // Also get materials linked through the junction table (for backward compatibility)
      final junctionResponse = await supabase
          .from('classroom_reading_materials')
          .select('''
          reading_material_id,
          reading_materials (
            *,
            reading_levels(level_number, title),
            class_rooms(class_name),
            prerequisite:prerequisite_id(id, title)
          ),
          class_rooms(class_name)
        ''')
          .eq('classroom_id', classroomId)
          .order('assigned_at', ascending: false);

      // Combine results
      final directMaterials =
          (directResponse as List).map((json) {
            final data = Map<String, dynamic>.from(json);
            final levelData = data['reading_levels'] as Map<String, dynamic>?;
            final classData = data['class_rooms'] as Map<String, dynamic>?;
            final prerequisiteData =
                data['prerequisite'] as Map<String, dynamic>?;

            return ReadingMaterial.fromJson({
              ...data,
              'level_number': levelData?['level_number'],
              'level_title': levelData?['title'],
              'class_name': classData?['class_name'],
              'prerequisite_title': prerequisiteData?['title'],
            });
          }).toList();

      final junctionMaterials =
          (junctionResponse as List)
              .map((json) {
                final data = Map<String, dynamic>.from(json);
                final materialData =
                    data['reading_materials'] as Map<String, dynamic>?;
                final classData = data['class_rooms'] as Map<String, dynamic>?;

                if (materialData == null) return null;

                final levelData =
                    materialData['reading_levels'] as Map<String, dynamic>?;
                final prerequisiteData =
                    materialData['prerequisite'] as Map<String, dynamic>?;

                return ReadingMaterial.fromJson({
                  ...materialData,
                  'level_number': levelData?['level_number'],
                  'level_title': levelData?['title'],
                  'class_name': classData?['class_name'],
                  'prerequisite_title': prerequisiteData?['title'],
                });
              })
              .whereType<ReadingMaterial>()
              .toList();

      // Merge and deduplicate by material ID
      final allMaterials = [...directMaterials, ...junctionMaterials];
      final uniqueMaterials = <String, ReadingMaterial>{};

      for (final material in allMaterials) {
        uniqueMaterials[material.id] = material;
      }

      return uniqueMaterials.values.toList();
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching classroom materials: $e');
      return [];
    }
  }

  /// Get reading materials for a specific level (Student view) - with optional class filter
  /// Updated to include prerequisite info and check for student completion
  static Future<List<Map<String, dynamic>>>
  getReadingMaterialsByLevelForStudent(
    String levelId,
    String studentId, {
    String? classRoomId,
  }) async {
    try {
      debugPrint(
        '📚 [READING_MATERIAL] Fetching materials for level: $levelId, Student: $studentId, Class: $classRoomId',
      );

      var query = supabase
          .from('reading_materials')
          .select('''
          *,
          reading_levels(level_number, title),
          class_rooms(class_name),
          prerequisite:prerequisite_id(id, title)
        ''')
          .eq('level_id', levelId);

      // Filter by class_room_id if provided
      if (classRoomId != null && classRoomId.isNotEmpty) {
        query = query.eq('class_room_id', classRoomId);
      } else {
        // If no class filter, get materials not assigned to any specific class (null class_room_id)
        query = query.isFilter('class_room_id', null);
      }

      final response = await query.order('created_at', ascending: false);

      final materials =
          (response as List).map((json) {
            final data = Map<String, dynamic>.from(json);
            final levelData = data['reading_levels'] as Map<String, dynamic>?;
            final classData = data['class_rooms'] as Map<String, dynamic>?;
            final prerequisiteData =
                data['prerequisite'] as Map<String, dynamic>?;

            return {
              'material': ReadingMaterial.fromJson({
                ...data,
                'level_number': levelData?['level_number'],
                'level_title': levelData?['title'],
                'class_name': classData?['class_name'],
                'prerequisite_title': prerequisiteData?['title'],
              }),
              'prerequisite_id': data['prerequisite_id'] as String?,
            };
          }).toList();

      // Check completion status for each material with prerequisite
      final result = <Map<String, dynamic>>[];

      for (final item in materials) {
        final material = item['material'] as ReadingMaterial;
        final prerequisiteId = item['prerequisite_id'] as String?;

        bool isAccessible = true;
        bool hasCompletedPrerequisite = true;
        String? prerequisiteTitle = material.prerequisiteTitle;

        if (prerequisiteId != null && prerequisiteId.isNotEmpty) {
          // Check if student has completed the prerequisite
          hasCompletedPrerequisite = await hasStudentCompletedPrerequisite(
            studentId: studentId,
            prerequisiteId: prerequisiteId,
            classId: classRoomId,
          );
          isAccessible = hasCompletedPrerequisite;
        }

        // Check if student has already completed this material
        final hasCompletedMaterial =
            await getStudentSubmission(
              studentId: studentId,
              materialId: material.id,
              classId: classRoomId,
            ) !=
            null;

        result.add({
          'material': material,
          'is_accessible': isAccessible,
          'has_completed_prerequisite': hasCompletedPrerequisite,
          'has_completed_material': hasCompletedMaterial,
          'prerequisite_title': prerequisiteTitle,
        });
      }

      return result;
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching materials by level: $e');
      return [];
    }
  }

  /// NEW: Check if student has completed a prerequisite material
  static Future<bool> hasStudentCompletedPrerequisite({
    required String studentId,
    required String prerequisiteId,
    String? classId,
  }) async {
    try {
      debugPrint(
        '📚 [READING_MATERIAL] Checking prerequisite completion - Student: $studentId, Prerequisite: $prerequisiteId, Class: $classId',
      );

      var query = supabase
          .from('student_recordings')
          .select('id')
          .eq('student_id', studentId)
          .eq('material_id', prerequisiteId);

      // If classId is provided, filter by class_id
      if (classId != null && classId.isNotEmpty) {
        query = query.eq('class_id', classId);
      }

      final response = await query.maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint(
        '❌ [READING_MATERIAL] Error checking prerequisite completion: $e',
      );
      return false;
    }
  }

  /// Get reading materials for student's current level with class context
  /// Updated to include prerequisite checking
  static Future<List<Map<String, dynamic>>> getReadingMaterialsForStudent(
    String studentId, {
    String? classId,
  }) async {
    try {
      debugPrint(
        '📚 [READING_MATERIAL] Fetching materials for student: $studentId, Class: $classId',
      );

      // Get student's current reading level
      final studentResponse =
          await supabase
              .from('students')
              .select('current_reading_level_id')
              .eq('id', studentId)
              .maybeSingle();

      if (studentResponse == null ||
          studentResponse['current_reading_level_id'] == null) {
        debugPrint(
          '⚠️ [READING_MATERIAL] Student has no reading level assigned',
        );
        return [];
      }

      final levelId = studentResponse['current_reading_level_id'] as String;
      return await getReadingMaterialsByLevelForStudent(
        levelId,
        studentId,
        classRoomId: classId,
      );
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching student materials: $e');
      return [];
    }
  }

  /// Update reading material (Teacher only) - updated to include prerequisite
  /// Update reading material (Teacher only) - updated to include prerequisite and audio
  static Future<bool> updateReadingMaterial({
    required String materialId,
    String? title,
    String? description,
    String? levelId,
    String? classRoomId,
    String? prerequisiteId,
    String? audioUrl, // NEW: Update audio URL
  }) async {
    try {
      debugPrint('📚 [READING_MATERIAL] Updating material: $materialId');

      final updateData = <String, dynamic>{};
      if (title != null && title.trim().isNotEmpty) {
        updateData['title'] = title.trim();
      }
      if (description != null) {
        updateData['description'] =
            description.trim().isEmpty ? null : description.trim();
      }
      if (levelId != null && Validators.isValidUUID(levelId)) {
        updateData['level_id'] = levelId;
      }
      if (classRoomId != null) {
        updateData['class_room_id'] = classRoomId.isEmpty ? null : classRoomId;
      }
      if (prerequisiteId != null) {
        updateData['prerequisite_id'] =
            prerequisiteId.isEmpty ? null : prerequisiteId;
      }
      if (audioUrl != null) {
        updateData['audio_url'] = audioUrl.isEmpty ? null : audioUrl; // NEW
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

  static Future<bool> deleteReadingMaterial(String materialId) async {
    try {
      debugPrint('📚 [READING_MATERIAL] Deleting material: $materialId');

      // Get material to find file URL and title for syncing deletion
      final material =
          await supabase
              .from('reading_materials')
              .select(
                'file_url, audio_url, title, level_id, class_room_id, prerequisite_id',
              )
              .eq('id', materialId)
              .maybeSingle();

      String? filePath;
      String? audioPath;
      String? materialTitle;
      String? levelId;
      String? classRoomId;
      String? prerequisiteId;

      if (material != null) {
        final fileUrl = material['file_url'] as String?;
        final audioUrl = material['audio_url'] as String?; // NEW
        materialTitle = material['title'] as String?;
        levelId = material['level_id'] as String?;
        classRoomId = material['class_room_id'] as String?;
        prerequisiteId = material['prerequisite_id'] as String?;

        // Delete main file
        if (fileUrl != null && fileUrl.contains('materials/')) {
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
            debugPrint(
              '⚠️ [READING_MATERIAL] Failed to delete file from storage: $e',
            );
          }
        }

        // NEW: Delete audio file if exists
        if (audioUrl != null &&
            audioUrl.isNotEmpty &&
            audioUrl.contains('materials/')) {
          try {
            final audioUri = Uri.parse(audioUrl);
            final audioPathSegments = audioUri.pathSegments;
            final audioMaterialIndex = audioPathSegments.indexOf('materials');
            if (audioMaterialIndex >= 0 &&
                audioMaterialIndex < audioPathSegments.length - 1) {
              audioPath = audioPathSegments
                  .sublist(audioMaterialIndex + 1)
                  .join('/');
              await supabase.storage.from('materials').remove([audioPath]);
              debugPrint(
                '✅ [READING_MATERIAL] Audio file deleted from storage',
              );
            }
          } catch (e) {
            debugPrint(
              '⚠️ [READING_MATERIAL] Failed to delete audio file from storage: $e',
            );
          }
        }
      }

      // NEW: Find and update any materials that have this material as their prerequisite
      if (materialId != null && materialId.isNotEmpty) {
        try {
          await supabase
              .from('reading_materials')
              .update({
                'prerequisite_id': null,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('prerequisite_id', materialId);
          debugPrint(
            '✅ [READING_MATERIAL] Removed as prerequisite from other materials',
          );
        } catch (e) {
          debugPrint(
            '⚠️ [READING_MATERIAL] Failed to update dependent materials: $e',
          );
        }
      }

      // Delete from classroom_reading_materials (remove from all classrooms - backward compatibility)
      try {
        await supabase
            .from('classroom_reading_materials')
            .delete()
            .eq('reading_material_id', materialId);
        debugPrint(
          '✅ [READING_MATERIAL] Removed from all classrooms (junction)',
        );
      } catch (e) {
        debugPrint(
          '⚠️ [READING_MATERIAL] Failed to remove from classrooms (junction): $e',
        );
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

      return (response as List)
          .map((json) => Map<String, dynamic>.from(json))
          .toList();
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching reading levels: $e');
      return [];
    }
  }

  /// Get student submissions for a reading material
  static Future<List<Map<String, dynamic>>> getSubmissionsForMaterial(
    String materialId,
  ) async {
    try {
      debugPrint(
        '📚 [READING_MATERIAL] Fetching submissions for material: $materialId',
      );

      // Get recordings linked to this material
      final response = await supabase
          .from('student_recordings')
          .select('''
            *,
            students(student_name, username, profile_picture)
          ''')
          .eq('material_id', materialId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Map<String, dynamic>.from(json))
          .toList();
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching submissions: $e');
      return [];
    }
  }

  /// Submit student recording for a reading material with class context
  /// Updated to check prerequisite completion before submission
  static Future<Map<String, dynamic>?> submitReadingRecording({
    required String studentId,
    required String materialId,
    required String recordingFilePath,
    String? classId,
  }) async {
    try {
      debugPrint(
        '📚 [READING_MATERIAL] Submitting recording - Student: $studentId, Material: $materialId, Class: $classId',
      );

      // NEW: Check if material has prerequisite
      final materialResponse =
          await supabase
              .from('reading_materials')
              .select('prerequisite_id, class_room_id')
              .eq('id', materialId)
              .maybeSingle();

      if (materialResponse != null) {
        final prerequisiteId = materialResponse['prerequisite_id'] as String?;
        final materialClassId = materialResponse['class_room_id'] as String?;

        // If material has prerequisite, check if student has completed it
        if (prerequisiteId != null && prerequisiteId.isNotEmpty) {
          final hasCompletedPrerequisite =
              await hasStudentCompletedPrerequisite(
                studentId: studentId,
                prerequisiteId: prerequisiteId,
                classId: classId ?? materialClassId,
              );

          if (!hasCompletedPrerequisite) {
            // Get prerequisite material title for error message
            final prerequisiteMaterial =
                await supabase
                    .from('reading_materials')
                    .select('title')
                    .eq('id', prerequisiteId)
                    .maybeSingle();

            final prerequisiteTitle =
                prerequisiteMaterial?['title'] as String? ??
                'prerequisite material';

            return {
              'error':
                  'You must complete "$prerequisiteTitle" before attempting this reading material',
              'requires_prerequisite': true,
              'prerequisite_id': prerequisiteId,
              'prerequisite_title': prerequisiteTitle,
            };
          }
        }

        // If material is class-specific but no classId provided, or classId doesn't match
        if (materialClassId != null && materialClassId.isNotEmpty) {
          if (classId == null || classId != materialClassId) {
            return {
              'error': 'This reading material is assigned to a different class',
            };
          }
        }
      }

      final file = File(recordingFilePath);
      if (!await file.exists()) {
        return {'error': 'Recording file does not exist'};
      }

      // Upload recording to storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'student_recordings/$studentId/${materialId}_${classId ?? 'global'}_$timestamp.m4a';

      debugPrint('📚 [READING_MATERIAL] Uploading recording: $fileName');

      final fileBytes = await file.readAsBytes();
      await supabase.storage
          .from('student_voice')
          .uploadBinary(
            fileName,
            fileBytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'audio/m4a',
            ),
          );

      final publicUrl = supabase.storage
          .from('student_voice')
          .getPublicUrl(fileName);

      // Create teacher_comments JSON with material_id and optional class_id
      final teacherComments = {
        'material_id': materialId,
        if (classId != null) 'class_id': classId,
        'submitted_at': DateTime.now().toIso8601String(),
      };

      // Insert into student_recordings
      final recordingData = {
        'student_id': studentId,
        'task_id': null, // NULL because this is for reading material
        'material_id': materialId,
        'class_id': classId, // Store class_id directly in student_recordings
        'recording_url': publicUrl,
        'file_url': publicUrl,
        'recorded_at': DateTime.now().toIso8601String(),
        'needs_grading': true,
        'teacher_comments': teacherComments.toString(), // Store as JSON string
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

  /// Check if student has submitted recording for a material with class context
  static Future<Map<String, dynamic>?> getStudentSubmission({
    required String studentId,
    required String materialId,
    String? classId,
  }) async {
    try {
      var query = supabase
          .from('student_recordings')
          .select('*')
          .eq('student_id', studentId)
          .eq('material_id', materialId);

      // Filter by class_id if provided
      if (classId != null && classId.isNotEmpty) {
        query = query.eq('class_id', classId);
      }

      final response = await query.maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching student submission: $e');
      return null;
    }
  }

  /// Assign existing reading material to a classroom
  static Future<bool> assignMaterialToClassroom({
    required String materialId,
    required String classroomId,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ [READING_MATERIAL] No authenticated user');
        return false;
      }

      // Verify material exists and belongs to current teacher
      final material =
          await supabase
              .from('reading_materials')
              .select('id, uploaded_by')
              .eq('id', materialId)
              .eq('uploaded_by', user.id)
              .maybeSingle();

      if (material == null) {
        debugPrint(
          '❌ [READING_MATERIAL] Material not found or not owned by teacher',
        );
        return false;
      }

      // Verify classroom exists
      final classroom =
          await supabase
              .from('class_rooms')
              .select('id')
              .eq('id', classroomId)
              .maybeSingle();

      if (classroom == null) {
        debugPrint('❌ [READING_MATERIAL] Classroom not found');
        return false;
      }

      // Update material's class_room_id
      await supabase
          .from('reading_materials')
          .update({
            'class_room_id': classroomId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', materialId);

      // Also link through junction table for backward compatibility
      await _linkMaterialToClassroom(
        classroomId: classroomId,
        materialId: materialId,
        assignedBy: user.id,
      );

      debugPrint(
        '✅ [READING_MATERIAL] Material assigned to classroom successfully',
      );
      return true;
    } catch (e) {
      debugPrint(
        '❌ [READING_MATERIAL] Error assigning material to classroom: $e',
      );
      return false;
    }
  }

  /// Remove reading material from a classroom
  static Future<bool> removeMaterialFromClassroom({
    required String materialId,
    required String classroomId,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ [READING_MATERIAL] No authenticated user');
        return false;
      }

      // Set class_room_id to null for this material
      await supabase
          .from('reading_materials')
          .update({
            'class_room_id': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', materialId)
          .eq('class_room_id', classroomId);

      // Also remove from junction table for backward compatibility
      await supabase
          .from('classroom_reading_materials')
          .delete()
          .eq('classroom_id', classroomId)
          .eq('reading_material_id', materialId);

      debugPrint('✅ [READING_MATERIAL] Material removed from classroom');
      return true;
    } catch (e) {
      debugPrint(
        '❌ [READING_MATERIAL] Error removing material from classroom: $e',
      );
      return false;
    }
  }

  /// Get all reading materials not yet assigned to a classroom
  static Future<List<ReadingMaterial>> getUnassignedReadingMaterials({
    required String classroomId,
  }) async {
    try {
      debugPrint(
        '📚 [READING_MATERIAL] Fetching unassigned materials for classroom: $classroomId',
      );

      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ [READING_MATERIAL] No authenticated user');
        return [];
      }

      // Get all materials uploaded by teacher that are not assigned to any class
      final allMaterials = await supabase
          .from('reading_materials')
          .select('''
            *,
            reading_levels(level_number, title),
            class_rooms(class_name),
            prerequisite:prerequisite_id(id, title)
          ''')
          .eq('uploaded_by', user.id)
          .isFilter(
            'class_room_id',
            null,
          ) // Only materials not assigned to any class
          .order('created_at', ascending: false);

      // Also filter out materials already linked through junction table (backward compatibility)
      final assignedMaterialsRes = await supabase
          .from('classroom_reading_materials')
          .select('reading_material_id')
          .eq('classroom_id', classroomId);

      final assignedMaterialIds =
          (assignedMaterialsRes as List)
              .map((item) => item['reading_material_id'] as String?)
              .whereType<String>()
              .toSet();

      // Filter out already assigned materials
      return (allMaterials as List)
          .map((json) {
            final data = Map<String, dynamic>.from(json);
            final materialId = data['id'] as String?;

            // Skip if material is already assigned to this classroom through junction table
            if (materialId != null &&
                assignedMaterialIds.contains(materialId)) {
              return null;
            }

            final levelData = data['reading_levels'] as Map<String, dynamic>?;
            final classData = data['class_rooms'] as Map<String, dynamic>?;
            final prerequisiteData =
                data['prerequisite'] as Map<String, dynamic>?;

            return ReadingMaterial.fromJson({
              ...data,
              'level_number': levelData?['level_number'],
              'level_title': levelData?['title'],
              'class_name': classData?['class_name'],
              'prerequisite_title': prerequisiteData?['title'],
            });
          })
          .whereType<ReadingMaterial>()
          .toList();
    } catch (e) {
      debugPrint(
        '❌ [READING_MATERIAL] Error fetching unassigned materials: $e',
      );
      return [];
    }
  }

  /// Get classrooms where a material is assigned
  static Future<List<Map<String, dynamic>>> getMaterialClassrooms(
    String materialId,
  ) async {
    try {
      // First check direct assignment through class_room_id
      final directResponse = await supabase
          .from('reading_materials')
          .select('''
            class_room_id,
            class_rooms(class_name, grade_level, section)
          ''')
          .eq('id', materialId);

      final directResults = <Map<String, dynamic>>[];

      if (directResponse.isNotEmpty) {
        final data = Map<String, dynamic>.from(directResponse[0]);
        final classRoomId = data['class_room_id'] as String?;
        final classData = data['class_rooms'] as Map<String, dynamic>?;

        if (classRoomId != null && classData != null) {
          directResults.add({
            'classroom_id': classRoomId,
            'class_name': classData['class_name'],
            'grade_level': classData['grade_level'],
            'section': classData['section'],
            'assigned_type': 'direct',
          });
        }
      }

      // Also check junction table for backward compatibility
      final junctionResponse = await supabase
          .from('classroom_reading_materials')
          .select('''
            classroom_id,
            class_rooms(class_name, grade_level, section),
            assigned_at
          ''')
          .eq('reading_material_id', materialId)
          .order('assigned_at', ascending: false);

      final junctionResults =
          (junctionResponse as List).map((json) {
            final data = Map<String, dynamic>.from(json);
            final classroomData = data['class_rooms'] as Map<String, dynamic>?;

            return {
              'classroom_id': data['classroom_id'],
              'class_name': classroomData?['class_name'],
              'grade_level': classroomData?['grade_level'],
              'section': classroomData?['section'],
              'assigned_at': data['assigned_at'],
              'assigned_type': 'junction',
            };
          }).toList();

      // Merge results, preferring direct assignments
      final allResults = [...directResults, ...junctionResults];
      final uniqueResults = <String, Map<String, dynamic>>{};

      for (final result in allResults) {
        final classroomId = result['classroom_id'] as String?;
        if (classroomId != null) {
          // If we already have this classroom, prefer direct assignment
          if (!uniqueResults.containsKey(classroomId) ||
              result['assigned_type'] == 'direct') {
            uniqueResults[classroomId] = result;
          }
        }
      }

      return uniqueResults.values.toList();
    } catch (e) {
      debugPrint('❌ [READING_MATERIAL] Error fetching material classrooms: $e');
      return [];
    }
  }

  /// Get reading materials by multiple criteria for filtering - updated to include prerequisite
  static Future<List<ReadingMaterial>> getReadingMaterialsByFilters({
    String? levelId,
    String? classRoomId,
    String? searchQuery,
    int? limit,
    bool? hasPrerequisite, // NEW: Filter by prerequisite status
  }) async {
    try {
      debugPrint(
        '📚 [READING_MATERIAL] Fetching materials with filters - Level: $levelId, Class: $classRoomId, Search: $searchQuery, HasPrerequisite: $hasPrerequisite',
      );

      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ [READING_MATERIAL] No authenticated user');
        return [];
      }

      // Start with a PostgrestFilterBuilder
      PostgrestFilterBuilder<dynamic> query = supabase
          .from('reading_materials')
          .select('''
        *,
        reading_levels(level_number, title),
        class_rooms(class_name),
        prerequisite:prerequisite_id(id, title)
      ''')
          .eq('uploaded_by', user.id);

      if (levelId != null && levelId.isNotEmpty) {
        query = query.eq('level_id', levelId);
      }

      if (classRoomId != null) {
        if (classRoomId.isEmpty) {
          // Get materials not assigned to any class
          query = query.isFilter('class_room_id', null);
        } else {
          query = query.eq('class_room_id', classRoomId);
        }
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      // NEW: Filter by prerequisite status
      if (hasPrerequisite != null) {
        if (hasPrerequisite) {
          query = query.not('prerequisite_id', 'is', null);
        } else {
          query = query.isFilter('prerequisite_id', null);
        }
      }

      // After using filter methods, we need to handle ordering and limiting
      // Cast to dynamic to handle the type transition
      var finalQuery = query.order('created_at', ascending: false);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      // Execute the query
      final response = await finalQuery;

      return (response as List).map((json) {
        final data = Map<String, dynamic>.from(json);
        final levelData = data['reading_levels'] as Map<String, dynamic>?;
        final classData = data['class_rooms'] as Map<String, dynamic>?;
        final prerequisiteData = data['prerequisite'] as Map<String, dynamic>?;

        return ReadingMaterial.fromJson({
          ...data,
          'level_number': levelData?['level_number'],
          'level_title': levelData?['title'],
          'class_name': classData?['class_name'],
          'prerequisite_title': prerequisiteData?['title'],
        });
      }).toList();
    } catch (e) {
      debugPrint(
        '❌ [READING_MATERIAL] Error fetching materials with filters: $e',
      );
      return [];
    }
  }

  /// NEW: Get available prerequisites for a material (excluding the material itself and its dependents)
  static Future<List<Map<String, dynamic>>> getAvailablePrerequisites({
    String? currentMaterialId,
    String? classroomId,
  }) async {
    try {
      debugPrint(
        '📚 [READING_MATERIAL] Fetching available prerequisites - Current Material: $currentMaterialId, Classroom: $classroomId',
      );

      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ [READING_MATERIAL] No authenticated user');
        return [];
      }

      // Start with query for all materials uploaded by current teacher
      var query = supabase
          .from('reading_materials')
          .select('''
            id,
            title,
            level_id,
            reading_levels(level_number, title)
          ''')
          .eq('uploaded_by', user.id);

      // If classroomId is provided, include materials for that classroom
      if (classroomId != null && classroomId.isNotEmpty) {
        query = query.or(
          'class_room_id.eq.${classroomId},class_room_id.is.null',
        );
      }

      // Exclude current material if provided
      if (currentMaterialId != null && currentMaterialId.isNotEmpty) {
        query = query.neq('id', currentMaterialId);
      }

      final response = await query.order('title', ascending: true);

      return (response as List).map((json) {
        final data = Map<String, dynamic>.from(json);
        final levelData = data['reading_levels'] as Map<String, dynamic>?;
        return {
          'id': data['id'] as String,
          'title': data['title'] as String,
          'level_id': data['level_id'] as String?,
          'level_number': levelData?['level_number'] as int?,
          'level_title': levelData?['title'] as String?,
        };
      }).toList();
    } catch (e) {
      debugPrint(
        '❌ [READING_MATERIAL] Error fetching available prerequisites: $e',
      );
      return [];
    }
  }

  /// NEW: Check for circular dependencies when setting prerequisites
  static Future<bool> validatePrerequisiteChain({
    required String materialId,
    required String prerequisiteId,
  }) async {
    try {
      debugPrint(
        '📚 [READING_MATERIAL] Validating prerequisite chain - Material: $materialId, Prerequisite: $prerequisiteId',
      );

      // Start with the potential prerequisite
      String currentId = prerequisiteId;
      Set<String> visited = {
        materialId,
      }; // Start with current material to prevent self-reference

      // Follow the chain to check for circular dependencies
      while (currentId.isNotEmpty) {
        if (visited.contains(currentId)) {
          // Circular dependency detected
          debugPrint('❌ [READING_MATERIAL] Circular dependency detected');
          return false;
        }

        visited.add(currentId);

        // Get the prerequisite of the current material
        final material =
            await supabase
                .from('reading_materials')
                .select('prerequisite_id')
                .eq('id', currentId)
                .maybeSingle();

        if (material == null) {
          break;
        }

        final nextPrerequisiteId = material['prerequisite_id'] as String?;
        if (nextPrerequisiteId == null || nextPrerequisiteId.isEmpty) {
          break;
        }

        currentId = nextPrerequisiteId;
      }

      return true;
    } catch (e) {
      debugPrint(
        '❌ [READING_MATERIAL] Error validating prerequisite chain: $e',
      );
      return false;
    }
  }
}
