import 'dart:convert';
import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/api/user_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/quiz_questions.dart';
import '../teacher pages/quiz_preview_screen.dart';


class StudentQuizPage extends StatefulWidget {
  final String quizId;
  final String assignmentId;
  final String studentId;

  const StudentQuizPage({
    super.key,
    required this.quizId,
    required this.assignmentId,
    required this.studentId,
  });

  @override
  State<StudentQuizPage> createState() => _StudentQuizPageState();
}

class _StudentQuizPageState extends State<StudentQuizPage> {
  bool loading = true;
  List<QuizQuestion> questions = [];
  String quizTitle = "";
  int? timeLimit; // seconds
  int remainingSeconds = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    final supabase = Supabase.instance.client;

    try {
      // 🔹 Fetch quiz info (including optional time_limit column in seconds)
      final quizRes = await supabase
          .from('quizzes')
          .select('quiz_title, questions, time_limit')
          .eq('id', widget.quizId)
          .single();

      quizTitle = quizRes['quiz_title'] ?? "Quiz";
      timeLimit = quizRes['time_limit']; // e.g., 600 seconds = 10 mins
      remainingSeconds = timeLimit ?? 0;

      // 🔹 Map DB questions into QuizQuestion model
      final List<dynamic> qList = quizRes['questions'] ?? [];
      questions = qList.map((q) => QuizQuestion.fromMap(q)).toList();

      // 🔹 Start countdown if time limit exists
      if (timeLimit != null && timeLimit! > 0) {
        timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (remainingSeconds > 0) {
            setState(() => remainingSeconds--);
          } else {
            t.cancel();
            _submitQuiz(auto: true);
          }
        });
      }

      setState(() => loading = false);
    } catch (e) {
      debugPrint("Error loading quiz: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _submitQuiz({bool auto = false}) async {
    timer?.cancel();

    int score = 0;

    for (var q in questions) {
      if (q.type == QuestionType.multipleChoice ||
          q.type == QuestionType.fillInTheBlank) {
        if (q.userAnswer?.trim().toLowerCase() ==
            q.correctAnswer?.trim().toLowerCase()) {
          score++;
        }
      } else if (q.type == QuestionType.dragAndDrop) {
        if (q.options?.join(",") == q.correctAnswer) score++;
      } else if (q.type == QuestionType.matching) {
        final allCorrect = q.matchingPairs!.every((p) =>
        p.userSelected?.trim().toLowerCase() ==
            p.correctAnswer?.trim().toLowerCase());
        if (allCorrect) score++;
      }
    }

    final supabase = Supabase.instance.client;

    await supabase.from('quiz_submissions').insert({
      'assignment_id': widget.assignmentId,
      'student_id': widget.studentId,
      'quiz_id': widget.quizId,
      'score': score,
      'submitted_at': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(auto ? "Time's Up!" : "Quiz Submitted"),
        content: Text("Your score: $score / ${questions.length}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(quizTitle),
        actions: [
          if (timeLimit != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  _formatTime(remainingSeconds),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ),
        ],
      ),
      body: QuizPreviewScreen(title: quizTitle, questions: questions),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _submitQuiz(),
        label: const Text("Submit Quiz"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
