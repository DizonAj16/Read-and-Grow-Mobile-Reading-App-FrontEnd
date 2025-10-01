import 'dart:async';
import 'package:flutter/foundation.dart'; // for VoidCallback
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_questions.dart';

class QuizHelper {
  final String studentId;
  final String taskId;
  final List<QuizQuestion> questions;
  final int maxAttempts;
  int currentAttempt = 1;
  int score = 0;
  Timer? timer;
  int timeRemaining = 0;
  final SupabaseClient supabase;

  QuizHelper({
    required this.studentId,
    required this.taskId,
    required this.questions,
    required this.supabase,
    this.maxAttempts = 3,
  });

  void startTimer(int seconds, VoidCallback onTimeUp, VoidCallback onTick) {
    timeRemaining = seconds;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeRemaining <= 0) {
        t.cancel();
        onTimeUp();
      } else {
        timeRemaining--;
        onTick();
      }
    });
  }

  void calculateScore() {
    int tempScore = 0;
    for (var q in questions) {
      if (q.userAnswer.isNotEmpty && q.userAnswer == q.correctAnswer) {
        tempScore++;
      }
    }
    score = tempScore;
  }

  Future<void> submitQuiz() async {
    calculateScore();
    if (currentAttempt > maxAttempts) return;

    final progress = {
      'student_id': studentId,
      'task_id': taskId,
      'attempts_left': maxAttempts - currentAttempt,
      'score': score,
      'max_score': questions.length,
      'activity_details': questions.map((q) => q.toMap()).toList(),
      'completed': score == questions.length,
    };

    await supabase.from('student_task_progress').upsert(progress);
    currentAttempt++;
  }

}
