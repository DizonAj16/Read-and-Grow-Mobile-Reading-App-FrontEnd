import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../api/supabase_api_service.dart';
import '../../../../models/quiz_questions.dart';

class AddQuizScreen extends StatefulWidget {
  final String? lessonId;
  final Map<String, dynamic>? classDetails;
  final String? quizId; // For editing mode
  final Map<String, dynamic>? initialQuizData; // For editing mode

  const AddQuizScreen({
    super.key,
    this.lessonId,
    this.classDetails,
    this.quizId,
    this.initialQuizData,
  });

  @override
  State<AddQuizScreen> createState() => _AddQuizScreenState();
}

class _AddQuizScreenState extends State<AddQuizScreen> {
  final _quizTitleController = TextEditingController();
  List<QuizQuestion> _questions = [];
  bool _isLoading = false;
  bool _isLoadingData = false;
  String? _selectedLessonId;

  bool get _isEditMode => widget.quizId != null;

  @override
  void initState() {
    super.initState();
    _selectedLessonId = widget.lessonId;
    if (_isEditMode && widget.initialQuizData != null) {
      _loadQuizData();
    }
  }

  Future<void> _loadQuizData() async {
    if (widget.initialQuizData == null) return;

    setState(() => _isLoadingData = true);

    try {
      final quiz = widget.initialQuizData!['quiz'] as Map<String, dynamic>?;
      final questions = widget.initialQuizData!['questions'] as List<dynamic>?;

      if (quiz != null) {
        _quizTitleController.text = quiz['title']?.toString() ?? '';
      }

      if (questions != null && questions.isNotEmpty) {
        _questions = questions.map<QuizQuestion>((q) {
          // Convert database question to QuizQuestion
          final questionType = _parseQuestionType(q['question_type']?.toString() ?? '');
          List<String>? options;
          String? correctAnswer;
          List<MatchingPair>? matchingPairs;

          // Handle options for multiple choice, true/false, drag and drop
          if (q['question_options'] != null && q['question_options'] is List) {
            final opts = q['question_options'] as List;
            if (questionType == QuestionType.dragAndDrop) {
              // For drag and drop, sort by sort_order
              opts.sort((a, b) {
                final orderA = a['sort_order'] as int? ?? 0;
                final orderB = b['sort_order'] as int? ?? 0;
                return orderA.compareTo(orderB);
              });
              options = opts.map<String>((opt) => opt['option_text']?.toString() ?? '').toList();
            } else {
              options = opts.map<String>((opt) => opt['option_text']?.toString() ?? '').toList();
              // Find correct answer
              for (var opt in opts) {
                if (opt['is_correct'] == true) {
                  correctAnswer = opt['option_text']?.toString();
                  break;
                }
              }
            }
          }

          // Handle fill in the blank
          if (questionType == QuestionType.fillInTheBlank && q['question_options'] != null) {
            final opts = q['question_options'] as List;
            for (var opt in opts) {
              if (opt['is_correct'] == true) {
                correctAnswer = opt['option_text']?.toString();
                break;
              }
            }
          }

          // Handle matching pairs
          if (questionType == QuestionType.matching && q['matching_pairs'] != null) {
            matchingPairs = (q['matching_pairs'] as List)
                .map((p) => MatchingPair.fromMap(p))
                .toList();
          }

          return QuizQuestion(
            id: q['id']?.toString(),
            questionText: q['question_text']?.toString() ?? '',
            type: questionType,
            options: options,
            correctAnswer: correctAnswer,
            matchingPairs: matchingPairs,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Error loading quiz data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  QuestionType _parseQuestionType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'multiple_choice':
        return QuestionType.multipleChoice;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'fill_in_the_blank':
        return QuestionType.fillInTheBlank;
      case 'drag_and_drop':
        return QuestionType.dragAndDrop;
      case 'matching':
        return QuestionType.matching;
      case 'audio':
        return QuestionType.audio;
      default:
        return QuestionType.multipleChoice;
    }
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
    if (_quizTitleController.text.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode 
              ? 'Please add questions' 
              : 'Please select a lesson and add questions'),
        ),
      );
      return;
    }

    if (!_isEditMode && _selectedLessonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a lesson')),
      );
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      bool success;
      if (_isEditMode) {
        // Update existing quiz
        success = await ApiService.updateQuiz(
          quizId: widget.quizId!,
          title: _quizTitleController.text,
          questions: _questions,
        );
      } else {
        // Create new quiz
        final quiz = await ApiService.addQuiz(
          taskId: _selectedLessonId!,
          title: _quizTitleController.text,
          questions: _questions,
        );
        success = quiz != null;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode 
                  ? 'Quiz updated successfully!' 
                  : 'Quiz added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Return true to indicate success
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditMode 
                  ? 'Failed to update quiz' 
                  : 'Failed to add quiz'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditMode ? 'Edit Quiz' : 'Add Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Quiz' : 'Add Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (!_isEditMode && widget.lessonId == null)
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
                  : Text(_isEditMode ? 'Update Quiz' : 'Save Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}