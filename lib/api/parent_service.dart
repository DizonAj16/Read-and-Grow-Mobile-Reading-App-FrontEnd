import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParentService {
  final supabase = Supabase.instance.client;

  /// Fetch all children linked to this parent (via parent_student_relationships)
/// Fetch all children linked to this parent (via parent_student_relationships)
Future<List<Map<String, dynamic>>> getChildrenSummary(
  String parentUserId,
) async {
  try {
    debugPrint(
      '🔍 Fetching children for parentUserId (auth ID): $parentUserId',
    );

    // Step 1: Find the parent record matching this auth user ID
    final parentRecord =
        await supabase
            .from('parents')
            .select('id, id')
            .eq('id', parentUserId)
            .maybeSingle();

    if (parentRecord == null) {
      debugPrint('⚠️ No parent record found for id: $parentUserId');
      return [];
    }

    final parentId = parentRecord['id'];
    debugPrint('👨 Parent found: $parentId');

    // Step 2: Get linked students via parent_student_relationships
    final relationships = await supabase
        .from('parent_student_relationships')
        .select('student_id')
        .eq('parent_id', parentId);

    if (relationships.isEmpty) {
      debugPrint('⚠️ No linked students for parent_id: $parentId');
      return [];
    }

    final studentIds =
        relationships.map((r) => r['student_id'] as String).toList();
    debugPrint('👦 Student IDs found: $studentIds');

    // Step 3: Fetch student info
    final studentsResp = await supabase
        .from('students')
        .select('id, student_name, current_reading_level_id, profile_picture')
        .inFilter('id', studentIds);

    List<Map<String, dynamic>> childrenList = [];

    for (final student in studentsResp) {
      final studentId = student['id'] as String;
      final studentName = student['student_name'] as String;
      final profilePicture = student['profile_picture'] as String?;

      final levelId = student['current_reading_level_id'] as String?;

      // Step 4: Get reading level title
      String readingLevel = 'Not Set';
      if (levelId != null) {
        final levelResp =
            await supabase
                .from('reading_levels')
                .select('title')
                .eq('id', levelId)
                .maybeSingle();
        readingLevel = levelResp?['title'] ?? 'Unknown';
      }

      // Step 5: Get reading materials count (for Reading Task Overview)
      int totalMaterials = 0;
      int submittedMaterials = 0;

      if (levelId != null) {
        final materialsRes = await supabase
            .from('reading_materials')
            .select('id')
            .eq('level_id', levelId);

        totalMaterials = (materialsRes as List).length;

        if (totalMaterials > 0) {
          final materialIds =
              materialsRes
                  .map((m) => m['id']?.toString())
                  .where((id) => id != null)
                  .toList();

          final submissionsRes = await supabase
              .from('student_recordings')
              .select('teacher_comments, file_url')
              .eq('student_id', studentId)
              .isFilter('task_id', null);

          Set<String> submittedMaterialIds = {};
          for (final s in submissionsRes) {
            String? materialId;

            final comments = s['teacher_comments'] as String?;
            if (comments != null && comments.contains('"material_id"')) {
              try {
                final regex = RegExp(r'"material_id":\s*"([^"]+)"');
                final match = regex.firstMatch(comments);
                if (match != null) {
                  materialId = match.group(1);
                }
              } catch (e) {
                debugPrint('Error parsing material_id: $e');
              }
            }

            if (materialId == null) {
              final fileUrl = s['file_url'] as String?;
              if (fileUrl != null && fileUrl.isNotEmpty) {
                for (final mid in materialIds) {
                  if (mid != null && fileUrl.contains(mid)) {
                    materialId = mid;
                    break;
                  }
                }
              }
            }

            if (materialId != null && materialIds.contains(materialId)) {
              submittedMaterialIds.add(materialId);
            }
          }

          submittedMaterials = submittedMaterialIds.length;
        }
      }

      // Step 6: Get assignment-based task progress
      final enrollments = await supabase
          .from('student_enrollments')
          .select('class_room_id')
          .eq('student_id', studentId);

      final classIds =
          enrollments.map((e) => e['class_room_id'] as String).toList();

      List<String> assignedTaskIds = [];
      List<String> assignedQuizIds = [];
      Set<String> tasksWithQuizzes = {};

      if (classIds.isNotEmpty) {
        final assignments = await supabase
            .from('assignments')
            .select('task_id, quiz_id, tasks(id, quizzes(id))')
            .inFilter('class_room_id', classIds);

        for (var assignment in assignments) {
          final directQuizId = assignment['quiz_id'] as String?;
          if (directQuizId != null && !assignedQuizIds.contains(directQuizId)) {
            assignedQuizIds.add(directQuizId);
          }

          final taskId = assignment['task_id'] as String?;
          if (taskId != null) {
            final task = assignment['tasks'] as Map<String, dynamic>?;
            bool taskHasQuiz = false;

            if (task != null) {
              final quizzes = task['quizzes'] as List?;
              if (quizzes != null && quizzes.isNotEmpty) {
                taskHasQuiz = true;
                tasksWithQuizzes.add(taskId);
                for (var quiz in quizzes) {
                  final quizId = quiz['id'] as String?;
                  if (quizId != null && !assignedQuizIds.contains(quizId)) {
                    assignedQuizIds.add(quizId);
                  }
                }
              }
            }

            if (!taskHasQuiz && !assignedTaskIds.contains(taskId)) {
              assignedTaskIds.add(taskId);
            }
          }
        }
      }

      final taskProgress = await supabase
          .from('student_task_progress')
          .select('task_id, score, max_score, completed')
          .eq('student_id', studentId);

      Set<String> completedTaskIds = {};
      Set<String> pendingTaskIds = {};

      for (var t in taskProgress) {
        final taskId = t['task_id'] as String?;
        if (taskId == null) continue;

        if (t['completed'] == true) {
          completedTaskIds.add(taskId);
        } else {
          pendingTaskIds.add(taskId);
        }
      }

      Set<String> completedTasksWithoutQuizzes =
          completedTaskIds
              .where((id) => !tasksWithQuizzes.contains(id))
              .toSet();
      Set<String> pendingTasksWithoutQuizzes =
          pendingTaskIds
              .where((id) => !tasksWithQuizzes.contains(id))
              .toSet();

      int newPendingTasks = 0;
      for (var taskId in assignedTaskIds) {
        if (!completedTasksWithoutQuizzes.contains(taskId) &&
            !pendingTasksWithoutQuizzes.contains(taskId)) {
          newPendingTasks++;
        }
      }

      double totalScore = 0;
      double totalMax = 0;
      for (final t in taskProgress) {
        totalScore += (t['score'] ?? 0).toDouble();
        totalMax += (t['max_score'] ?? 0).toDouble();
      }
      double avgScore = totalMax > 0 ? (totalScore / totalMax) * 100 : 0;

      // Step 7: Get quiz completion data (same as in getChildProgress)
      final quizSubmissions = await supabase
          .from('student_submissions')
          .select(
            'score, max_score, assignment_id, assignments(id, task_id, quiz_id, tasks(id, quizzes(id)), quiz:quizzes(id))',
          )
          .eq('student_id', studentId);

      Set<String> completedQuizIds = {};
      for (var submission in quizSubmissions) {
        final assignment = submission['assignments'] as Map<String, dynamic>?;
        if (assignment != null) {
          final directQuiz = assignment['quiz'] as Map<String, dynamic>?;
          if (directQuiz != null) {
            final quizId = directQuiz['id'] as String?;
            if (quizId != null) {
              completedQuizIds.add(quizId);
            }
          }

          final task = assignment['tasks'] as Map<String, dynamic>?;
          if (task != null) {
            final quizzes = task['quizzes'] as List?;
            if (quizzes != null) {
              for (var quiz in quizzes) {
                final quizId = quiz['id'] as String?;
                if (quizId != null) {
                  completedQuizIds.add(quizId);
                }
              }
            }
          }
        }
      }

      int totalQuizzes = assignedQuizIds.length;
      int completedQuizzes = completedQuizIds.length;
      double quizAvg = 0;

      if (quizSubmissions.isNotEmpty) {
        double totalScore = 0;
        double totalMax = 0;
        for (var s in quizSubmissions) {
          final score = (s['score'] ?? 0).toDouble();
          final maxScore = (s['max_score'] ?? 0).toDouble();
          if (maxScore > 0) {
            totalScore += score;
            totalMax += maxScore;
          }
        }
        if (totalMax > 0) {
          quizAvg = (totalScore / totalMax) * 100;
        }
      }

      // Use materials count for Reading Task Overview
      childrenList.add({
        'studentId': studentId,
        'studentName': studentName,
        'readingLevel': readingLevel,
        'totalTasks': assignedTaskIds.length + totalMaterials,
        'completedTasks':
            completedTasksWithoutQuizzes.length + submittedMaterials,
        'pendingTasks':
            totalMaterials - submittedMaterials, // Pending materials
        'averageScore': avgScore,
        'quizCount': completedQuizzes, // This should be completedQuizzes, not total
        'totalQuizzes': totalQuizzes, // Add this field
        'completedQuizzes': completedQuizzes, // Add this field
        'quizAverage': quizAvg,
        'profile_picture': profilePicture,
      });
    }

    debugPrint('✅ Found ${childrenList.length} children.');
    return childrenList;
  } catch (e) {
    debugPrint('❌ Error fetching children summary: $e');
    return [];
  }
}

  Future<List<Map<String, dynamic>>> getReadingGrades(String studentId) async {
    final response = await supabase
        .from('student_recordings')
        .select('''
        id,
        score,
        material_id,
        graded_by,
                teacher_comments,
        graded_at,
        reading_materials (title, description),
        teachers:graded_by (teacher_name)
      ''')
        .eq('student_id', studentId)
        .order('graded_at', ascending: false);

    return response.map((e) {
      return {
        'id': e['id'],
        'score': e['score'],
        'max_score': 5,
        'material_id': e['material_id'],
        'graded_by': e['graded_by'],
        'graded_by_name': e['teachers']?['teacher_name'] ?? 'N/A',
        'teacher_comments': e['teacher_comments'] ?? '',

        'graded_at': e['graded_at'],
        'title': e['reading_materials']?['title'] ?? 'Reading Material',
        'description': e['reading_materials']?['description'] ?? '',
      };
    }).toList();
  }

  /// Fetch detailed progress for a single child
  Future<Map<String, dynamic>?> getChildProgress(String studentId) async {
    try {
      debugPrint('📘 Fetching progress for studentId: $studentId');

      // Step 1: Get reading level
      final studentResp =
          await supabase
              .from('students')
              .select('current_reading_level_id')
              .eq('id', studentId)
              .maybeSingle();

      String readingLevel = 'Not Set';
      String? levelId;

      if (studentResp != null &&
          studentResp['current_reading_level_id'] != null) {
        levelId = studentResp['current_reading_level_id'] as String?;
        if (levelId != null) {
          final levelResp =
              await supabase
                  .from('reading_levels')
                  .select('title')
                  .eq('id', levelId)
                  .maybeSingle();
          readingLevel = levelResp?['title'] ?? 'Not Set';
        }
      }

      // Step 2: Get reading materials count
      int totalMaterials = 0;
      int submittedMaterials = 0;

      if (levelId != null) {
        final materialsRes = await supabase
            .from('reading_materials')
            .select('id')
            .eq('level_id', levelId);

        totalMaterials = (materialsRes as List).length;

        if (totalMaterials > 0) {
          final materialIds =
              materialsRes
                  .map((m) => m['id']?.toString())
                  .where((id) => id != null)
                  .toList();

          final submissionsRes = await supabase
              .from('student_recordings')
              .select('teacher_comments, file_url')
              .eq('student_id', studentId)
              .isFilter('task_id', null);

          Set<String> submittedMaterialIds = {};
          for (final s in submissionsRes) {
            String? materialId;

            final comments = s['teacher_comments'] as String?;
            if (comments != null && comments.contains('"material_id"')) {
              try {
                final regex = RegExp(r'"material_id":\s*"([^"]+)"');
                final match = regex.firstMatch(comments);
                if (match != null) {
                  materialId = match.group(1);
                }
              } catch (e) {
                debugPrint('Error parsing material_id: $e');
              }
            }

            if (materialId == null) {
              final fileUrl = s['file_url'] as String?;
              if (fileUrl != null && fileUrl.isNotEmpty) {
                for (final mid in materialIds) {
                  if (mid != null && fileUrl.contains(mid)) {
                    materialId = mid;
                    break;
                  }
                }
              }
            }

            if (materialId != null && materialIds.contains(materialId)) {
              submittedMaterialIds.add(materialId);
            }
          }

          submittedMaterials = submittedMaterialIds.length;
        }
      }

      // Step 3: Assignment-based progress
      final enrollments = await supabase
          .from('student_enrollments')
          .select('class_room_id')
          .eq('student_id', studentId);

      final classIds =
          enrollments.map((e) => e['class_room_id'] as String).toList();

      List<String> assignedTaskIds = [];
      List<String> assignedQuizIds = [];
      Set<String> tasksWithQuizzes = {};

      if (classIds.isNotEmpty) {
        final assignments = await supabase
            .from('assignments')
            .select('task_id, quiz_id, tasks(id, quizzes(id))')
            .inFilter('class_room_id', classIds);

        for (var assignment in assignments) {
          final directQuizId = assignment['quiz_id'] as String?;
          if (directQuizId != null && !assignedQuizIds.contains(directQuizId)) {
            assignedQuizIds.add(directQuizId);
          }

          final taskId = assignment['task_id'] as String?;
          if (taskId != null) {
            final task = assignment['tasks'] as Map<String, dynamic>?;
            bool taskHasQuiz = false;

            if (task != null) {
              final quizzes = task['quizzes'] as List?;
              if (quizzes != null && quizzes.isNotEmpty) {
                taskHasQuiz = true;
                tasksWithQuizzes.add(taskId);
                for (var quiz in quizzes) {
                  final quizId = quiz['id'] as String?;
                  if (quizId != null && !assignedQuizIds.contains(quizId)) {
                    assignedQuizIds.add(quizId);
                  }
                }
              }
            }

            if (!taskHasQuiz && !assignedTaskIds.contains(taskId)) {
              assignedTaskIds.add(taskId);
            }
          }
        }
      }

      // Step 4: Task progress
      final taskProgress = await supabase
          .from('student_task_progress')
          .select(
            'task_id, score, max_score, correct_answers, wrong_answers, completed',
          )
          .eq('student_id', studentId);

      Set<String> completedTaskIds = {};
      Set<String> pendingTaskIds = {};

      for (var t in taskProgress) {
        final taskId = t['task_id'] as String?;
        if (taskId == null) continue;
        if (t['completed'] == true) {
          completedTaskIds.add(taskId);
        } else {
          pendingTaskIds.add(taskId);
        }
      }

      Set<String> completedTasksWithoutQuizzes =
          completedTaskIds
              .where((id) => !tasksWithQuizzes.contains(id))
              .toSet();
      Set<String> pendingTasksWithoutQuizzes =
          pendingTaskIds.where((id) => !tasksWithQuizzes.contains(id)).toSet();

      int newPendingTasks = 0;
      for (var taskId in assignedTaskIds) {
        if (!completedTasksWithoutQuizzes.contains(taskId) &&
            !pendingTasksWithoutQuizzes.contains(taskId)) {
          newPendingTasks++;
        }
      }

      double totalScore = 0;
      double totalMax = 0;
      int totalCorrect = 0;
      int totalWrong = 0;

      for (final t in taskProgress) {
        totalScore += (t['score'] ?? 0).toDouble();
        totalMax += (t['max_score'] ?? 0).toDouble();
        totalCorrect += (t['correct_answers'] ?? 0) as int;
        totalWrong += (t['wrong_answers'] ?? 0) as int;
      }

      double averageScore = totalMax > 0 ? (totalScore / totalMax) * 100 : 0;

      // Step 5: Fetch quiz submissions (GradesPage-style)
      final quizSubmissions = await supabase
          .from('student_submissions')
          .select(
            'score, max_score, submitted_at, assignment_id, assignments(id, task_id, quiz_id, tasks(id, quizzes(id, title)), quiz:quizzes(id, title))',
          )
          .eq('student_id', studentId)
          .order('submitted_at', ascending: false);

      List<Map<String, dynamic>> quizSubmissionList = [];
      Set<String> completedQuizIds = {};

      for (var submission in quizSubmissions) {
        final assignment = submission['assignments'] as Map<String, dynamic>?;
        String quizTitle = 'Quiz';

        if (assignment != null) {
          final directQuiz = assignment['quiz'] as Map<String, dynamic>?;
          if (directQuiz != null && directQuiz['title'] != null) {
            quizTitle = directQuiz['title'];
            final quizId = directQuiz['id'] as String?;
            if (quizId != null) completedQuizIds.add(quizId);
          } else {
            final task = assignment['tasks'] as Map<String, dynamic>?;
            final quizzes = task?['quizzes'] as List<dynamic>?;
            if (quizzes != null && quizzes.isNotEmpty) {
              final firstQuiz = quizzes.first as Map<String, dynamic>?;
              if (firstQuiz != null && firstQuiz['title'] != null) {
                quizTitle = firstQuiz['title'];
                final quizId = firstQuiz['id'] as String?;
                if (quizId != null) completedQuizIds.add(quizId);
              }
            }
          }
        }

        quizSubmissionList.add({
          'score': submission['score'],
          'max_score': submission['max_score'],
          'submitted_at': submission['submitted_at'],
          'quiz_title': quizTitle,
        });
      }

      int totalQuizzes = assignedQuizIds.length;
      int completedQuizzes = completedQuizIds.length;
      int pendingQuizzes = totalQuizzes - completedQuizzes;

      double quizAverage = 0;
      if (quizSubmissionList.isNotEmpty) {
        double totalQuizScore = 0;
        double totalQuizMax = 0;
        for (var sub in quizSubmissionList) {
          final score = (sub['score'] ?? 0).toDouble();
          final maxScore = (sub['max_score'] ?? 0).toDouble();
          if (maxScore > 0) {
            totalQuizScore += score;
            totalQuizMax += maxScore;
          }
        }
        if (totalQuizMax > 0) {
          quizAverage = (totalQuizScore / totalQuizMax) * 100;
        }
      }

      return {
        'readingLevel': readingLevel,
        'totalTasks': assignedTaskIds.length,
        'completedTasks': submittedMaterials,
        'pendingTasks': totalMaterials - submittedMaterials,
        'totalCorrect': totalCorrect,
        'totalWrong': totalWrong,
        'averageScore': averageScore,
        'totalQuizzes': totalQuizzes,
        'completedQuizzes': completedQuizzes,
        'pendingQuizzes': pendingQuizzes,
        'quizAverage': quizAverage,
        'quizSubmissions': quizSubmissionList,
      };
    } catch (e) {
      debugPrint('❌ Error fetching child progress: $e');
      return null;
    }
  }
}
