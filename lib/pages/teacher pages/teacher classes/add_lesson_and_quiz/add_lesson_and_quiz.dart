import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../api/supabase_api_service.dart';
import '../../../../models/quiz_questions.dart';
import '../../quiz_preview_screen.dart';

class AddLessonWithQuizScreen extends StatefulWidget {
  final String? readingLevelId; // The lesson's reading level
  final Map<String, dynamic> classDetails; // ✅ added classDetails

  const AddLessonWithQuizScreen({
    super.key,
    this.readingLevelId,
    required this.classDetails, // ✅ require it
  });

  @override
  State<AddLessonWithQuizScreen> createState() => _AddLessonWithQuizScreenState();
}

class _AddLessonWithQuizScreenState extends State<AddLessonWithQuizScreen> {
  // Lesson controllers
  final _lessonTitleController = TextEditingController();
  final _lessonDescController = TextEditingController();
  final _lessonTimeController = TextEditingController();
  bool _unlocksNextLevel = false;

  // Quiz controllers
  final _quizTitleController = TextEditingController();
  List<QuizQuestion> _questions = [];

  bool _isLoading = false;

  void _addQuestion() {
    final defaultOptions = List.generate(4, (i) => 'Option ${i + 1}');
    final newQuestion = QuizQuestion(
      questionText: '',
      type: QuestionType.multipleChoice,
      options: defaultOptions,
      matchingPairs: [],
    );
    
    // Initialize options for drag and drop
    if (newQuestion.type == QuestionType.dragAndDrop) {
      newQuestion.options = defaultOptions;
    }
    
    // Initialize options for true/false
    if (newQuestion.type == QuestionType.trueFalse) {
      newQuestion.options = ['True', 'False'];
    }
    
    _questions.add(newQuestion);
    setState(() {});
  }

  void _addOption(QuizQuestion question) {
    question.options?.add('');
    setState(() {});
  }

  void _addMatchingPair(QuizQuestion question) {
    question.matchingPairs ??= [];
    question.matchingPairs!.add(MatchingPair(leftItem: '', rightItemUrl: ''));
    setState(() {});
  }

  Future<void> _submitLessonAndQuiz() async {
    if (_lessonTitleController.text.isEmpty || _quizTitleController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Determine if there is an audio quiz
      final hasAudioQuiz = _questions.any((q) => q.type == QuestionType.audio);

      // 2️⃣ Only require reading level if there’s an audio quiz
      final readingLevelId = widget.readingLevelId ?? widget.classDetails['reading_level_id'];
      if (hasAudioQuiz && readingLevelId == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio quiz requires a reading level')),
        );
        return;
      }

      // 3️⃣ Add lesson
      final lesson = await ApiService.addLesson(
        readingLevelId: hasAudioQuiz ? readingLevelId : null,
        title: _lessonTitleController.text,
        description: _lessonDescController.text,
        timeLimitMinutes: int.tryParse(_lessonTimeController.text),
        unlocksNextLevel: _unlocksNextLevel,
      );

      if (lesson == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add lesson')),
        );
        return;
      }

      // 4️⃣ Get teacher_id (from classDetails or current user)
      String? teacherId = widget.classDetails['teacher_id'];
      if (teacherId == null) {
        // Fetch teacher ID of the logged-in user
        final teacherData = await Supabase.instance.client
            .from('teachers')
            .select('id')
            .eq('id', Supabase.instance.client.auth.currentUser!.id)
            .maybeSingle();
        teacherId = teacherData?['id'];
        if (teacherId == null) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to find teacher ID')),
          );
          return;
        }
      }

      // 5️⃣ Assign lesson to class with teacher_id
      await Supabase.instance.client.from('assignments').insert({
        'class_room_id': widget.classDetails['id'],
        'task_id': lesson['id'],
        'teacher_id': teacherId, // ✅ now required
      });

      // 6️⃣ Add quiz
      final quiz = await ApiService.addQuiz(
        taskId: lesson['id'],
        title: _quizTitleController.text,
        questions: _questions,
      );

      setState(() => _isLoading = false);

      if (quiz != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson & Quiz added!')),
        );

        // Navigate to QuizPreviewScreen
        Navigator.pushReplacement(
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
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Lesson & Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Lesson Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _lessonTitleController,
              decoration: const InputDecoration(labelText: 'Lesson Title'),
            ),
            TextField(
              controller: _lessonDescController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _lessonTimeController,
              decoration: const InputDecoration(labelText: 'Time Limit (minutes)'),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              title: const Text('Unlocks Next Level'),
              value: _unlocksNextLevel,
              onChanged: (val) => setState(() => _unlocksNextLevel = val),
            ),
            const SizedBox(height: 20),
            const Text('Quiz Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _quizTitleController,
              decoration: const InputDecoration(labelText: 'Quiz Title'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _addQuestion, child: const Text('Add Question')),
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
              onPressed: _isLoading ? null : _submitLessonAndQuiz,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save Lesson & Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
