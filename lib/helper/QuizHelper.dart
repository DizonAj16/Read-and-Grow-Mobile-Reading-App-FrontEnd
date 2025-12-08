import 'dart:async';
import 'package:flutter/foundation.dart';
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

  // Add this flag to track timer state
  bool _isTimerRunning = false;

  QuizHelper({
    required this.studentId,
    required this.taskId,
    required this.questions,
    required this.supabase,
    this.maxAttempts = 3,
  });

  /// Fetch time_limit_minutes from tasks table
  Future<int> fetchTaskTimeLimit() async {
    final task =
        await supabase
            .from('tasks')
            .select('time_limit_minutes')
            .eq('id', taskId)
            .maybeSingle();
    return task?['time_limit_minutes'] ?? 0;
  }

  /// Start timer synced with database
  Future<void> startTimerFromDatabase(
    VoidCallback onTimeUp,
    VoidCallback onTick,
  ) async {
    final minutes = await fetchTaskTimeLimit();
    timeRemaining = minutes * 60;
    
    // Cancel any existing timer
    timer?.cancel();
    
    _isTimerRunning = true;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_isTimerRunning) {
        t.cancel();
        return;
      }
      
      if (timeRemaining <= 0) {
        t.cancel();
        _isTimerRunning = false;
        onTimeUp();
      } else {
        timeRemaining--;
        onTick();
      }
    });
  }

  /// Stop timer completely
  void stopTimer() {
    _isTimerRunning = false;
    timer?.cancel();
    timer = null;
    debugPrint('⏹️ QuizHelper timer stopped');
  }

  /// Calculate score
  void calculateScore() {
    int tempScore = 0;
    for (var q in questions) {
      if (q.userAnswer.isNotEmpty && q.userAnswer == q.correctAnswer) {
        tempScore++;
      } else if (q.type == QuestionType.matching) {
        if (q.matchingPairs!.every((p) => p.userSelected == p.leftItem)) {
          tempScore++;
        }
      }
    }
    score = tempScore;
  }

  /// Submit quiz
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

  /// Cancel timer (alias for stopTimer for backward compatibility)
  void cancelTimer() {
    stopTimer();
  }
}