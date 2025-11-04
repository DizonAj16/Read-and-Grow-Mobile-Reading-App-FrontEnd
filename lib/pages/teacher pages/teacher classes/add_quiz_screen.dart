import 'dart:io';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/quiz_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../api/supabase_api_service.dart';
import '../../../../models/quiz_questions.dart';

class AddQuizScreen extends StatefulWidget {
  final String? lessonId;
  final Map<String, dynamic>? classDetails;

  const AddQuizScreen({
    super.key,
    this.lessonId,
    this.classDetails,
  });

  @override
  State<AddQuizScreen> createState() => _AddQuizScreenState();
}

class _AddQuizScreenState extends State<AddQuizScreen> {
  final _quizTitleController = TextEditingController();
  List<QuizQuestion> _questions = [];
  bool _isLoading = false;
  String? _selectedLessonId;

  @override
  void initState() {
    super.initState();
    _selectedLessonId = widget.lessonId;
  }

  void _addQuestion() {
    final defaultOptions = List.generate(4, (i) => 'Option ${i + 1}');
    _questions.add(
      QuizQuestion(
        questionText: '',
        type: QuestionType.multipleChoice,
        options: defaultOptions,
        matchingPairs: [],
      ),
    );
    setState(() {});
  }

  void _addOption(QuizQuestion question) {
    final newIndex = (question.options?.length ?? 0) + 1;
    question.options?.add('Option $newIndex');
    setState(() {});
  }

  void _addMatchingPair(QuizQuestion question) {
    question.matchingPairs ??= [];
    question.matchingPairs!.add(
      MatchingPair(leftItem: '', rightItemUrl: ''),
    );
    setState(() {});
  }

  Future<void> _submitQuiz() async {
    final lessonId = _selectedLessonId;
    if (lessonId == null ||
        _quizTitleController.text.isEmpty ||
        _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a lesson and add questions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final quiz = await ApiService.addQuiz(
      taskId: lessonId,
      title: _quizTitleController.text,
      questions: _questions,
    );

    setState(() => _isLoading = false);

    if (quiz != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz added successfully!')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPreviewScreen(
            questions: _questions,
            title: _quizTitleController.text,
            isPreview: true,
            classDetails: widget.classDetails,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add quiz')),
      );
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
            if (widget.lessonId == null)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: ApiService.getLessons(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No lessons found. Please add a lesson first.');
                  }

                  final lessons = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    value: _selectedLessonId,
                    hint: const Text("Select Lesson"),
                    items: lessons.map((lesson) {
                      return DropdownMenuItem<String>(
                        value: lesson['id'].toString(),
                        child: Text(lesson['title']?.toString() ?? 'Untitled Lesson'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedLessonId = val),
                  );
                },
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _quizTitleController,
              decoration: const InputDecoration(labelText: 'Quiz Title'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addQuestion,
              child: const Text('Add Question'),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final q = _questions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          decoration: InputDecoration(labelText: 'Question ${index + 1}'),
                          onChanged: (val) => q.questionText = val,
                        ),
                        DropdownButton<QuestionType>(
                          value: q.type,
                          items: QuestionType.values
                              .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.name),
                          ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              q.type = val!;
                              // Initialize options based on question type
                              if (q.type == QuestionType.dragAndDrop && (q.options == null || q.options!.isEmpty)) {
                                q.options = List.generate(3, (i) => 'Item ${i + 1}');
                              } else if (q.type == QuestionType.trueFalse) {
                                q.options = ['True', 'False'];
                              } else if (q.type == QuestionType.multipleChoice && (q.options == null || q.options!.isEmpty)) {
                                q.options = List.generate(4, (i) => 'Option ${i + 1}');
                              }
                              // Clear correct answer when type changes
                              q.correctAnswer = null;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        if (q.type == QuestionType.multipleChoice)
                          Column(
                            children: [
                              ...List.generate(q.options!.length, (i) {
                                final optionValue = q.options![i];
                                return Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                                        controller: TextEditingController(text: optionValue),
                                        onChanged: (val) => q.options![i] = val,
                                      ),
                                    ),
                                    Radio<String>(
                                      value: optionValue,
                                      groupValue: q.correctAnswer,
                                      onChanged: (val) {
                                        setState(() {
                                          q.correctAnswer = val;
                                        });
                                      },
                                    ),
                                  ],
                                );
                              }),
                              TextButton(
                                onPressed: () => _addOption(q),
                                child: const Text('Add Option'),
                              ),
                            ],
                          ),
                        if (q.type == QuestionType.dragAndDrop)
                          ReorderableListView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex -= 1;
                                final item = q.options?.removeAt(oldIndex);
                                if (item != null)
                                  q.options?.insert(newIndex, item);
                              });
                            },
                            children: [
                              for (int i = 0; i < q.options!.length; i++)
                                ListTile(
                                  key: ValueKey('${q.options![i]}_$i'),
                                  title: TextField(
                                    decoration:
                                    InputDecoration(labelText: 'Item ${i + 1}'),
                                    controller: TextEditingController(text: q.options?[i]),
                                    onChanged: (val) => q.options?[i] = val,
                                  ),
                                  trailing: const Icon(Icons.drag_handle),
                                ),
                            ],
                          ),
                        if (q.type == QuestionType.fillInTheBlank)
                          TextField(
                            decoration: const InputDecoration(labelText: 'Correct Answer'),
                            onChanged: (val) => q.correctAnswer = val,
                          ),
                        if (q.type == QuestionType.trueFalse)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select the correct answer:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              RadioListTile<String>(
                                title: const Text('True'),
                                value: 'True',
                                groupValue: q.correctAnswer,
                                onChanged: (val) {
                                  setState(() {
                                    q.correctAnswer = val;
                                  });
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text('False'),
                                value: 'False',
                                groupValue: q.correctAnswer,
                                onChanged: (val) {
                                  setState(() {
                                    q.correctAnswer = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        if (q.type == QuestionType.matching)
                          Column(
                            children: [
                              ...List.generate(q.matchingPairs?.length ?? 0, (i) {
                                final pair = q.matchingPairs![i];
                                return Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                            labelText: 'Left Item (Text)'),
                                        controller: TextEditingController(
                                            text: pair.leftItem),
                                        onChanged: (val) => pair.leftItem = val,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          final picker = ImagePicker();
                                          final pickedFile =
                                          await picker.pickImage(
                                            source: ImageSource.gallery,
                                            imageQuality: 80,
                                          );
                                          if (pickedFile != null) {
                                            File file = File(pickedFile.path);
                                            String? uploadedUrl =
                                            await ApiService.uploadFile(file);
                                            if (uploadedUrl != null) {
                                              setState(() => pair.rightItemUrl = uploadedUrl);
                                            }
                                          }
                                        },
                                        child: Container(
                                          height: 60,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius:
                                            BorderRadius.circular(8),
                                          ),
                                          child: (pair.rightItemUrl ?? '').isEmpty
                                              ? const Center(
                                              child: Text('Tap to pick image'))
                                              : Image.network(
                                              pair.rightItemUrl!,
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        q.matchingPairs!.removeAt(i);
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                );
                              }),
                              TextButton(
                                onPressed: () => _addMatchingPair(q),
                                child: const Text('Add Matching Pair'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitQuiz,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}