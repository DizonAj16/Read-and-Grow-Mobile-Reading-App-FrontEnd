  import 'package:flutter/material.dart';
  import '../../../../api/supabase_api_service.dart';
  import '../../../../models/quiz_questions.dart';
  import '../quiz_preview_screen.dart';

  class AddQuizScreen extends StatefulWidget {
    final String lessonId;

    const AddQuizScreen({super.key, required this.lessonId});

    @override
    State<AddQuizScreen> createState() => _AddQuizScreenState();
  }

  class _AddQuizScreenState extends State<AddQuizScreen> {
    final _quizTitleController = TextEditingController();
    List<QuizQuestion> _questions = [];
    bool _isLoading = false;

    void _addQuestion() {
      _questions.add(QuizQuestion(

        questionText: '',
        type: QuestionType.multipleChoice,
        options: List.filled(4, ''),
        matchingPairs: [],
      ));
      setState(() {});
    }

    Future<void> _submitQuiz() async {
      if (_quizTitleController.text.isEmpty || _questions.isEmpty) return;

      setState(() => _isLoading = true);

      final quiz = await ApiService.addQuiz(
        taskId: widget.lessonId,
        title: _quizTitleController.text,
        questions: _questions,
      );

      setState(() => _isLoading = false);

      if (quiz != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz added successfully!')));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizPreviewScreen(
              questions: _questions,
              title: _quizTitleController.text,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to add quiz')));
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Quiz')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextField(controller: _quizTitleController, decoration: const InputDecoration(labelText: 'Quiz Title')),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _addQuestion, child: const Text('Add Question')),
              const SizedBox(height: 10),
              // Render question list (same as before)
              ..._questions.map((q) {
                final index = _questions.indexOf(q);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(labelText: 'Question ${index + 1}'),
                          onChanged: (val) => q.questionText = val,
                        ),
                        DropdownButton<QuestionType>(
                          value: q.type,
                          items: QuestionType.values
                              .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                              .toList(),
                          onChanged: (val) => setState(() => q.type = val!),
                        ),
                        // TODO: render options / matching pairs same as before
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitQuiz,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Quiz'),
              ),
            ],
          ),
        ),
      );
    }
  }
