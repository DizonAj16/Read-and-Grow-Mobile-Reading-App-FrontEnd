import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParentService {
  final supabase = Supabase.instance.client;

  /// Fetch all children linked to this parent (via parent_student_relationships)
  Future<List<Map<String, dynamic>>> getChildrenSummary(String parentUserId) async {
    try {
      debugPrint('🔍 Fetching children for parentUserId (auth ID): $parentUserId');

      // Step 1: Find the parent record matching this auth user ID
      final parentRecord = await supabase
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
          .select('id, student_name, current_reading_level_id')
          .inFilter('id', studentIds); // ✅ Using user_id since that’s what relationship links to

      List<Map<String, dynamic>> childrenList = [];

      for (final student in studentsResp) {
        final studentId = student['id'] as String;
        final studentName = student['student_name'] as String;
        final levelId = student['current_reading_level_id'] as String?;

        // Step 4: Get reading level title
        String readingLevel = 'Not Set';
        if (levelId != null) {
          final levelResp = await supabase
              .from('reading_levels')
              .select('title')
              .eq('id', levelId)
              .maybeSingle();
          readingLevel = levelResp?['title'] ?? 'Unknown';
        }

        // Step 5: Get all tasks assigned to student's classes
        // First, get all classes the student is enrolled in
        final enrollments = await supabase
            .from('student_enrollments')
            .select('class_room_id')
            .eq('student_id', studentId);
        
        final classIds = enrollments.map((e) => e['class_room_id'] as String).toList();
        
        // Get all assignments for these classes with tasks and quizzes
        // Important: If a task has a quiz, we count the quiz, not the task (to avoid double counting)
        List<String> assignedTaskIds = []; // Only tasks WITHOUT quizzes
        List<String> assignedQuizIds = []; // All quizzes (from tasks or directly linked)
        Set<String> tasksWithQuizzes = {}; // Track which tasks have quizzes
        
        if (classIds.isNotEmpty) {
          final assignments = await supabase
              .from('assignments')
              .select('task_id, quiz_id, tasks(id, quizzes(id))')
              .inFilter('class_room_id', classIds);
          
          for (var assignment in assignments) {
            // Handle quiz_id assignments (quizzes directly linked to assignment)
            final directQuizId = assignment['quiz_id'] as String?;
            if (directQuizId != null && !assignedQuizIds.contains(directQuizId)) {
              assignedQuizIds.add(directQuizId);
            }
            
            // Handle task_id assignments
            final taskId = assignment['task_id'] as String?;
            if (taskId != null) {
              // Check if this task has quizzes
              final task = assignment['tasks'] as Map<String, dynamic>?;
              bool taskHasQuiz = false;
              
              if (task != null) {
                final quizzes = task['quizzes'] as List?;
                if (quizzes != null && quizzes.isNotEmpty) {
                  taskHasQuiz = true;
                  tasksWithQuizzes.add(taskId);
                  // Add quizzes from this task
                  for (var quiz in quizzes) {
                    final quizId = quiz['id'] as String?;
                    if (quizId != null && !assignedQuizIds.contains(quizId)) {
                      assignedQuizIds.add(quizId);
                    }
                  }
                }
              }
              
              // Only add task to assignedTaskIds if it doesn't have a quiz
              // Tasks with quizzes are counted via their quizzes to avoid double counting
              if (!taskHasQuiz && !assignedTaskIds.contains(taskId)) {
                assignedTaskIds.add(taskId);
              }
            }
          }
        }
        
        // Step 6: Get task progress - count based on completed and pending
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

        // Filter out tasks with quizzes from task counts (they're counted via their quizzes)
        Set<String> completedTasksWithoutQuizzes = completedTaskIds.where((id) => !tasksWithQuizzes.contains(id)).toSet();
        Set<String> pendingTasksWithoutQuizzes = pendingTaskIds.where((id) => !tasksWithQuizzes.contains(id)).toSet();

        // Count newly assigned tasks (without quizzes) that haven't been started yet
        int newPendingTasks = 0;
        for (var taskId in assignedTaskIds) {
          // assignedTaskIds already excludes tasks with quizzes
          if (!completedTasksWithoutQuizzes.contains(taskId) && !pendingTasksWithoutQuizzes.contains(taskId)) {
            newPendingTasks++;
          }
        }
        
        // Count completed tasks (only tasks without quizzes)
        int completedTasks = completedTasksWithoutQuizzes.length;
        
        // Count pending tasks (existing pending without quizzes + newly assigned)
        int pendingTasks = pendingTasksWithoutQuizzes.length + newPendingTasks;
        
        // Total tasks = only tasks without quizzes (tasks with quizzes are counted via quizzes)
        int totalTasks = assignedTaskIds.length;

        double totalScore = 0;
        double totalMax = 0;
        for (final t in taskProgress) {
          totalScore += (t['score'] ?? 0).toDouble();
          totalMax += (t['max_score'] ?? 0).toDouble();
        }
        double avgScore = totalMax > 0 ? (totalScore / totalMax) * 100 : 0;

        // Step 7: Quiz submissions - get completed quiz IDs and scores
        // Include both quizzes linked through tasks and quizzes directly linked via quiz_id
        final submissions = await supabase
            .from('student_submissions')
            .select('score, max_score, assignment_id, assignments(id, task_id, quiz_id, tasks(id, quizzes(id)), quiz:quizzes(id))')
            .eq('student_id', studentId);

        Set<String> completedQuizIds = {};
        for (var submission in submissions) {
          final assignment = submission['assignments'] as Map<String, dynamic>?;
          if (assignment != null) {
            // Check for quizzes directly linked via quiz_id in assignment
            final directQuiz = assignment['quiz'] as Map<String, dynamic>?;
            if (directQuiz != null) {
              final quizId = directQuiz['id'] as String?;
              if (quizId != null) {
                completedQuizIds.add(quizId);
              }
            }
            
            // Check for quizzes linked through tasks
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

        // Quiz count = total assigned quizzes
        int quizCount = assignedQuizIds.length;
        double quizAvg = 0;
        
        // Calculate quiz average from submissions (as percentage)
        if (submissions.isNotEmpty) {
          double totalScore = 0;
          double totalMax = 0;
          for (var s in submissions) {
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

        childrenList.add({
          'studentId': studentId,
          'studentName': studentName,
          'readingLevel': readingLevel,
          'totalTasks': totalTasks,
          'completedTasks': completedTasks,
          'pendingTasks': pendingTasks,
          'averageScore': avgScore,
          'quizCount': quizCount,
          'quizAverage': quizAvg,
        });
      }

      debugPrint('✅ Found ${childrenList.length} children.');
      return childrenList;
    } catch (e) {
      debugPrint('❌ Error fetching children summary: $e');
      return [];
    }
  }

  /// Fetch detailed progress for a single child
  Future<Map<String, dynamic>?> getChildProgress(String studentId) async {
    try {
      debugPrint('📘 Fetching progress for studentId: $studentId');

      // Step 1: Get reading level
      final studentResp = await supabase
          .from('students')
          .select('current_reading_level_id')
          .eq('id', studentId)
          .maybeSingle();

      String readingLevel = 'Not Set';
      if (studentResp != null &&
          studentResp['current_reading_level_id'] != null) {
        final levelResp = await supabase
            .from('reading_levels')
            .select('title')
            .eq('id', studentResp['current_reading_level_id'])
            .maybeSingle();
        readingLevel = levelResp?['title'] ?? 'Not Set';
      }

        // Step 2: Get all classes the student is enrolled in
        final enrollments = await supabase
            .from('student_enrollments')
            .select('class_room_id')
            .eq('student_id', studentId);
        
        final classIds = enrollments.map((e) => e['class_room_id'] as String).toList();
        
        // Step 3: Get all tasks assigned to student's classes through assignments
        // Important: If a task has a quiz, we count the quiz, not the task (to avoid double counting)
        List<String> assignedTaskIds = []; // Only tasks WITHOUT quizzes
        List<String> assignedQuizIds = []; // All quizzes (from tasks or directly linked)
        Set<String> tasksWithQuizzes = {}; // Track which tasks have quizzes
        
        if (classIds.isNotEmpty) {
          final assignments = await supabase
              .from('assignments')
              .select('task_id, quiz_id, tasks(id, quizzes(id))')
              .inFilter('class_room_id', classIds);
          
          for (var assignment in assignments) {
            // Handle quiz_id assignments (quizzes directly linked to assignment)
            final directQuizId = assignment['quiz_id'] as String?;
            if (directQuizId != null && !assignedQuizIds.contains(directQuizId)) {
              assignedQuizIds.add(directQuizId);
            }
            
            // Handle task_id assignments
            final taskId = assignment['task_id'] as String?;
            if (taskId != null) {
              // Check if this task has quizzes
              final task = assignment['tasks'] as Map<String, dynamic>?;
              bool taskHasQuiz = false;
              
              if (task != null) {
                final quizzes = task['quizzes'] as List?;
                if (quizzes != null && quizzes.isNotEmpty) {
                  taskHasQuiz = true;
                  tasksWithQuizzes.add(taskId);
                  // Add quizzes from this task
                  for (var quiz in quizzes) {
                    final quizId = quiz['id'] as String?;
                    if (quizId != null && !assignedQuizIds.contains(quizId)) {
                      assignedQuizIds.add(quizId);
                    }
                  }
                }
              }
              
              // Only add task to assignedTaskIds if it doesn't have a quiz
              // Tasks with quizzes are counted via their quizzes to avoid double counting
              if (!taskHasQuiz && !assignedTaskIds.contains(taskId)) {
                assignedTaskIds.add(taskId);
              }
            }
          }
        }
        
        // Step 4: Task progress - count based on completed and pending
        final taskProgress = await supabase
            .from('student_task_progress')
            .select('task_id, score, max_score, correct_answers, wrong_answers, completed')
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

        // Filter out tasks with quizzes from task counts (they're counted via their quizzes)
        Set<String> completedTasksWithoutQuizzes = completedTaskIds.where((id) => !tasksWithQuizzes.contains(id)).toSet();
        Set<String> pendingTasksWithoutQuizzes = pendingTaskIds.where((id) => !tasksWithQuizzes.contains(id)).toSet();

        // Count newly assigned tasks (without quizzes) that haven't been started yet
        int newPendingTasks = 0;
        for (var taskId in assignedTaskIds) {
          // assignedTaskIds already excludes tasks with quizzes
          if (!completedTasksWithoutQuizzes.contains(taskId) && !pendingTasksWithoutQuizzes.contains(taskId)) {
            newPendingTasks++;
          }
        }
        
        // Count completed tasks (only tasks without quizzes)
        int completedTasks = completedTasksWithoutQuizzes.length;
        
        // Count pending tasks (existing pending without quizzes + newly assigned)
        int pendingTasks = pendingTasksWithoutQuizzes.length + newPendingTasks;
        
        // Total tasks = only tasks without quizzes (tasks with quizzes are counted via quizzes)
        int totalTasks = assignedTaskIds.length;

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

      // Step 5: Quiz submissions - get completed quiz IDs and detailed submission data
      // Note: assignedQuizIds was already collected in Step 3 above
      // Include both quizzes linked through tasks and quizzes directly linked via quiz_id
      final quizSubmissions = await supabase
          .from('student_submissions')
          .select('score, max_score, submitted_at, assignment_id, assignments(id, task_id, quiz_id, tasks(id, quizzes(id)), quiz:quizzes(id, title))')
          .eq('student_id', studentId)
          .order('submitted_at', ascending: false);
      
      // Build list of quiz submission details with quiz titles
      List<Map<String, dynamic>> quizSubmissionList = [];
      Set<String> completedQuizIds = {};
      
      for (var submission in quizSubmissions) {
        final assignment = submission['assignments'] as Map<String, dynamic>?;
        String? quizTitle;
        
        if (assignment != null) {
          // Check for quiz directly linked via quiz_id
          final directQuiz = assignment['quiz'] as Map<String, dynamic>?;
          if (directQuiz != null) {
            final quizId = directQuiz['id'] as String?;
            quizTitle = directQuiz['title'] as String?;
            if (quizId != null) {
              completedQuizIds.add(quizId);
            }
          } else {
            // Check for quiz linked through task
            final task = assignment['tasks'] as Map<String, dynamic>?;
            if (task != null) {
              final quizzes = task['quizzes'] as List?;
              if (quizzes != null && quizzes.isNotEmpty) {
                final quiz = quizzes.first as Map<String, dynamic>;
                final quizId = quiz['id'] as String?;
                quizTitle = quiz['title'] as String?;
                if (quizId != null) {
                  completedQuizIds.add(quizId);
                }
              }
            }
          }
        }
        
        quizSubmissionList.add({
          'score': submission['score'],
          'max_score': submission['max_score'],
          'submitted_at': submission['submitted_at'],
          'quiz_title': quizTitle ?? 'Quiz',
        });
      }

      // Calculate quiz statistics
      int totalQuizzes = assignedQuizIds.length;
      int completedQuizzes = completedQuizIds.length;
      int pendingQuizzes = totalQuizzes - completedQuizzes;
      
      // Calculate quiz average score
      double quizAverage = 0;
      if (quizSubmissionList.isNotEmpty) {
        double totalScore = 0;
        double totalMax = 0;
        for (var sub in quizSubmissionList) {
          final score = (sub['score'] ?? 0).toDouble();
          final maxScore = (sub['max_score'] ?? 0).toDouble();
          if (maxScore > 0) {
            totalScore += score;
            totalMax += maxScore;
          }
        }
        if (totalMax > 0) {
          quizAverage = (totalScore / totalMax) * 100;
        }
      }

      return {
        'readingLevel': readingLevel,
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'pendingTasks': pendingTasks,
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
