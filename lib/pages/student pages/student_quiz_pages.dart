import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deped_reading_app_laravel/helper/QuizHelper.dart';
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
  String quizTitle = "Quiz";
  QuizHelper? quizHelper;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final supabase = Supabase.instance.client;

    try {
      debugPrint("📡 Fetching quiz title for quizId: ${widget.quizId}");
      final quizRes = await supabase
          .from('quizzes')
          .select('title')
          .eq('id', widget.quizId)
          .single();

      if (quizRes == null || quizRes.isEmpty) {
        debugPrint("⚠️ No quiz found with ID: ${widget.quizId}");
        return;
      }

      quizTitle = quizRes['title'] ?? "Quiz";
      debugPrint("✅ Quiz title loaded: $quizTitle");

      debugPrint("📡 Fetching questions for quizId: ${widget.quizId}");
      final qRes = await supabase
          .from('quiz_questions')
          .select('*, question_options(*), matching_pairs!matching_pairs_question_id_fkey(*)')
          .eq('quiz_id', widget.quizId)
          .order('sort_order', ascending: true);

      debugPrint("📥 Raw questions response: $qRes");

      questions = qRes.map<QuizQuestion>((q) => QuizQuestion.fromMap(q)).toList();
      debugPrint("✅ Parsed ${questions.length} questions");

      quizHelper = QuizHelper(
        studentId: widget.studentId,
        taskId: widget.assignmentId,
        questions: questions,
        supabase: supabase,
      );

      // Timer check
      if (questions.isNotEmpty && questions.first.timeLimitSeconds != null) {
        debugPrint("⏱ Starting timer for ${questions.first.timeLimitSeconds} seconds");
        quizHelper!.startTimer(
          questions.first.timeLimitSeconds!,
              () => _submitQuiz(auto: true),
              () => setState(() {}),
        );
      } else {
        debugPrint("⏱ No timer found for first question.");
      }

    } catch (e, stack) {
      debugPrint("❌ Error loading quiz: $e");
      debugPrint(stack.toString());
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _submitQuiz({bool auto = false}) async {
    await quizHelper?.submitQuiz();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(auto ? "Time's Up!" : "Quiz Submitted"),
        content: Text("Your score: ${quizHelper?.score ?? 0} / ${questions.length}"),
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
          if (quizHelper?.timeRemaining != null && quizHelper!.timeRemaining > 0)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(
                  _formatTime(quizHelper!.timeRemaining),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: QuizPreviewScreen(
        title: quizTitle,
        questions: questions,
        isPreview: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _submitQuiz(),
        label: const Text("Submit Quiz"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
