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

        // Step 5: Task progress
        final taskProgress = await supabase
            .from('student_task_progress')
            .select('score, max_score, completed')
            .eq('student_id', studentId);

        int totalTasks = taskProgress.length;
        int completedTasks =
            taskProgress.where((t) => t['completed'] == true).length;

        double totalScore = 0;
        double totalMax = 0;
        for (final t in taskProgress) {
          totalScore += (t['score'] ?? 0).toDouble();
          totalMax += (t['max_score'] ?? 0).toDouble();
        }
        double avgScore = totalMax > 0 ? (totalScore / totalMax) * 100 : 0;

        // Step 6: Quiz submissions
        final submissions = await supabase
            .from('student_submissions')
            .select('score')
            .eq('student_id', studentId);

        int quizCount = submissions.length;
        double quizAvg = 0;
        if (quizCount > 0) {
          final scores =
          submissions.map((s) => (s['score'] ?? 0).toDouble()).toList();
          quizAvg = scores.reduce((a, b) => a + b) / quizCount;
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

      // Step 2: Task progress
      final taskProgress = await supabase
          .from('student_task_progress')
          .select('score, max_score, correct_answers, wrong_answers, completed')
          .eq('student_id', studentId);

      int totalTasks = taskProgress.length;
      int completedTasks =
          taskProgress.where((t) => t['completed'] == true).length;

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

      // Step 3: Quiz submissions
      final quizSubmissions = await supabase
          .from('student_submissions')
          .select('score, max_score, submitted_at')
          .eq('student_id', studentId)
          .order('submitted_at', ascending: false);

      return {
        'readingLevel': readingLevel,
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'totalCorrect': totalCorrect,
        'totalWrong': totalWrong,
        'averageScore': averageScore,
        'quizSubmissions': List<Map<String, dynamic>>.from(quizSubmissions),
      };
    } catch (e) {
      debugPrint('❌ Error fetching child progress: $e');
      return null;
    }
  }
}
