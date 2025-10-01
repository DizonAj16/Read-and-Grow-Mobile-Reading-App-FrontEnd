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
      // Fetch quiz title
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

      // Fetch quiz questions
      final qRes = await supabase
          .from('quiz_questions')
          .select('*, question_options(*), matching_pairs!matching_pairs_question_id_fkey(*)')
          .eq('quiz_id', widget.quizId)
          .order('sort_order', ascending: true);

      questions = qRes.map<QuizQuestion>((q) => QuizQuestion.fromMap(q)).toList();

      // Initialize QuizHelper
      quizHelper = QuizHelper(
        studentId: widget.studentId,
        taskId: widget.assignmentId,
        questions: questions,
        supabase: supabase,
      );

      // Start timer from database
      quizHelper!.startTimerFromDatabase(
            () => _submitQuiz(auto: true), // onTimeUp
            () => setState(() {}),          // onTick
      );

    } catch (e, stack) {
      debugPrint("❌ Error loading quiz: $e");
      debugPrint(stack.toString());
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _submitQuiz({bool auto = false}) async {
    if (quizHelper == null) return;

    final supabase = quizHelper!.supabase;

    // 1️⃣ Get the `assignment_id` using `task_id`
    final assignmentRes = await supabase
        .from('assignments')
        .select('id')
        .eq('task_id', quizHelper!.taskId) // Look for the assignment based on task_id
        .single();

    if (assignmentRes == null) {
      // Handle the case where the assignment doesn't exist
      print("No assignment found for task_id ${quizHelper!.taskId}");
      return;
    }

    final assignmentId = assignmentRes['id'];

    // 2️⃣ Get the `student_id` directly from `users` table (since you're not using a separate students table)
    final studentRes = await supabase
        .from('users')
        .select('id')
        .eq('role', 'student') // Ensure you're getting the student role
        .eq('id', widget.studentId) // Pass the `user_id` here which acts as student ID
        .single();

    if (studentRes == null) {
      // Handle the case where the user is not a student
      print("No student found with user_id ${widget.studentId}");
      return;
    }

    final studentId = studentRes['id']; // This is the 'user' ID for the student (used as student_id)

    // 3️⃣ Calculate score for all question types
    int correct = 0;
    int wrong = 0;
    final List<Map<String, dynamic>> activityDetails = [];

    for (var q in quizHelper!.questions) {
      bool isCorrect = false;

      switch (q.type) {
        case QuestionType.multipleChoice:
        case QuestionType.fillInTheBlank:
        // Fetch options for this question
          final optionsRes = await supabase
              .from('question_options')
              .select('question_id, option_text, is_correct')
              .filter('question_id', 'in', '(${q.id})'); // fixed `.in_()`

          List opts = optionsRes as List? ?? [];

          if (opts.isNotEmpty) {
            final correctOption = opts.firstWhere(
                  (o) => o['is_correct'] == true,
              orElse: () => opts.first as Map<String, dynamic>, // Explicit cast
            );

            isCorrect = q.userAnswer.trim() == correctOption['option_text'].trim();
          }
          break;

        case QuestionType.matching:
          isCorrect = q.matchingPairs!.every((p) => p.userSelected == p.leftItem);
          break;

        case QuestionType.dragAndDrop:
        // example logic
          isCorrect = q.options!.asMap().entries.every((e) => e.key == e.value);
          break;

        default:
          isCorrect = false;
      }

      if (isCorrect) correct++;
      else wrong++;

      activityDetails.add(q.toMap());
    }

    // 4️⃣ Update helper score
    quizHelper!.score = correct;

    // 5️⃣ Update student_task_progress
    final progressUpdate = {
      'student_id': studentId, // Using the user_id as student_id here
      'task_id': quizHelper!.taskId,
      'attempts_left': (3 - quizHelper!.currentAttempt),
      'score': correct,
      'max_score': quizHelper!.questions.length,
      'activity_details': activityDetails,
      'correct_answers': correct,
      'wrong_answers': wrong,
      'completed': correct == quizHelper!.questions.length,
      'updated_at': DateTime.now().toIso8601String(),
    };

    await supabase.from('student_task_progress').upsert(progressUpdate);

    // 6️⃣ Store individual submission attempt with correct `assignment_id`
    await supabase.from('student_submissions').insert({
      'assignment_id': assignmentId, // Use the retrieved assignment_id
      'student_id': studentId, // Use the user_id (student_id) here
      'attempt_number': quizHelper!.currentAttempt,
      'score': correct,
      'max_score': quizHelper!.questions.length,
      'quiz_answers': activityDetails,
      'submitted_at': DateTime.now().toIso8601String(),
    });

    // 7️⃣ Increment attempt counter
    quizHelper!.currentAttempt++;

    // 8️⃣ Show result dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(auto ? "Time's Up!" : "Quiz Submitted"),
        content: Text("Your score: $correct / ${quizHelper!.questions.length}"),
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
        automaticallyImplyLeading: false,
        title: null,
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
