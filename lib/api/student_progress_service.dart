import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_progress.dart';

class StudentProgressService {
  final supabase = Supabase.instance.client;

  Future<List<StudentProgress>> getClassProgress(String classId) async {
    try {
      final studentEnrollments = await supabase
          .from('student_enrollments')
          .select('student_id, students(student_name)')
          .eq('class_room_id', classId);

      List<StudentProgress> progressList = [];

      for (final s in studentEnrollments) {
        final studentId = s['student_id'] as String;
        final studentName = (s['students'] as Map<String, dynamic>)['student_name'] as String;
        final tasks = await supabase
            .from('student_task_progress')
            .select('score, max_score, correct_answers, wrong_answers')
            .eq('student_id', studentId);

        final totalScore = tasks.fold<int>(
            0, (sum, t) => sum + ((t['score'] ?? 0) as int));
        final totalMaxScore = tasks.fold<int>(
            0, (sum, t) => sum + ((t['max_score'] ?? 0) as int));
        final totalCorrect = tasks.fold<int>(
            0, (sum, t) => sum + ((t['correct_answers'] ?? 0) as int));
        final totalWrong = tasks.fold<int>(
            0, (sum, t) => sum + ((t['wrong_answers'] ?? 0) as int));

        final avgScore = totalMaxScore > 0
            ? (totalScore / totalMaxScore) * 100
            : 0.0;

        progressList.add(StudentProgress(
          studentId: studentId,
          studentName: studentName,
          readingTime: totalScore,
          miscues: totalWrong,
          quizAverage: avgScore,
          quizResults: List<Map<String, dynamic>>.from(tasks),
        ));
      }

      return progressList;
    } catch (e) {
      print("❌ Error fetching class progress: $e");
      return [];
    }
  }
}
