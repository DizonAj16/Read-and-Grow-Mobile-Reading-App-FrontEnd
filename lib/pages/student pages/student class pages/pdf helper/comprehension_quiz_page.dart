import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComprehensionQuizPage extends StatefulWidget {
  final String taskId;
  final String studentId;
  const ComprehensionQuizPage({
    super.key,
    required this.taskId,
    required this.studentId,
  });

  @override
  State<ComprehensionQuizPage> createState() => _ComprehensionQuizPageState();
}

class _ComprehensionQuizPageState extends State<ComprehensionQuizPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> questions = [];
  int currentIndex = 0;
  int score = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final res = await supabase
          .from('quizzes')
          .select(
          'id, quiz_questions(id, question_text, question_options(option_text, is_correct))')
          .eq('task_id', widget.taskId)
          .maybeSingle();

      if (res != null && res['quiz_questions'] != null) {
        setState(() {
          questions = List<Map<String, dynamic>>.from(res['quiz_questions']);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading quiz: $e");
      setState(() => isLoading = false);
    }
  }

  void _submitAnswer(Map<String, dynamic> question, String selected) {
    final options = List<Map<String, dynamic>>.from(question['question_options']);
    final correct = options.firstWhere((o) => o['option_text'] == selected)['is_correct'] as bool;

    if (correct) score++;

    if (currentIndex < questions.length - 1) {
      setState(() => currentIndex++);
    } else {
      _finishQuiz();
    }
  }

  Future<void> _finishQuiz() async {
    try {
      await supabase.from('student_submissions').insert({
        'student_id': widget.studentId,
        'score': score,
        'max_score': questions.length,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      // Update progress
      await supabase.from('student_task_progress').update({
        'score': score,
        'max_score': questions.length,
        'completed': true,
        'attempts_left': supabase.rpc('decrement_attempt', params: {'task_id': widget.taskId}),
      }).eq('task_id', widget.taskId).eq('student_id', widget.studentId);

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("🎉 Quiz Completed"),
            content: Text("You scored $score out of ${questions.length}!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("Done"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error saving quiz: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Comprehension Quiz")),
        body: const Center(child: Text("No questions available for this task.")),
      );
    }

    final question = questions[currentIndex];
    final options = List<Map<String, dynamic>>.from(question['question_options']);

    return Scaffold(
      appBar: AppBar(title: const Text("Comprehension Quiz")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Question ${currentIndex + 1}/${questions.length}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              question['question_text'],
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ...options.map((opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ElevatedButton(
                onPressed: () => _submitAnswer(question, opt['option_text']),
                child: Text(opt['option_text']),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
