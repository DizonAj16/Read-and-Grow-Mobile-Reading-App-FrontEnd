import 'dart:async';
import 'dart:io';
import 'package:deped_reading_app_laravel/widgets/audio_recorder_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deped_reading_app_laravel/helper/QuizHelper.dart';
import '../../../models/quiz_questions.dart';

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
      final quizRes = await supabase
          .from('quizzes')
          .select('title')
          .eq('id', widget.quizId)
          .single();

      if (quizRes == null || quizRes.isEmpty) return;

      quizTitle = quizRes['title'] ?? "Quiz";
      final qRes = await supabase
          .from('quiz_questions')
          .select(
          '*, question_options(*), matching_pairs!matching_pairs_question_id_fkey(*)')
          .eq('quiz_id', widget.quizId)
          .order('sort_order', ascending: true);

      questions = qRes.map<QuizQuestion>((q) {
        List<MatchingPair> pairs = [];
        if (q['matching_pairs'] != null) {
          pairs = (q['matching_pairs'] as List)
              .map((p) => MatchingPair.fromMap(p))
              .toList();
        }
        return QuizQuestion.fromMap(q).copyWith(matchingPairs: pairs);
      }).toList();

      quizHelper = QuizHelper(
        studentId: widget.studentId,
        taskId: widget.assignmentId,
        questions: questions,
        supabase: supabase,
      );

      quizHelper!.startTimerFromDatabase(
            () => _submitQuiz(auto: true),
            () => setState(() {}),
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

    // Get assignment
    final assignmentRes = await supabase
        .from('assignments')
        .select('id')
        .eq('task_id', quizHelper!.taskId)
        .single();

    if (assignmentRes == null) {
      print("No assignment found for task_id ${quizHelper!.taskId}");
      return;
    }
    final assignmentId = assignmentRes['id'];

    // Get student
    final studentRes = await supabase
        .from('students')
        .select('id')
        .eq('user_id', widget.studentId)
        .single();

    if (studentRes == null) {
      print("No student found for user_id ${widget.studentId}");
      return;
    }
    final studentId = studentRes['id'];

    // Prepare scores
    int correct = 0;
    int wrong = 0;
    final List<Map<String, dynamic>> activityDetails = [];

    // Prepare a variable for audio upload
    String? audioFileUrl;

    for (var q in quizHelper!.questions) {
      bool isCorrect = false;

      switch (q.type) {
        case QuestionType.multipleChoice:
        case QuestionType.fillInTheBlank:
          final optionsRes = await supabase
              .from('question_options')
              .select('question_id, option_text, is_correct')
              .filter('question_id', 'in', '(${q.id})');
          final opts = optionsRes as List? ?? [];

          if (opts.isNotEmpty) {
            final correctOption = opts.firstWhere(
                  (o) => o['is_correct'] == true,
              orElse: () => opts.first as Map<String, dynamic>,
            );
            isCorrect =
                q.userAnswer.trim() == correctOption['option_text'].trim();
          }
          break;

        case QuestionType.matching:
          isCorrect = q.matchingPairs!.every((p) => p.userSelected == p.leftItem);
          break;

        case QuestionType.dragAndDrop:
          isCorrect =
              q.options!.asMap().entries.every((e) => e.key == e.value);
          break;

        case QuestionType.audio:
        // Upload happens here
          if (q.userAnswer.isNotEmpty && File(q.userAnswer).existsSync()) {
            final localFile = File(q.userAnswer);
            final fileName =
                '${widget.studentId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
            final storagePath = 'student_voice/$fileName';

            final fileBytes = await localFile.readAsBytes();
            await supabase.storage.from('student_voice').uploadBinary(
              storagePath,
              fileBytes,
              fileOptions: const FileOptions(contentType: 'audio/m4a'),
            );

            audioFileUrl =
                supabase.storage.from('student_voice').getPublicUrl(storagePath);
            isCorrect = true;

            await supabase.from('student_recordings').insert({
              'student_id': widget.studentId,
              'quiz_question_id': q.id,
              'file_url': audioFileUrl,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
          break;

        default:
          isCorrect = false;
      }

      if (isCorrect)
        correct++;
      else
        wrong++;

      activityDetails.add(q.toMap());
    }

    quizHelper!.score = correct;

    // Update progress
    final progressUpdate = {
      'student_id': studentId,
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

    // Insert submission
    await supabase.from('student_submissions').insert({
      'assignment_id': assignmentId,
      'student_id': widget.studentId,
      'attempt_number': quizHelper!.currentAttempt,
      'score': correct,
      'max_score': quizHelper!.questions.length,
      'quiz_answers': activityDetails,
      'audio_file_path': audioFileUrl,
      'submitted_at': DateTime.now().toIso8601String(),
    });

    quizHelper!.currentAttempt++;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(auto ? "Time's Up!" : "Quiz Submitted"),
        content: Text("Your score: $correct / ${quizHelper!.questions.length}"),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
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

  Widget _buildQuestionWidget(QuizQuestion question) {
    switch (question.type) {
      case QuestionType.audio:
        return AudioRecorderWidget(
          studentId: widget.studentId,
          quizQuestionId: question.id!,
          onRecordComplete: (filePath) {
            setState(() {
              question.userAnswer = filePath; // store local path for upload later
            });
          },
        );

      case QuestionType.multipleChoice:
        return Column(
          children: question.options!.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: question.userAnswer,
              onChanged: (value) {
                setState(() {
                  question.userAnswer = value!;
                });
              },
            );
          }).toList(),
        );

      case QuestionType.fillInTheBlank:
        return TextField(
          decoration: const InputDecoration(labelText: "Type your answer"),
          onChanged: (value) {
            question.userAnswer = value;
          },
        );

      case QuestionType.matching:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Match the items by dragging the text to the correct image:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: question.matchingPairs!.map((pair) {
                return Draggable<String>(
                  data: pair.leftItem,
                  feedback: Material(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.blue,
                      child: Text(
                        pair.leftItem,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey[300],
                    child: Text(pair.leftItem),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue[100],
                    child: Text(pair.leftItem),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Column(
              children: question.matchingPairs!.map((pair) {
                return DragTarget<String>(
                  onAccept: (received) {
                    setState(() {
                      pair.userSelected = received;
                    });
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      color: Colors.green[100],
                      child: Row(
                        children: [
                          if (pair.rightItemUrl != null &&
                              pair.rightItemUrl!.isNotEmpty)
                            Image.network(
                              pair.rightItemUrl!,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              pair.userSelected!.isEmpty
                                  ? 'Drop text here'
                                  : pair.userSelected!,
                              style: TextStyle(
                                color: pair.userSelected!.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        );

      case QuestionType.dragAndDrop:
        return ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = question.options!.removeAt(oldIndex);
              question.options!.insert(newIndex, item);
            });
          },
          children: [
            for (int i = 0; i < question.options!.length; i++)
              ListTile(
                key: ValueKey('${question.options![i]}-$i'),
                title: Text(question.options![i]),
                trailing: const Icon(Icons.drag_handle),
              )
          ],
        );

      default:
        return const Text("Unknown question type.");
    }
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
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Q${index + 1}: ${question.questionText}"),
                    const SizedBox(height: 10),
                    _buildQuestionWidget(question),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _submitQuiz,
        label: const Text("Submit Quiz"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
