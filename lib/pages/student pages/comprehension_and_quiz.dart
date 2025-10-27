import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum QuestionType { multipleChoice, trueFalse, fillInTheBlank }

class ComprehensionQuizPage extends StatefulWidget {
  final String studentId;
  final String storyId;
  final String levelId;

  const ComprehensionQuizPage({
    super.key,
    required this.studentId,
    required this.storyId,
    required this.levelId,
  });

  @override
  State<ComprehensionQuizPage> createState() => _ComprehensionQuizPageState();
}

class _ComprehensionQuizPageState extends State<ComprehensionQuizPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String quizTitle = "";
  List<Map<String, dynamic>> questions = [];
  Map<int, String> answers = {};
  Timer? timer;
  int? timeLimit;
  int remainingSeconds = 0;

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
    try {
      // 1️⃣ Fetch quiz info and linked task time limit
      final quizRes = await supabase
          .from('quizzes')
          .select('id, title, task:tasks(time_limit_minutes)')
          .eq('task_id', widget.storyId) // storyId = task_id
          .maybeSingle();

      if (quizRes == null) {
        setState(() {
          quizTitle = "No quiz available";
          loading = false;
        });
        return;
      }

      // 2️⃣ Extract quiz title and timer
      quizTitle = quizRes['title'] ?? "Comprehension Quiz";
      timeLimit = quizRes['task']?['time_limit_minutes'];
      remainingSeconds = timeLimit ?? 0;

      // 3️⃣ Fetch questions and their options
      final qRes = await supabase
          .from('quiz_questions')
          .select(
          'id, question_text, question_type, question_options(option_text, is_correct)'
      )
          .eq('quiz_id', quizRes['id'])
          .order('sort_order', ascending: true);

      questions = List<Map<String, dynamic>>.from(qRes);

      // 4️⃣ If there’s a time limit, start timer
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
    } catch (e, stack) {
      debugPrint("❌ Error loading quiz: $e");
      debugPrint(stack.toString());
      setState(() => loading = false);
    }
  }

  Future<void> _submitQuiz({bool auto = false}) async {
    timer?.cancel();

    int score = 0;

    for (var q in questions) {
      final qId = q['id'] as int;
      final correct = q['correct_answer'].toString().trim().toLowerCase();
      final user = (answers[qId] ?? '').trim().toLowerCase();

      if (correct == user) score++;
    }

    await supabase.from('quiz_submissions').insert({
      'student_id': widget.studentId,
      'quiz_id': questions.isNotEmpty ? questions.first['quiz_id'] : null,
      'story_id': widget.storyId,
      'level_id': widget.levelId,
      'score': score,
      'submitted_at': DateTime.now().toIso8601String(),
    });

    final passed = (score / questions.length) >= 0.7;
    if (passed) {
      await supabase.from('student_levels').update({'status': 'completed'}).match({
        'student_id': widget.studentId,
        'level_id': widget.levelId,
      });

      final nextLevel = await supabase
          .from('reading_levels')
          .select('id')
          .gt('id', int.parse(widget.levelId))
          .order('id')
          .limit(1)
          .maybeSingle();

      if (nextLevel != null) {
        await supabase.from('student_levels').insert({
          'student_id': widget.studentId,
          'level_id': nextLevel['id'],
          'status': 'active',
        });
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(auto ? "Time’s Up!" : "Quiz Submitted"),
        content: Text(
          "Your score: $score / ${questions.length}\n"
              "${passed ? "🎉 You unlocked the next level!" : "Try again to unlock the next level."}",
        ),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
      body: questions.isEmpty
          ? const Center(child: Text("No questions found"))
          : ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          final qId = q['id'] as int;
          final qType = q['type'];

          return Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${index + 1}. ${q['question_text']}",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  if (qType == 'multipleChoice')
                    Column(
                      children: (q['options'] as List<dynamic>)
                          .map((opt) => RadioListTile<String>(
                        title: Text(opt.toString()),
                        value: opt.toString(),
                        groupValue: answers[qId],
                        onChanged: (val) {
                          setState(() => answers[qId] = val ?? '');
                        },
                      ))
                          .toList(),
                    ),

                  if (qType == 'trueFalse')
                    Column(
                      children: ["True", "False"]
                          .map((opt) => RadioListTile<String>(
                        title: Text(opt),
                        value: opt,
                        groupValue: answers[qId],
                        onChanged: (val) {
                          setState(() => answers[qId] = val ?? '');
                        },
                      ))
                          .toList(),
                    ),

                  if (qType == 'fillInTheBlank')
                    TextField(
                      decoration:
                      const InputDecoration(labelText: "Your Answer"),
                      onChanged: (val) => answers[qId] = val,
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _submitQuiz(),
        label: const Text("Submit"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
