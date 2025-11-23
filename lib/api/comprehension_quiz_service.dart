import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing comprehension quiz flow:
/// Read Lesson/Material → Take Quiz → Unlock Next Lesson/Material
class ComprehensionQuizService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // LESSON READING METHODS
  // ============================================================================

  /// Start reading a lesson/material (creates reading record)
  /// Returns the reading record ID
  Future<String?> startReadingLesson({
    required String studentId,
    required int materialId, // materials.id is bigint
    required String classRoomId,
    String? taskId,
  }) async {
    try {
      final result = await _supabase.from('lesson_readings').insert({
        'student_id': studentId,
        'material_id': materialId,
        'class_room_id': classRoomId,
        'task_id': taskId,
        'started_at': DateTime.now().toIso8601String(),
        'is_completed': false,
      }).select('id').single();

      debugPrint('✅ [COMPREHENSION_QUIZ] Started reading lesson: ${result['id']}');
      return result['id'] as String?;
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error starting lesson reading: $e');
      rethrow;
    }
  }

  /// Mark lesson/material as completed
  Future<bool> completeLessonReading({
    required String studentId,
    required int materialId, // materials.id is bigint
    int readingDurationSeconds = 0,
    int pagesViewed = 0,
    int lastPageViewed = 0,
  }) async {
    try {
      final result = await _supabase
          .from('lesson_readings')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
            'reading_duration_seconds': readingDurationSeconds,
            'pages_viewed': pagesViewed,
            'last_page_viewed': lastPageViewed,
          })
          .eq('student_id', studentId)
          .eq('material_id', materialId)
          .select();

      if (result.isEmpty) {
        debugPrint('⚠️ [COMPREHENSION_QUIZ] No reading record found to update');
        return false;
      }

      debugPrint('✅ [COMPREHENSION_QUIZ] Lesson reading completed');
      return true;
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error completing lesson reading: $e');
      return false;
    }
  }

  /// Update reading progress (for tracking page views, etc.)
  Future<bool> updateReadingProgress({
    required String studentId,
    required int materialId, // materials.id is bigint
    int? pagesViewed,
    int? lastPageViewed,
    int? readingDurationSeconds,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (pagesViewed != null) updates['pages_viewed'] = pagesViewed;
      if (lastPageViewed != null) updates['last_page_viewed'] = lastPageViewed;
      if (readingDurationSeconds != null) {
        updates['reading_duration_seconds'] = readingDurationSeconds;
      }

      if (updates.isEmpty) return true;

      await _supabase
          .from('lesson_readings')
          .update(updates)
          .eq('student_id', studentId)
          .eq('material_id', materialId);

      return true;
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error updating reading progress: $e');
      return false;
    }
  }

  /// Check if student has read a lesson/material
  Future<bool> hasReadLesson({
    required String studentId,
    required int materialId, // materials.id is bigint
  }) async {
    try {
      final result = await _supabase.rpc('has_read_lesson', params: {
        'p_student_id': studentId,
        'p_material_id': materialId,
      });

      return result ?? false;
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error checking lesson reading: $e');
      return false;
    }
  }

  /// Get reading progress for a lesson/material
  Future<Map<String, dynamic>?> getReadingProgress({
    required String studentId,
    required int materialId, // materials.id is bigint
  }) async {
    try {
      final result = await _supabase
          .from('lesson_readings')
          .select()
          .eq('student_id', studentId)
          .eq('material_id', materialId)
          .maybeSingle();

      return result;
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error getting reading progress: $e');
      return null;
    }
  }

  /// Get all lessons/materials read by student
  Future<List<Map<String, dynamic>>> getStudentReadLessons({
    required String studentId,
    String? classRoomId,
  }) async {
    try {
      var query = _supabase
          .from('lesson_readings')
          .select('*, materials(*), class_rooms(*)')
          .eq('student_id', studentId)
          .eq('is_completed', true);

      if (classRoomId != null) {
        query = query.eq('class_room_id', classRoomId);
      }

      final queryResult = await query.order('completed_at', ascending: false);
      return List<Map<String, dynamic>>.from(queryResult);
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error getting student read lessons: $e');
      return [];
    }
  }

  // ============================================================================
  // QUIZ VALIDATION METHODS
  // ============================================================================

  /// Check if student can take a quiz
  /// Returns validation result with reason
  Future<Map<String, dynamic>> canTakeQuiz({
    required String studentId,
    required String quizId,
    int? materialId, // materials.id is bigint
  }) async {
    try {
      final result = await _supabase.rpc('can_take_quiz', params: {
        'p_student_id': studentId,
        'p_quiz_id': quizId,
        'p_material_id': materialId,
      });

      return result as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error validating quiz prerequisites: $e');
      return {
        'can_take': false,
        'reason': 'Error validating quiz prerequisites: $e',
      };
    }
  }

  /// Get next attempt number for a quiz
  Future<int> getNextQuizAttempt({
    required String studentId,
    required String quizId,
  }) async {
    try {
      final result = await _supabase.rpc('get_next_quiz_attempt', params: {
        'p_student_id': studentId,
        'p_quiz_id': quizId,
      });

      return result ?? 1;
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error getting next attempt: $e');
      return 1; // Default to first attempt
    }
  }

  // ============================================================================
  // QUIZ COMPLETION METHODS
  // ============================================================================

  /// Submit quiz completion
  /// Automatically unlocks next lesson/material if quiz is passed
  Future<Map<String, dynamic>> submitQuizCompletion({
    required String studentId,
    required String quizId,
    required String taskId,
    required String classRoomId,
    required int score,
    required int maxScore,
    int? materialId, // materials.id is bigint
    double passingThreshold = 0.7,
    int timeTakenSeconds = 0,
  }) async {
    try {
      // Get next attempt number
      final attemptNumber = await getNextQuizAttempt(
        studentId: studentId,
        quizId: quizId,
      );

      // Calculate if passed
      final passed = (score / maxScore) >= passingThreshold;

      // Insert quiz completion (trigger will unlock level if passed)
      final result = await _supabase
          .from('quiz_completions')
          .insert({
            'student_id': studentId,
            'quiz_id': quizId,
            'task_id': taskId,
            'lesson_material_id': materialId, // Use lesson_material_id for materials table (bigint)
            'class_room_id': classRoomId,
            'score': score,
            'max_score': maxScore,
            'passed': passed,
            'passing_threshold': passingThreshold,
            'attempt_number': attemptNumber,
            'time_taken_seconds': timeTakenSeconds,
          })
          .select()
          .single();

      final completionData = Map<String, dynamic>.from(result);
      final nextMaterialUnlocked = completionData['next_material_unlocked'] as int?;

      debugPrint('✅ [COMPREHENSION_QUIZ] Quiz completion submitted');
      if (nextMaterialUnlocked != null) {
        debugPrint('🎉 [COMPREHENSION_QUIZ] Next lesson unlocked: $nextMaterialUnlocked');
      }

      return {
        'success': true,
        'completion_id': completionData['id'],
        'passed': passed,
        'score': score,
        'max_score': maxScore,
        'score_percentage': (score / maxScore) * 100,
        'next_material_unlocked': nextMaterialUnlocked,
        'attempt_number': attemptNumber,
      };
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error submitting quiz completion: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get quiz completion history for a student
  Future<List<Map<String, dynamic>>> getStudentQuizCompletions({
    required String studentId,
    String? quizId,
    String? levelId,
    bool? passed,
  }) async {
    try {
      var query = _supabase
          .from('quiz_completions')
          .select('*, quizzes(*), tasks(*), class_rooms(*)')
          .eq('student_id', studentId)
          .not('lesson_material_id', 'is', null); // Only lesson quizzes

      if (quizId != null) {
        query = query.eq('quiz_id', quizId);
      }

      if (levelId != null) {
        query = query.eq('class_room_id', levelId); // Using class_room_id instead
      }

      if (passed != null) {
        query = query.eq('passed', passed);
      }

      final result = await query.order('completed_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error getting quiz completions: $e');
      return [];
    }
  }

  /// Get quiz completion statistics for a student
  Future<Map<String, dynamic>> getStudentQuizStats({
    required String studentId,
    String? levelId,
  }) async {
    try {
      var query = _supabase
          .from('quiz_completions')
          .select('score, max_score, passed, class_room_id')
          .eq('student_id', studentId);

      if (levelId != null) {
        query = query.eq('class_room_id', levelId); // Using class_room_id instead
      }

      final result = await query;
      final completions = List<Map<String, dynamic>>.from(result);

      if (completions.isEmpty) {
        return {
          'total_quizzes': 0,
          'quizzes_passed': 0,
          'quizzes_failed': 0,
          'average_score': 0.0,
          'pass_rate': 0.0,
        };
      }

      final totalQuizzes = completions.length;
      final quizzesPassed = completions.where((c) => c['passed'] == true).length;
      final quizzesFailed = totalQuizzes - quizzesPassed;

      double totalScore = 0;
      double totalMaxScore = 0;

      for (var completion in completions) {
        totalScore += (completion['score'] as num).toDouble();
        totalMaxScore += (completion['max_score'] as num).toDouble();
      }

      final averageScore = totalMaxScore > 0 ? (totalScore / totalMaxScore) * 100 : 0.0;
      final passRate = totalQuizzes > 0 ? (quizzesPassed / totalQuizzes) * 100 : 0.0;

      return {
        'total_quizzes': totalQuizzes,
        'quizzes_passed': quizzesPassed,
        'quizzes_failed': quizzesFailed,
        'average_score': averageScore,
        'pass_rate': passRate,
      };
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error getting quiz stats: $e');
      return {
        'total_quizzes': 0,
        'quizzes_passed': 0,
        'quizzes_failed': 0,
        'average_score': 0.0,
        'pass_rate': 0.0,
      };
    }
  }

  // ============================================================================
  // LESSON UNLOCKING METHODS
  // ============================================================================

  /// Get unlocked lessons/materials for a student
  Future<List<int>> getUnlockedLessons(String studentId) async {
    try {
      final result = await _supabase
          .from('quiz_completions')
          .select('next_material_unlocked')
          .eq('student_id', studentId)
          .not('next_material_unlocked', 'is', null);

      final materials = <int>{};
      for (var row in result) {
        final materialId = row['next_material_unlocked'] as int?;
        if (materialId != null) {
          materials.add(materialId);
        }
      }

      return materials.toList();
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error getting unlocked lessons: $e');
      return [];
    }
  }

  /// Check if a lesson/material is unlocked for a student
  Future<bool> isLessonUnlocked({
    required String studentId,
    required int materialId, // materials.id is bigint
  }) async {
    try {
      final unlockedLessons = await getUnlockedLessons(studentId);
      return unlockedLessons.contains(materialId);
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error checking lesson unlock: $e');
      return false;
    }
  }

  // ============================================================================
  // COMPLETE FLOW METHODS
  // ============================================================================

  /// Complete the full flow: Read Lesson → Take Quiz → Unlock Next Lesson
  Future<Map<String, dynamic>> completeComprehensionFlow({
    required String studentId,
    required int materialId, // materials.id is bigint
    required String quizId,
    required String taskId,
    required String classRoomId,
    required int quizScore,
    required int quizMaxScore,
    int readingDurationSeconds = 0,
    int timeTakenSeconds = 0,
    double passingThreshold = 0.7,
  }) async {
    try {
      // Step 1: Ensure lesson is marked as read
      final hasRead = await hasReadLesson(
        studentId: studentId,
        materialId: materialId,
      );

      if (!hasRead) {
        await completeLessonReading(
          studentId: studentId,
          materialId: materialId,
          readingDurationSeconds: readingDurationSeconds,
        );
      }

      // Step 2: Validate quiz prerequisites
      final validation = await canTakeQuiz(
        studentId: studentId,
        quizId: quizId,
        materialId: materialId,
      );

      if (validation['can_take'] != true) {
        return {
          'success': false,
          'error': validation['reason'] ?? 'Cannot take quiz',
          'validation': validation,
        };
      }

      // Step 3: Submit quiz completion
      final result = await submitQuizCompletion(
        studentId: studentId,
        quizId: quizId,
        taskId: taskId,
        classRoomId: classRoomId,
        score: quizScore,
        maxScore: quizMaxScore,
        materialId: materialId,
        passingThreshold: passingThreshold,
        timeTakenSeconds: timeTakenSeconds,
      );

      return result;
    } catch (e) {
      debugPrint('❌ [COMPREHENSION_QUIZ] Error completing flow: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

