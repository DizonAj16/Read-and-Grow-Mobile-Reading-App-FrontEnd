import 'package:deped_reading_app_laravel/helper/QuizHelper.dart';
import 'package:flutter/material.dart';
import 'package:deped_reading_app_laravel/api/supabase_api_service.dart';
import 'package:deped_reading_app_laravel/models/quiz_questions.dart';

class QuizPreviewScreenInteractive extends StatefulWidget {
  final String quizId;
  final String userRole;
  final String loggedInUserId;
  final String taskId;

  const QuizPreviewScreenInteractive({
    super.key,
    required this.quizId,
    required this.userRole,
    required this.loggedInUserId,
    required this.taskId,
  });

  @override
  State<QuizPreviewScreenInteractive> createState() =>
      _QuizPreviewScreenInteractiveState();
}

class _QuizPreviewScreenInteractiveState
    extends State<QuizPreviewScreenInteractive> {
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  QuizHelper? _quizHelper;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);

    try {
      final questionsData = await ApiService.getQuizQuestions(widget.quizId) ?? [];

      if (questionsData.isNotEmpty && questionsData.first is Map<String, dynamic>) {
        _questions = questionsData
            .map<QuizQuestion>((e) => QuizQuestion.fromMap(e as Map<String, dynamic>))
            .toList();
      } else if (questionsData.isNotEmpty && questionsData.first is QuizQuestion) {
        _questions = List<QuizQuestion>.from(questionsData);
      } else {
        _questions = [];
      }

      if (_questions.isNotEmpty && widget.userRole == 'student') {
        _quizHelper = QuizHelper(
          studentId: widget.loggedInUserId,
          taskId: widget.taskId,
          questions: _questions,
          supabase: ApiService.supabase,
        );

        // Start timer synced with database
        await _quizHelper!.startTimerFromDatabase(
          _submitQuiz,           // onTimeUp
              () => setState(() {}), // onTick
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading quiz: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _submitQuiz() async {
    if (_quizHelper != null) {
      await _quizHelper!.submitQuiz();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quiz submitted! Score: ${_quizHelper!.score}')),
      );
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) setState(() => _currentIndex++);
  }

  void _prevQuestion() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_questions.isEmpty) return const Scaffold(body: Center(child: Text('No questions')));

    final q = _questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(title: Text('Question ${_currentIndex + 1}/${_questions.length}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.questionText, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            if (q.type == QuestionType.multipleChoice && q.options!.isNotEmpty)
              Column(
                children: List.generate(q.options!.length, (i) {
                  return ListTile(
                    title: Text(q.options![i]),
                    leading: Radio<String>(
                      value: q.options![i],
                      groupValue: q.userAnswer,
                      onChanged: (val) => setState(() => q.userAnswer = val ?? ''),
                    ),
                  );
                }),
              ),
            if (q.type == QuestionType.fillInTheBlank)
              TextField(
                decoration: const InputDecoration(labelText: 'Your Answer'),
                onChanged: (val) => q.userAnswer = val,
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  ElevatedButton(onPressed: _prevQuestion, child: const Text('Previous')),
                if (_currentIndex < _questions.length - 1)
                  ElevatedButton(onPressed: _nextQuestion, child: const Text('Next')),
                if (_currentIndex == _questions.length - 1)
                  ElevatedButton(onPressed: _submitQuiz, child: const Text('Submit')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
