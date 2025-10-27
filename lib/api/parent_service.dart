import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParentService {
  final supabase = Supabase.instance.client;

  /// Fetch summary of all children for a parent
  Future<List<Map<String, dynamic>>> getChildrenSummary(String parentId) async {
    try {
      final studentsResp = await supabase
          .from('students')
          .select('id, student_name, current_reading_level_id')
          .eq('parent_id', parentId);

      List<Map<String, dynamic>> childrenList = [];

      for (final student in studentsResp) {
        final studentId = student['id'] as String;
        final studentName = student['student_name'] as String;
        final levelId = student['current_reading_level_id'] as String?;

        // Get reading level info
        String readingLevel = 'Not Set';
        if (levelId != null) {
          final levelResp = await supabase
              .from('reading_levels')
              .select('title')
              .eq('id', levelId)
              .maybeSingle();
          
          if (levelResp != null) {
            readingLevel = levelResp['title'] ?? 'Unknown';
          }
        }

        // Get task progress
        final taskProgress = await supabase
            .from('student_task_progress')
            .select('score, max_score, completed')
            .eq('student_id', studentId);

        int totalTasks = taskProgress.length;
        int completedTasks = taskProgress.where((t) => t['completed'] == true).length;
        double totalScore = 0;
        double totalMax = 0;

        for (final task in taskProgress) {
          totalScore += (task['score'] ?? 0).toDouble();
          totalMax += (task['max_score'] ?? 0).toDouble();
        }

        double avgScore = totalMax > 0 ? (totalScore / totalMax) * 100 : 0;

        // Get quiz submissions count
        final submissions = await supabase
            .from('student_submissions')
            .select('id, score')
            .eq('student_id', studentId);

        int quizCount = submissions.length;
        double quizAvg = 0;

        if (submissions.isNotEmpty) {
          final scores = submissions.map((s) => (s['score'] ?? 0).toDouble()).toList();
          quizAvg = scores.reduce((a, b) => a + b) / scores.length;
        }

        childrenList.add({
          'studentId': studentId,
          'studentName': studentName,
          'readingLevel': readingLevel,
          'totalTasks': totalTasks,
          'completedTasks': completedTasks,
          'averageScore': avgScore,
          'quizCount': quizCount,
          'quizAverage': quizAvg,
        });
      }

      return childrenList;
    } catch (e) {
      debugPrint('Error fetching children summary: $e');
      return [];
    }
  }

  /// Fetch detailed progress data for a specific child
  Future<Map<String, dynamic>?> getChildProgress(String studentId) async {
    try {
      // Get student info
      final studentResp = await supabase
          .from('students')
          .select('current_reading_level_id')
          .eq('id', studentId)
          .maybeSingle();

      String readingLevel = 'Not Set';
      if (studentResp != null && studentResp['current_reading_level_id'] != null) {
        final levelId = studentResp['current_reading_level_id'] as String;
        final levelResp = await supabase
            .from('reading_levels')
            .select('title')
            .eq('id', levelId)
            .maybeSingle();

        readingLevel = levelResp?['title'] ?? 'Not Set';
      }

      // Get task progress
      final taskProgress = await supabase
          .from('student_task_progress')
          .select('score, max_score, correct_answers, wrong_answers, completed')
          .eq('student_id', studentId);

      int totalTasks = taskProgress.length;
      int completedTasks = taskProgress.where((t) => t['completed'] == true).length;

      double totalScore = 0;
      double totalMax = 0;
      int totalCorrect = 0;
      int totalWrong = 0;

      for (final task in taskProgress) {
        totalScore += (task['score'] ?? 0).toDouble();
        totalMax += (task['max_score'] ?? 0).toDouble();
        totalCorrect += (task['correct_answers'] ?? 0) as int;
        totalWrong += (task['wrong_answers'] ?? 0) as int;
      }

      double averageScore = totalMax > 0 ? (totalScore / totalMax) * 100 : 0;

      // Get quiz submissions
      final submissions = await supabase
          .from('student_submissions')
          .select('id, score, max_score, submitted_at')
          .eq('student_id', studentId)
          .order('submitted_at', ascending: false);

      return {
        'readingLevel': readingLevel,
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'totalCorrect': totalCorrect,
        'totalWrong': totalWrong,
        'averageScore': averageScore,
        'quizSubmissions': List<Map<String, dynamic>>.from(submissions),
      };
    } catch (e) {
      debugPrint('Error fetching child progress: $e');
      return null;
    }
  }
}
