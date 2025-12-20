import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassroomAnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get comprehensive analytics for a specific classroom
  Future<Map<String, dynamic>> getClassAnalytics({
    required String classId,
    required String teacherId,
  }) async {
    try {
      debugPrint(
        '📊 [Analytics] Starting analytics for class: $classId, teacher: $teacherId',
      );

      // Get class info
      debugPrint('📊 [Analytics] Fetching class info...');
      final classInfo =
          await _supabase
              .from('class_rooms')
              .select()
              .eq('id', classId)
              .single();

      // Get enrolled students with their details
      debugPrint('📊 [Analytics] Fetching enrolled students...');
      final enrolledStudents = await _supabase
          .from('student_enrollments')
          .select('student_id')
          .eq('class_room_id', classId);

      final studentIds =
          enrolledStudents
              .map((e) => e['student_id'] as String?)
              .where((id) => id != null)
              .cast<String>()
              .toList();

      final totalStudents = studentIds.length;

      // If no students, return empty analytics
      if (studentIds.isEmpty) {
        debugPrint(
          '📊 [Analytics] No students enrolled, returning empty analytics',
        );
        return _getEmptyAnalytics(classInfo['class_name'] ?? 'Class');
      }

      // Get student details for valid students WITH reading levels
      debugPrint('📊 [Analytics] Fetching student details...');
      final studentsData = await _supabase
          .from('students')
          .select('''
            id,
            student_name,
            profile_picture,
            student_lrn,
            student_grade,
            student_section,
            current_reading_level_id,
            reading_levels!inner(id, level_number, title)
          ''')
          .inFilter('id', studentIds);

      debugPrint('📊 [Analytics] Found ${studentsData.length} student records');

      // Create a map of student ID to student data for easy lookup
      final Map<String, Map<String, dynamic>> studentDataMap = {};
      for (final student in studentsData) {
        final studentId = student['id'] as String?;
        if (studentId != null) {
          studentDataMap[studentId] = student as Map<String, dynamic>;
        }
      }

      // Get all necessary data in parallel to optimize performance
      debugPrint(
        '📊 [Analytics] Fetching parallel data: submissions, recordings, task progress, assignments',
      );

      final [
        submissions,
        recordings,
        taskProgress,
        assignments,
        quizzes,
      ] = await Future.wait([
        // Get submissions
        _supabase
            .from('student_submissions')
            .select('''
              id,
              student_id,
              assignment_id,
              score,
              max_score,
              submitted_at,
              assignments!inner(
                id,
                quiz_id,
                class_room_id
              )
            ''')
            .inFilter('student_id', studentIds)
            .not('score', 'is', null),
        // Get recordings - FIXED: Get all recordings for this class
        _supabase
            .from('student_recordings')
            .select('''
              id,
              student_id,
              score,
              graded_at,
              class_id,
              material_id
            ''')
            .eq('class_id', classId)
            .inFilter('student_id', studentIds),
        // Get task progress
        _supabase
            .from('student_task_progress')
            .select('''
              id,
              student_id,
              task_id,
              completed,
              score,
              max_score
            ''')
            .inFilter('student_id', studentIds),
        // Get assignments for this class
        _supabase
            .from('assignments')
            .select('''
              id,
              task_id,
              quiz_id,
              class_room_id
            ''')
            .eq('class_room_id', classId),
        // Get quizzes for this class
        _supabase
            .from('quizzes')
            .select('id, task_id, title')
            .eq('class_room_id', classId),
      ]);

      debugPrint('📊 [Analytics] Submissions count: ${submissions.length}');
      debugPrint('📊 [Analytics] Recordings count: ${recordings.length}');
      debugPrint('📊 [Analytics] Task progress count: ${taskProgress.length}');
      debugPrint('📊 [Analytics] Assignments count: ${assignments.length}');
      debugPrint('📊 [Analytics] Quizzes count: ${quizzes.length}');

      // Get reading materials for this class with their levels
      debugPrint('📊 [Analytics] Fetching reading materials...');
      final readingMaterials = await _getReadingMaterialsWithLevels(classId);
      debugPrint(
        '📊 [Analytics] Reading materials count: ${readingMaterials.length}',
      );

      // Get tasks for this class
      debugPrint('📊 [Analytics] Fetching tasks...');
      final tasksData = await _getTasksData(classId);
      debugPrint('📊 [Analytics] Tasks count: ${tasksData.length}');

      // Calculate all analytics with FIXED reading task progress
      debugPrint('📊 [Analytics] Calculating analytics...');
      final result = await _calculateAnalyticsWithReadingProgress(
        classInfo: classInfo,
        studentDataMap: studentDataMap,
        studentIds: studentIds,
        assignmentsData: assignments as List<Map<String, dynamic>>,
        submissionsData: submissions as List<Map<String, dynamic>>,
        recordingsData: recordings as List<Map<String, dynamic>>,
        taskProgressData: taskProgress as List<Map<String, dynamic>>,
        readingMaterialsData: readingMaterials,
        tasksData: tasksData,
        quizzesData: quizzes as List<Map<String, dynamic>>,
        totalStudents: totalStudents,
        classId: classId,
      );

      debugPrint('📊 [Analytics] Analytics calculation complete!');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ [Analytics] Error in getClassAnalytics: $e');
      debugPrint('❌ [Analytics] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get reading materials with their levels - FIXED to avoid duplicates
  Future<List<Map<String, dynamic>>> _getReadingMaterialsWithLevels(
    String classId,
  ) async {
    try {
      debugPrint('📚 [Materials] Fetching materials for class: $classId');

      final Set<String> seenMaterialIds = {};
      final List<Map<String, dynamic>> uniqueMaterials = [];

      // Helper function to add materials without duplicates
      void addUniqueMaterials(List<Map<String, dynamic>> materials) {
        for (final material in materials) {
          final materialId = material['id'] as String?;
          if (materialId != null && !seenMaterialIds.contains(materialId)) {
            seenMaterialIds.add(materialId);
            uniqueMaterials.add(material);
          }
        }
      }

      // 1. Get materials directly assigned to class
      final directMaterials = await _supabase
          .from('reading_materials')
          .select('''
          id,
          title,
          level_id,
          class_room_id,
          reading_levels!inner(id, level_number, title)
        ''')
          .eq('class_room_id', classId);

      addUniqueMaterials(directMaterials as List<Map<String, dynamic>>);
      debugPrint('📚 [Materials] Direct materials: ${directMaterials.length}');

      // 2. Get materials through classroom_reading_materials
      final classroomMaterials = await _supabase
          .from('classroom_reading_materials')
          .select('reading_material_id')
          .eq('classroom_id', classId);

      if (classroomMaterials.isNotEmpty) {
        final materialIds =
            classroomMaterials
                .map((m) => m['reading_material_id'] as String?)
                .where((id) => id != null)
                .cast<String>()
                .toList();

        if (materialIds.isNotEmpty) {
          final additionalMaterials = await _supabase
              .from('reading_materials')
              .select('''
              id,
              title,
              level_id,
              class_room_id,
              reading_levels!inner(id, level_number, title)
            ''')
              .inFilter('id', materialIds);

          addUniqueMaterials(additionalMaterials as List<Map<String, dynamic>>);
          debugPrint(
            '📚 [Materials] Additional materials: ${additionalMaterials.length}',
          );
        }
      }

      // 3. Also get materials that might be assigned to this class through other means
      // Use the correct Supabase filter for NULL values
      final globalMaterials = await _supabase
          .from('reading_materials')
          .select('''
          id,
          title,
          level_id,
          class_room_id,
          reading_levels!inner(id, level_number, title)
        ''')
          .filter(
            'class_room_id',
            'is',
            null,
          ); // Fixed: Use filter with 'is' operator

      addUniqueMaterials(globalMaterials as List<Map<String, dynamic>>);
      debugPrint('📚 [Materials] Global materials: ${globalMaterials.length}');

      debugPrint(
        '📚 [Materials] Total unique materials: ${uniqueMaterials.length}',
      );

      // Debug: Show each material
      for (final material in uniqueMaterials) {
        final levelInfo = material['reading_levels'];
        if (levelInfo is Map<String, dynamic>) {
          final levelNumber = levelInfo['level_number'];
          final levelTitle = levelInfo['title'];
          debugPrint(
            '📚 [Materials] Material ${material['id']}: ${material['title']} - Level $levelNumber: $levelTitle',
          );
        }
      }

      return uniqueMaterials;
    } catch (e) {
      debugPrint('❌ [Materials] Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getTasksData(String classId) async {
    try {
      debugPrint('📋 [Tasks] Fetching tasks for class: $classId');

      // First, get tasks linked to this class through assignments
      final assignments = await _supabase
          .from('assignments')
          .select('task_id')
          .eq('class_room_id', classId)
          .not('task_id', 'is', null);

      debugPrint('📋 [Tasks] Assignments with tasks: ${assignments.length}');

      if (assignments.isEmpty) {
        return [];
      }

      final taskIds =
          assignments
              .map((a) => a['task_id'] as String?)
              .where((id) => id != null)
              .cast<String>()
              .toList();

      if (taskIds.isEmpty) {
        return [];
      }

      debugPrint('📋 [Tasks] Task IDs: $taskIds');

      // Get task details
      final tasks = await _supabase
          .from('tasks')
          .select('id, title, description')
          .inFilter('id', taskIds);

      debugPrint('📋 [Tasks] Found ${tasks.length} tasks');

      // Determine task type based on linked data
      final List<Map<String, dynamic>> categorizedTasks = [];

      for (final task in tasks) {
        final taskId = task['id'] as String?;
        if (taskId == null) continue;

        // Check if task is linked to a quiz
        final quizAssignment =
            await _supabase
                .from('assignments')
                .select('quiz_id')
                .eq('task_id', taskId)
                .eq('class_room_id', classId)
                .not('quiz_id', 'is', null)
                .maybeSingle();

        final hasQuiz =
            quizAssignment != null && quizAssignment['quiz_id'] != null;

        // Check if task is linked to reading materials
        final readingAssignment =
            await _supabase
                .from('assignments')
                .select('*')
                .eq('task_id', taskId)
                .eq('class_room_id', classId)
                .maybeSingle();

        bool hasReading = false;
        if (readingAssignment != null) {
          // Check if there are reading materials for this class
          final readingMaterials = await _supabase
              .from('reading_materials')
              .select('id')
              .eq('class_room_id', classId)
              .limit(1);
          hasReading = readingMaterials.isNotEmpty;
        }

        // Determine task type
        String taskType = 'unknown';
        if (hasQuiz && hasReading) {
          taskType = 'mixed';
        } else if (hasQuiz) {
          taskType = 'quiz';
        } else if (hasReading) {
          taskType = 'reading';
        }

        categorizedTasks.add({
          ...task as Map<String, dynamic>,
          'task_type': taskType,
        });

        debugPrint('📋 [Tasks] Task ${task['title']} classified as: $taskType');
      }

      return categorizedTasks;
    } catch (e) {
      debugPrint('❌ [Tasks] Error getting tasks: $e');
      return [];
    }
  }

  /// Calculate analytics with FIXED reading task progress
  Future<Map<String, dynamic>> _calculateAnalyticsWithReadingProgress({
    required Map<String, dynamic> classInfo,
    required Map<String, Map<String, dynamic>> studentDataMap,
    required List<String> studentIds,
    required List<Map<String, dynamic>> assignmentsData,
    required List<Map<String, dynamic>> submissionsData,
    required List<Map<String, dynamic>> recordingsData,
    required List<Map<String, dynamic>> taskProgressData,
    required List<Map<String, dynamic>> readingMaterialsData,
    required List<Map<String, dynamic>> tasksData,
    required List<Map<String, dynamic>> quizzesData,
    required int totalStudents,
    required String classId,
  }) async {
    debugPrint(
      '🧮 [Calculate] Starting analytics calculation with FIXED reading progress...',
    );

    // Calculate reading levels distribution
    debugPrint('📚 [Calculate] Calculating reading levels distribution...');
    final Map<String, int> readingLevelCounts = {};
    for (final studentId in studentIds) {
      final studentData = studentDataMap[studentId];
      String level = 'Not Set';

      if (studentData != null) {
        final readingLevels = studentData['reading_levels'];
        if (readingLevels is Map<String, dynamic>) {
          level = readingLevels['title'] as String? ?? 'Not Set';
        }
      }

      readingLevelCounts[level] = (readingLevelCounts[level] ?? 0) + 1;
    }

    final mostCommonLevel =
        readingLevelCounts.isNotEmpty
            ? readingLevelCounts.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
            : 'N/A';

    // Filter quiz submissions
    debugPrint('📝 [Calculate] Filtering quiz submissions...');
    final quizSubmissions =
        submissionsData.where((s) {
          final assignments = s['assignments'];
          return assignments is Map<String, dynamic> &&
              assignments['quiz_id'] != null;
        }).toList();

    final totalQuizzesTaken = quizSubmissions.length;

    // Calculate average quiz score
    debugPrint('📝 [Calculate] Calculating average quiz score...');
    double totalQuizScore = 0;
    for (final submission in quizSubmissions) {
      final score = (submission['score'] as num?)?.toDouble() ?? 0;
      final maxScore = (submission['max_score'] as num?)?.toDouble() ?? 0;
      if (maxScore > 0) {
        totalQuizScore += (score / maxScore) * 100;
      }
    }
    final averageQuizScore =
        totalQuizzesTaken > 0 ? totalQuizScore / totalQuizzesTaken : 0;

    // FIXED: Group reading materials by level
    debugPrint('✅ [Calculate] Grouping reading materials by level...');
    final materialsByLevel = <String, List<Map<String, dynamic>>>{};
    for (final material in readingMaterialsData) {
      final levelInfo = material['reading_levels'];
      if (levelInfo is Map<String, dynamic>) {
        final levelId = levelInfo['id'] as String?;
        if (levelId != null) {
          materialsByLevel.putIfAbsent(levelId, () => []).add(material);
        }
      }
    }

    // FIXED: Calculate reading task completion PROPERLY
    debugPrint('✅ [Calculate] Calculating reading task completion (FIXED)...');

    int totalReadingTasksAssigned = 0;
    int totalCompletedReadingTasks = 0;

    for (final studentId in studentIds) {
      final studentData = studentDataMap[studentId];
      final levelInfo = studentData?['reading_levels'] as Map<String, dynamic>?;
      final levelId = levelInfo?['id'] as String?;

      if (levelId != null) {
        // Get materials at student's reading level
        final levelMaterials = materialsByLevel[levelId] ?? [];

        totalReadingTasksAssigned += levelMaterials.length;

        // Get student's recordings for this class
        final studentRecordings =
            recordingsData.where((r) => r['student_id'] == studentId).toList();

        // Count completed materials (recordings with material_id)
        int completedForStudent = 0;
        final completedMaterialIds = <String>{};

        for (final recording in studentRecordings) {
          final materialId = recording['material_id'] as String?;
          if (materialId != null) {
            // Check if this material belongs to student's level
            final isMaterialInLevel = levelMaterials.any(
              (m) => m['id'] == materialId,
            );
            if (isMaterialInLevel &&
                !completedMaterialIds.contains(materialId)) {
              completedMaterialIds.add(materialId);
              completedForStudent++;
            }
          }
        }

        totalCompletedReadingTasks += completedForStudent;

        debugPrint(
          '📚 [Calculate] Student $studentId: $completedForStudent/${levelMaterials.length} reading tasks completed',
        );
      } else {
        debugPrint('📚 [Calculate] Student $studentId has no reading level');
      }
    }

    // Calculate reading task completion rate
    final readingTaskCompletionRate =
        totalReadingTasksAssigned > 0
            ? (totalCompletedReadingTasks / totalReadingTasksAssigned * 100)
                .clamp(0, 100)
            : 0;

    debugPrint(
      '📚 [Calculate] Total reading tasks assigned: $totalReadingTasksAssigned',
    );
    debugPrint(
      '📚 [Calculate] Total completed reading tasks: $totalCompletedReadingTasks',
    );
    debugPrint(
      '📚 [Calculate] Reading task completion rate: ${readingTaskCompletionRate.toStringAsFixed(1)}%',
    );

    // FIXED: Calculate quiz task completion PROPERLY using student_submissions
    debugPrint(
      '✅ [Calculate] Calculating quiz task completion using student_submissions (FIXED)...',
    );

    // Get all quiz assignments for this class
    final quizAssignments =
        assignmentsData.where((a) => a['quiz_id'] != null).toList();

    // Get task IDs for quizzes
    final Set<String> quizTaskIds = {};
    for (final quiz in quizzesData) {
      final taskId = quiz['task_id'] as String?;
      if (taskId != null) {
        quizTaskIds.add(taskId);
      }
    }

    // Count unique student-task combinations that have submissions
    final Set<String> completedQuizTaskSet = <String>{};
    int totalQuizTasksAssigned = quizTaskIds.length * totalStudents;
    int totalCompletedQuizTasks = 0;

    // For each student and each quiz task, check if they have a submission
    for (final studentId in studentIds) {
      for (final quizTaskId in quizTaskIds) {
        // Find the assignment that links this quiz task to the class
        final assignment = quizAssignments.firstWhere((a) {
          // Find quiz by task_id to get quiz_id, then check assignment with that quiz_id
          final quiz = quizzesData.firstWhere(
            (q) => q['task_id'] == quizTaskId,
            orElse: () => {},
          );
          final quizId = quiz['id'] as String?;
          return quizId != null && a['quiz_id'] == quizId;
        }, orElse: () => {});

        if (assignment.isNotEmpty) {
          final assignmentId = assignment['id'] as String?;

          // Check if this student has a submission for this assignment
          final hasSubmission = submissionsData.any((s) {
            final sStudentId = s['student_id'] as String?;
            final sAssignmentId = s['assignment_id'] as String?;
            final assignments = s['assignments'] as Map<String, dynamic>?;

            return sStudentId == studentId &&
                sAssignmentId == assignmentId &&
                assignments != null &&
                assignments['quiz_id'] != null;
          });

          if (hasSubmission) {
            final key = '$studentId-$quizTaskId';
            if (!completedQuizTaskSet.contains(key)) {
              completedQuizTaskSet.add(key);
              totalCompletedQuizTasks++;
            }
          }
        }
      }
    }

    final quizTaskCompletionRate =
        totalQuizTasksAssigned > 0
            ? (totalCompletedQuizTasks / totalQuizTasksAssigned * 100).clamp(
              0,
              100,
            )
            : 0;

    debugPrint('📝 [Calculate] Quiz tasks found: ${quizTaskIds.length}');
    debugPrint(
      '📝 [Calculate] Total quiz tasks assigned: $totalQuizTasksAssigned',
    );
    debugPrint(
      '📝 [Calculate] Total completed quiz tasks: $totalCompletedQuizTasks',
    );
    debugPrint(
      '📝 [Calculate] Quiz task completion rate: ${quizTaskCompletionRate.toStringAsFixed(1)}%',
    );

    // Calculate regular task completion (non-reading, non-quiz tasks)
    debugPrint('✅ [Calculate] Calculating regular task completion...');
    final regularAssignments =
        assignmentsData
            .where((a) => a['task_id'] != null && a['quiz_id'] == null)
            .toList();
    final Set<String> regularTaskIds = {};
    for (final assignment in regularAssignments) {
      final taskId = assignment['task_id'] as String?;
      if (taskId != null) {
        regularTaskIds.add(taskId);
      }
    }

    final Set<String> completedRegularTaskSet = <String>{};
    int totalRegularTasksAssigned = 0;
    int totalCompletedRegularTasks = 0;

    for (final studentId in studentIds) {
      for (final taskId in regularTaskIds) {
        totalRegularTasksAssigned++;

        final hasCompleted = taskProgressData.any((tp) {
          final tpStudentId = tp['student_id'] as String?;
          final tpTaskId = tp['task_id'] as String?;
          final isCompleted = tp['completed'] == true;

          return tpStudentId == studentId && tpTaskId == taskId && isCompleted;
        });

        if (hasCompleted) {
          final key = '$studentId-$taskId';
          if (!completedRegularTaskSet.contains(key)) {
            completedRegularTaskSet.add(key);
            totalCompletedRegularTasks++;
          }
        }
      }
    }

    final regularTaskCompletionRate =
        totalRegularTasksAssigned > 0
            ? (totalCompletedRegularTasks / totalRegularTasksAssigned * 100)
                .clamp(0, 100)
            : 0;

    debugPrint('📋 [Calculate] Regular tasks found: ${regularTaskIds.length}');
    debugPrint(
      '📋 [Calculate] Total regular tasks assigned: $totalRegularTasksAssigned',
    );
    debugPrint(
      '📋 [Calculate] Total completed regular tasks: $totalCompletedRegularTasks',
    );
    debugPrint(
      '📋 [Calculate] Regular task completion rate: ${regularTaskCompletionRate.toStringAsFixed(1)}%',
    );

    // Calculate reading performance (from graded recordings)
    debugPrint('📖 [Calculate] Calculating reading performance...');
    final gradedRecordings =
        recordingsData.where((r) => r['score'] != null).toList();
    double totalReadingScore = 0;
    for (final recording in gradedRecordings) {
      final score = (recording['score'] as num?)?.toDouble() ?? 0;
      totalReadingScore += score;
    }
    final averageReadingScore =
        gradedRecordings.isNotEmpty
            ? (totalReadingScore / gradedRecordings.length).clamp(0, 5)
            : 0;

    // Calculate last activity
    debugPrint('⏰ [Calculate] Calculating last activity...');
    final lastSubmissions =
        submissionsData
            .where((s) => s['submitted_at'] != null)
            .map((s) => DateTime.tryParse(s['submitted_at'] as String))
            .where((date) => date != null)
            .cast<DateTime>()
            .toList();

    final lastActivity =
        lastSubmissions.isNotEmpty
            ? lastSubmissions.reduce((a, b) => a.isAfter(b) ? a : b)
            : null;

    // Calculate active students (last 7 days)
    debugPrint('👥 [Calculate] Calculating active students...');
    final activeStudents = _calculateActiveStudents(
      submissionsData,
      recordingsData,
    );

    // Calculate total tasks (all types)
    final totalAllTasksAssigned =
        totalReadingTasksAssigned +
        totalQuizTasksAssigned +
        totalRegularTasksAssigned;

    final totalAllTasksCompleted =
        totalCompletedReadingTasks +
        totalCompletedQuizTasks +
        totalCompletedRegularTasks;

    final overallCompletionRate =
        totalAllTasksAssigned > 0
            ? (totalAllTasksCompleted / totalAllTasksAssigned * 100).clamp(
              0,
              100,
            )
            : 0;

    // Get student performance breakdown
    debugPrint('🎓 [Calculate] Calculating student performance...');
    final studentPerformance = await _calculateStudentPerformanceWithReading(
      studentDataMap: studentDataMap,
      studentIds: studentIds,
      submissionsData: submissionsData,
      taskProgressData: taskProgressData,
      recordingsData: recordingsData,
      readingMaterialsData: readingMaterialsData,
      assignmentsData: assignmentsData,
      tasksData: tasksData,
      quizzesData: quizzesData,
      classId: classId,
      materialsByLevel: materialsByLevel,
      totalStudents: totalStudents,
    );

    final result = {
      'classInfo': {
        'id': classInfo['id'],
        'name': classInfo['class_name'] ?? 'Class',
        'section': classInfo['section'],
        'gradeLevel': classInfo['grade_level'],
        'schoolYear': classInfo['school_year'],
        'totalStudents': totalStudents,
      },
      'overallStats': {
        'averageQuizScore': averageQuizScore,
        'averageReadingScore': averageReadingScore,
        'mostCommonReadingLevel': mostCommonLevel,
        'totalQuizzesTaken': totalQuizzesTaken,
        'totalReadingTasksAssigned': totalReadingTasksAssigned,
        'completedReadingTasks': totalCompletedReadingTasks,
        'readingTaskCompletionRate': readingTaskCompletionRate,
        'totalQuizTasksAssigned': totalQuizTasksAssigned,
        'completedQuizTasks': totalCompletedQuizTasks,
        'quizTaskCompletionRate': quizTaskCompletionRate,
        'totalRegularTasksAssigned': totalRegularTasksAssigned,
        'completedRegularTasks': totalCompletedRegularTasks,
        'regularTaskCompletionRate': regularTaskCompletionRate,
        'totalAllTasksAssigned': totalAllTasksAssigned,
        'totalAllTasksCompleted': totalAllTasksCompleted,
        'overallCompletionRate': overallCompletionRate,
        'lastActivity': lastActivity?.toIso8601String(),
        'activeStudents': activeStudents,
        'gradedRecordingsCount': gradedRecordings.length,
      },
      'readingLevelDistribution': readingLevelCounts,
      'performanceBreakdown': {
        'quizPerformance': _calculateQuizPerformance(quizSubmissions),
        'readingPerformance': _calculateReadingPerformance(gradedRecordings),
        'readingTaskPerformance': {
          'completed': totalCompletedReadingTasks,
          'pending': totalReadingTasksAssigned - totalCompletedReadingTasks,
          'total': totalReadingTasksAssigned,
        },
        'quizTaskPerformance': {
          'completed': totalCompletedQuizTasks,
          'pending': totalQuizTasksAssigned - totalCompletedQuizTasks,
          'total': totalQuizTasksAssigned,
        },
        'regularTaskPerformance': {
          'completed': totalCompletedRegularTasks,
          'pending': totalRegularTasksAssigned - totalCompletedRegularTasks,
          'total': totalRegularTasksAssigned,
        },
      },
      'studentPerformance': studentPerformance,
    };

    debugPrint('✅ [Calculate] Analytics calculation complete!');
    return result;
  }

  /// Calculate student performance WITH FIXED reading progress
  Future<Map<String, dynamic>> _calculateStudentPerformanceWithReading({
    required Map<String, Map<String, dynamic>> studentDataMap,
    required List<String> studentIds,
    required List<Map<String, dynamic>> submissionsData,
    required List<Map<String, dynamic>> taskProgressData,
    required List<Map<String, dynamic>> recordingsData,
    required List<Map<String, dynamic>> readingMaterialsData,
    required List<Map<String, dynamic>> assignmentsData,
    required List<Map<String, dynamic>> tasksData,
    required List<Map<String, dynamic>> quizzesData,
    required String classId,
    required Map<String, List<Map<String, dynamic>>> materialsByLevel,
    required int totalStudents,
  }) async {
    debugPrint(
      '🎓 [Student Perf] Calculating performance for ${studentIds.length} enrolled students',
    );

    final List<Map<String, dynamic>> allStudents = [];
    final List<Map<String, dynamic>> topPerformers = [];
    final List<Map<String, dynamic>> averagePerformers = [];

    // Get quiz task IDs and their assignments
    final quizAssignments =
        assignmentsData.where((a) => a['quiz_id'] != null).toList();

    // Create a map of quiz_id to assignment for quick lookup
    final Map<String, Map<String, dynamic>> quizAssignmentMap = {};
    for (final assignment in quizAssignments) {
      final quizId = assignment['quiz_id'] as String?;
      if (quizId != null) {
        quizAssignmentMap[quizId] = assignment;
      }
    }

    // Get quiz task IDs
    final quizTaskIds =
        quizzesData
            .map((q) => q['task_id'] as String?)
            .where((id) => id != null)
            .cast<String>()
            .toSet()
            .toList();

    // Get regular task IDs (non-quiz tasks)
    final regularTaskIds = <String>{};
    for (final assignment in assignmentsData) {
      final taskId = assignment['task_id'] as String?;
      final quizId = assignment['quiz_id'];

      if (taskId != null && quizId == null) {
        regularTaskIds.add(taskId);
      }
    }
    final regularTaskIdsList = regularTaskIds.toList();

    for (var i = 0; i < studentIds.length; i++) {
      final studentId = studentIds[i];
      final studentInfo = studentDataMap[studentId];
      final studentName =
          studentInfo?['student_name'] as String? ?? 'Unknown Student';
      final profilePicture = studentInfo?['profile_picture'] as String?;

      String readingLevel = 'Not Set';
      String? levelId;
      if (studentInfo != null) {
        final readingLevelData = studentInfo['reading_levels'];
        if (readingLevelData is Map<String, dynamic>) {
          readingLevel = readingLevelData['title'] as String? ?? 'Not Set';
          levelId = readingLevelData['id'] as String?;
        }
      }

      // Get student-specific data
      final studentSubmissions =
          submissionsData.where((s) => s['student_id'] == studentId).where((s) {
            final assignments = s['assignments'];
            return assignments is Map<String, dynamic> &&
                assignments['quiz_id'] != null;
          }).toList();

      final studentTaskProgress =
          taskProgressData.where((t) => t['student_id'] == studentId).toList();
      final studentRecordings =
          recordingsData.where((r) => r['student_id'] == studentId).toList();

      // FIXED: Calculate reading task completion based on student's reading level
      int completedReadingTasks = 0;
      int totalReadingTasksForStudent = 0;
      double readingTaskCompletionRate = 0;

      if (levelId != null) {
        // Get materials at student's reading level
        final levelMaterials = materialsByLevel[levelId] ?? [];
        totalReadingTasksForStudent = levelMaterials.length;

        // Count completed materials (recordings with material_id)
        final completedMaterialIds = <String>{};
        for (final recording in studentRecordings) {
          final materialId = recording['material_id'] as String?;
          if (materialId != null) {
            // Check if this material belongs to student's level
            final isMaterialInLevel = levelMaterials.any(
              (m) => m['id'] == materialId,
            );
            if (isMaterialInLevel &&
                !completedMaterialIds.contains(materialId)) {
              completedMaterialIds.add(materialId);
              completedReadingTasks++;
            }
          }
        }

        readingTaskCompletionRate =
            totalReadingTasksForStudent > 0
                ? (completedReadingTasks / totalReadingTasksForStudent * 100)
                    .clamp(0, 100)
                : 0;
      } else {
        // If student has no reading level, they have 0 reading tasks
        totalReadingTasksForStudent = 0;
        readingTaskCompletionRate = 0;
      }

      // FIXED: Calculate quiz task completion using student_submissions
      int completedQuizTasks = 0;
      final totalQuizTasksForStudent = quizTaskIds.length;

      for (final quizTaskId in quizTaskIds) {
        // Find the quiz for this task
        final quiz = quizzesData.firstWhere(
          (q) => q['task_id'] == quizTaskId,
          orElse: () => {},
        );

        final quizId = quiz['id'] as String?;
        if (quizId != null) {
          final assignment = quizAssignmentMap[quizId];
          final assignmentId = assignment?['id'] as String?;

          if (assignmentId != null) {
            // Check if this student has a submission for this assignment
            final hasSubmission = studentSubmissions.any((s) {
              final sAssignmentId = s['assignment_id'] as String?;
              return sAssignmentId == assignmentId;
            });

            if (hasSubmission) {
              completedQuizTasks++;
            }
          }
        }
      }

      final quizTaskCompletionRate =
          totalQuizTasksForStudent > 0
              ? (completedQuizTasks / totalQuizTasksForStudent * 100).clamp(
                0,
                100,
              )
              : 0;

      // FIXED: Calculate regular task completion
      int completedRegularTasks = 0;
      final totalRegularTasksForStudent = regularTaskIdsList.length;

      for (final regularTaskId in regularTaskIdsList) {
        final hasCompleted = studentTaskProgress.any((tp) {
          final tpTaskId = tp['task_id'] as String?;
          final isCompleted = tp['completed'] == true;

          return tpTaskId == regularTaskId && isCompleted;
        });

        if (hasCompleted) {
          completedRegularTasks++;
        }
      }

      final regularTaskCompletionRate =
          totalRegularTasksForStudent > 0
              ? (completedRegularTasks / totalRegularTasksForStudent * 100)
                  .clamp(0, 100)
              : 0;

      // Calculate quiz average score
      double quizAverage = 0;
      if (studentSubmissions.isNotEmpty) {
        double totalQuizScore = 0;
        for (final submission in studentSubmissions) {
          final score = (submission['score'] as num?)?.toDouble() ?? 0;
          final maxScore = (submission['max_score'] as num?)?.toDouble() ?? 0;
          if (maxScore > 0) {
            totalQuizScore += (score / maxScore) * 100;
          }
        }
        quizAverage = totalQuizScore / studentSubmissions.length;
      }

      // Calculate reading average score
      double readingAverage = 0;
      if (studentRecordings.isNotEmpty) {
        double totalReadingScore = 0;
        for (final recording in studentRecordings) {
          totalReadingScore += (recording['score'] as num?)?.toDouble() ?? 0;
        }
        readingAverage = totalReadingScore / studentRecordings.length;
      }

      // Determine last activity
      String lastActivity = 'Never';
      final lastSubmission = studentSubmissions
          .where((s) => s['submitted_at'] != null)
          .map((s) => DateTime.tryParse(s['submitted_at'] as String))
          .where((date) => date != null)
          .fold<DateTime?>(
            null,
            (prev, curr) => prev == null || curr!.isAfter(prev) ? curr : prev,
          );

      if (lastSubmission != null) {
        final now = DateTime.now();
        final diff = now.difference(lastSubmission);
        if (diff.inHours < 24) {
          lastActivity = 'Today';
        } else if (diff.inHours < 48) {
          lastActivity = 'Yesterday';
        } else {
          lastActivity = '${diff.inDays} days ago';
        }
      }

      // Calculate overall score (weighted average)
      // Convert readingAverage from 0-5 to 0-100
      final readingScoreOn100Scale = readingAverage * 20;

      // Simple average of both scores
      final overallScore = (quizAverage + readingScoreOn100Scale) / 2;

      // Inside _calculateStudentPerformanceWithReading method, update the studentData creation:

      final studentData = {
        'id': studentId,
        'name': studentName,
        'grade_level': studentInfo?['student_grade'] as String? ?? 'N/A',
        'student_section': studentInfo?['student_section'] as String? ?? 'N/A',
        'student_lrn': studentInfo?['student_lrn'] as String? ?? 'N/A',
        'readingLevel': readingLevel,
        'level_id': levelId,
        'quizAverage': quizAverage,
        'readingAverage': readingAverage,
        'readingTaskCompletionRate': readingTaskCompletionRate,
        'completedReadingTasks': completedReadingTasks,
        'totalReadingTasks': totalReadingTasksForStudent,
        'quizTaskCompletionRate': quizTaskCompletionRate,
        'completedQuizTasks': completedQuizTasks,
        'totalQuizTasks': totalQuizTasksForStudent,
        'regularTaskCompletionRate': regularTaskCompletionRate,
        'completedRegularTasks': completedRegularTasks,
        'totalRegularTasks': totalRegularTasksForStudent,
        'lastActivity': lastActivity,
        'profile_picture': profilePicture,
        'overallScore': overallScore,
        'hasData': studentInfo != null,
      };

      allStudents.add(studentData);

      debugPrint('🎓 [Student Perf] Student $studentName:');
      debugPrint(
        '  - Reading tasks: $completedReadingTasks/$totalReadingTasksForStudent',
      );
      debugPrint(
        '  - Quiz tasks: $completedQuizTasks/$totalQuizTasksForStudent',
      );
      debugPrint(
        '  - Regular tasks: $completedRegularTasks/$totalRegularTasksForStudent',
      );
    }

    // Sort students by overall performance
    allStudents.sort((a, b) {
      final aHasData = a['hasData'] as bool;
      final bHasData = b['hasData'] as bool;

      if (aHasData && !bHasData) return -1;
      if (!aHasData && bHasData) return 1;

      return (b['overallScore'] as double).compareTo(
        a['overallScore'] as double,
      );
    });

    // Categorize students - only categorize those with data
    final studentsWithData =
        allStudents.where((s) => s['hasData'] as bool).toList();
    for (int i = 0; i < studentsWithData.length; i++) {
      final student = studentsWithData[i];
      if (i < 3) {
        topPerformers.add(student);
      } else if (i < 8) {
        averagePerformers.add(student);
      }
    }

    return {
      'allStudents': allStudents,
      'topPerformingStudents': topPerformers,
      'averagePerformers': averagePerformers,
      'studentsWithData': studentsWithData,
    };
  }

  int _calculateActiveStudents(
    List<Map<String, dynamic>> submissionsData,
    List<Map<String, dynamic>> recordingsData,
  ) {
    final activeStudentIds = <String>{};
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    for (final submission in submissionsData) {
      if (submission['submitted_at'] != null) {
        final submittedAt = DateTime.tryParse(
          submission['submitted_at'] as String,
        );
        if (submittedAt != null && submittedAt.isAfter(weekAgo)) {
          final studentId = submission['student_id'] as String?;
          if (studentId != null) activeStudentIds.add(studentId);
        }
      }
    }

    for (final recording in recordingsData) {
      if (recording['graded_at'] != null) {
        final gradedAt = DateTime.tryParse(recording['graded_at'] as String);
        if (gradedAt != null && gradedAt.isAfter(weekAgo)) {
          final studentId = recording['student_id'] as String?;
          if (studentId != null) activeStudentIds.add(studentId);
        }
      }
    }

    return activeStudentIds.length;
  }

  Map<String, int> _calculateQuizPerformance(
    List<Map<String, dynamic>> submissionsData,
  ) {
    final performance = {
      'excellent': 0,
      'good': 0,
      'average': 0,
      'needsImprovement': 0,
    };

    for (final submission in submissionsData) {
      final score = (submission['score'] as num?)?.toDouble() ?? 0;
      final maxScore = (submission['max_score'] as num?)?.toDouble() ?? 0;

      if (maxScore > 0) {
        final percentage = (score / maxScore) * 100;
        if (percentage >= 80) {
          performance['excellent'] = performance['excellent']! + 1;
        } else if (percentage >= 60) {
          performance['good'] = performance['good']! + 1;
        } else if (percentage >= 40) {
          performance['average'] = performance['average']! + 1;
        } else {
          performance['needsImprovement'] =
              performance['needsImprovement']! + 1;
        }
      }
    }

    return performance;
  }

  Map<String, int> _calculateReadingPerformance(
    List<Map<String, dynamic>> recordingsData,
  ) {
    final performance = {
      'excellent': 0,
      'good': 0,
      'average': 0,
      'needsImprovement': 0,
    };

    for (final recording in recordingsData) {
      final score = (recording['score'] as num?)?.toDouble() ?? 0;
      if (score >= 4) {
        performance['excellent'] = performance['excellent']! + 1;
      } else if (score >= 3) {
        performance['good'] = performance['good']! + 1;
      } else if (score >= 2) {
        performance['average'] = performance['average']! + 1;
      } else {
        performance['needsImprovement'] = performance['needsImprovement']! + 1;
      }
    }

    return performance;
  }

  Map<String, dynamic> _getEmptyAnalytics(String className) {
    return {
      'classInfo': {'name': className, 'totalStudents': 0},
      'overallStats': {
        'averageQuizScore': 0,
        'averageReadingScore': 0,
        'mostCommonReadingLevel': 'N/A',
        'totalQuizzesTaken': 0,
        'totalReadingTasksAssigned': 0,
        'completedReadingTasks': 0,
        'readingTaskCompletionRate': 0,
        'totalQuizTasksAssigned': 0,
        'completedQuizTasks': 0,
        'quizTaskCompletionRate': 0,
        'totalRegularTasksAssigned': 0,
        'completedRegularTasks': 0,
        'regularTaskCompletionRate': 0,
        'totalAllTasksAssigned': 0,
        'totalAllTasksCompleted': 0,
        'overallCompletionRate': 0,
        'lastActivity': null,
        'activeStudents': 0,
        'gradedRecordingsCount': 0,
      },
      'readingLevelDistribution': {},
      'performanceBreakdown': {
        'quizPerformance': {
          'excellent': 0,
          'good': 0,
          'average': 0,
          'needsImprovement': 0,
        },
        'readingPerformance': {
          'excellent': 0,
          'good': 0,
          'average': 0,
          'needsImprovement': 0,
        },
        'readingTaskPerformance': {'completed': 0, 'pending': 0, 'total': 0},
        'quizTaskPerformance': {'completed': 0, 'pending': 0, 'total': 0},
        'regularTaskPerformance': {'completed': 0, 'pending': 0, 'total': 0},
      },
      'studentPerformance': {
        'allStudents': [],
        'topPerformingStudents': [],
        'averagePerformers': [],
        'studentsWithData': [],
      },
    };
  }
}
