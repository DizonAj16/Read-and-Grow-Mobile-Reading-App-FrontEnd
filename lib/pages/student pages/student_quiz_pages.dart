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
      // Check if quiz has already been submitted (up to 3 attempts allowed)
      // widget.assignmentId is already the assignment ID from assignments table
      final existingSubmissionRes = await supabase
          .from('student_submissions')
          .select('id, score, max_score, attempt_number')
          .eq('assignment_id', widget.assignmentId)
          .eq('student_id', widget.studentId)
          .order('submitted_at', ascending: false);

      final attemptCount = existingSubmissionRes.length;
      final maxAttempts = 3;

      if (attemptCount >= maxAttempts) {
        final existingSubmission = existingSubmissionRes.first;
        // Quiz already taken maximum times, show message and go back
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Quiz Already Completed'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'You have already completed this quiz $maxAttempts times. Maximum attempts reached.',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Your Score',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${existingSubmission['score']} / ${existingSubmission['max_score']}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back
                    },
                    child: const Text('OK'),
                  ),
                ],
            ),
          );
        }
        return;
      }

      final quizRes = await supabase
          .from('quizzes')
          .select('title')
          .eq('id', widget.quizId)
          .maybeSingle();

      if (quizRes == null) return;

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
        
        // For drag-and-drop, ensure options are loaded and sorted by sort_order
        QuizQuestion question = QuizQuestion.fromMap(q).copyWith(matchingPairs: pairs);
        if (question.type == QuestionType.dragAndDrop && q['question_options'] != null) {
          // Sort by sort_order if available, otherwise keep original order
          final sortedOptions = <Map<String, dynamic>>[];
          for (var opt in q['question_options']) {
            sortedOptions.add(opt);
          }
          sortedOptions.sort((a, b) {
            final orderA = a['sort_order'] as int? ?? 0;
            final orderB = b['sort_order'] as int? ?? 0;
            return orderA.compareTo(orderB);
          });
          final optionTexts = sortedOptions
              .map((opt) => opt['option_text'] as String)
              .toList();
          question = question.copyWith(options: optionTexts);
          // Store correct order as JSON string in userAnswer for later comparison
          question.userAnswer = ''; // Will be set when student reorders
        }
        
        return question;
      }).toList();

      // Get task_id from assignment to pass to QuizHelper
      final assignmentRes = await supabase
          .from('assignments')
          .select('task_id')
          .eq('id', widget.assignmentId)
          .maybeSingle();
      
      final taskId = assignmentRes?['task_id'] as String? ?? widget.assignmentId;

      // Determine current attempt number
      final attemptRes = await supabase
          .from('student_submissions')
          .select('attempt_number')
          .eq('assignment_id', widget.assignmentId)
          .eq('student_id', widget.studentId)
          .order('submitted_at', ascending: false)
          .limit(1);
      
      final currentAttempt = attemptRes.isNotEmpty 
          ? (attemptRes.first['attempt_number'] as int? ?? 0) + 1
          : 1;

      quizHelper = QuizHelper(
        studentId: widget.studentId,
        taskId: taskId,
        questions: questions,
        supabase: supabase,
      );
      quizHelper!.currentAttempt = currentAttempt;

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

    // Check attempt count (allow up to 3 attempts)
    final existingSubmissionRes = await supabase
        .from('student_submissions')
        .select('id, attempt_number')
        .eq('assignment_id', widget.assignmentId)
        .eq('student_id', widget.studentId);

    final attemptCount = existingSubmissionRes.length;
    final maxAttempts = 3;
    final nextAttemptNumber = attemptCount + 1;

    if (attemptCount >= maxAttempts) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have already completed this quiz $maxAttempts times. Maximum attempts reached.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    // Get student
    final studentRes = await supabase
        .from('students')
        .select('id')
        .eq('id', widget.studentId)
        .maybeSingle();

    if (studentRes == null) {
      debugPrint("No student found for id ${widget.studentId}");
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
          // Get correct order from database (sorted by sort_order)
          final optionsRes = await supabase
              .from('question_options')
              .select('option_text, sort_order')
              .eq('question_id', q.id as Object)
              .order('sort_order', ascending: true);
          
          final correctOrder = (optionsRes as List)
              .map((opt) => opt['option_text'] as String)
              .toList();
          
          // Compare student's current order (q.options) with correct order
          if (q.options != null && q.options!.length == correctOrder.length) {
            isCorrect = q.options!.asMap().entries.every((entry) {
              return entry.value == correctOrder[entry.key];
            });
          } else {
            isCorrect = false;
          }
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

    // Insert submission with attempt number
    await supabase.from('student_submissions').insert({
      'assignment_id': widget.assignmentId,
      'student_id': widget.studentId,
      'attempt_number': nextAttemptNumber,
      'score': correct,
      'max_score': quizHelper!.questions.length,
      'quiz_answers': activityDetails,
      'audio_file_path': audioFileUrl,
      'submitted_at': DateTime.now().toIso8601String(),
    });

    quizHelper!.currentAttempt++;

    if (!mounted) return;

    // Show review dialog with correct answers
    _showQuizReviewDialog(correct, quizHelper!.questions.length);
  }

  /// Show dialog with quiz results and correct answers for review
  Future<void> _showQuizReviewDialog(int score, int totalQuestions) async {
    if (quizHelper == null) return;
    
    final supabase = quizHelper!.supabase;
    
    // Build list of question reviews with correct answers
    final List<Map<String, dynamic>> questionReviews = [];
    
    for (int i = 0; i < quizHelper!.questions.length; i++) {
      final q = quizHelper!.questions[i];
      String correctAnswerText = '';
      String studentAnswerText = q.userAnswer.isEmpty ? '(No answer)' : q.userAnswer;
      bool isCorrect = false;

      // Get correct answer based on question type
      switch (q.type) {
        case QuestionType.multipleChoice:
        case QuestionType.fillInTheBlank:
          // Fetch correct option from database
          final optionsRes = await supabase
              .from('question_options')
              .select('option_text, is_correct')
              .eq('question_id', q.id as Object);
          
          final correctOption = optionsRes.firstWhere(
            (o) => o['is_correct'] == true,
            orElse: () => {'option_text': 'N/A'},
          );
          correctAnswerText = correctOption['option_text'] ?? 'N/A';
          isCorrect = q.userAnswer.trim().toLowerCase() == correctAnswerText.trim().toLowerCase();
          break;

        case QuestionType.matching:
          if (q.matchingPairs != null) {
            final correctPairs = q.matchingPairs!
                .map((p) => '${p.leftItem} → ${p.leftItem}')
                .join(', ');
            final userPairs = q.matchingPairs!
                .map((p) => '${p.leftItem} → ${p.userSelected.isEmpty ? "(No match)" : p.userSelected}')
                .join(', ');
            correctAnswerText = correctPairs;
            studentAnswerText = userPairs;
            isCorrect = q.matchingPairs!.every((p) => p.userSelected == p.leftItem);
          }
          break;

        case QuestionType.trueFalse:
          // Fetch correct option from database
          final optionsRes = await supabase
              .from('question_options')
              .select('option_text, is_correct')
              .eq('question_id', q.id as Object);
          
          final correctOption = optionsRes.firstWhere(
            (o) => o['is_correct'] == true,
            orElse: () => {'option_text': q.correctAnswer ?? 'N/A'},
          );
          correctAnswerText = correctOption['option_text'] ?? q.correctAnswer ?? 'N/A';
          isCorrect = q.userAnswer.trim().toLowerCase() == correctAnswerText.trim().toLowerCase();
          break;

        case QuestionType.dragAndDrop:
          // Get correct order from database
          final optionsRes = await supabase
              .from('question_options')
              .select('option_text, sort_order')
              .eq('question_id', q.id as Object)
              .order('sort_order', ascending: true);
          
          final correctOrder = (optionsRes as List)
              .map((opt) => opt['option_text'] as String)
              .toList();
          
          correctAnswerText = correctOrder.join(' → ');
          studentAnswerText = q.options?.join(' → ') ?? '(No answer)';
          
          // Compare student's current order with correct order
          if (q.options != null && q.options!.length == correctOrder.length) {
            isCorrect = q.options!.asMap().entries.every((entry) {
              return entry.value == correctOrder[entry.key];
            });
          } else {
            isCorrect = false;
          }
          break;

        case QuestionType.audio:
          correctAnswerText = 'Audio recording submitted';
          studentAnswerText = q.userAnswer.isNotEmpty ? 'Audio recorded' : '(No recording)';
          isCorrect = q.userAnswer.isNotEmpty;
          break;
      }

      questionReviews.add({
        'questionNumber': i + 1,
        'questionText': q.questionText,
        'studentAnswer': studentAnswerText,
        'correctAnswer': correctAnswerText,
        'isCorrect': isCorrect,
      });
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.quiz, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Quiz Review",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Score: $score / $totalQuestions",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Scrollable content with questions and answers
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  itemCount: questionReviews.length,
                  itemBuilder: (context, index) {
                    final review = questionReviews[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: review['isCorrect'] 
                          ? Colors.green.shade50 
                          : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question number and text
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: review['isCorrect']
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "Q${review['questionNumber']}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  review['isCorrect']
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: review['isCorrect']
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              review['questionText'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Student's answer
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Your Answer: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    review['studentAnswer'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      fontStyle: review['studentAnswer'] == '(No answer)' 
                                          ? FontStyle.italic 
                                          : FontStyle.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Correct answer
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Correct Answer: ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    review['correctAnswer'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // OK Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

      case QuestionType.trueFalse:
        // For true/false, always show True and False options
        return Column(
          children: ['True', 'False'].map((option) {
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
        // Ensure matching pairs exist
        if (question.matchingPairs == null || question.matchingPairs!.isEmpty) {
          return const Text("No matching pairs available for this question.");
        }
        
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
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pair.leftItem,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pair.leftItem,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[300]!),
                    ),
                    child: Text(
                      pair.leftItem,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // Target drop zones
            Column(
              children: question.matchingPairs!.asMap().entries.map((entry) {
                final pair = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pair.userSelected.isEmpty
                        ? Colors.green[50]
                        : Colors.green[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pair.userSelected.isEmpty
                          ? Colors.green[300]!
                          : Colors.green,
                      width: 2,
                    ),
                  ),
                  child: DragTarget<String>(
                    onAccept: (received) {
                      setState(() {
                        pair.userSelected = received;
                      });
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Row(
                        children: [
                          if (pair.rightItemUrl != null &&
                              pair.rightItemUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                pair.rightItemUrl!,
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 80,
                                  width: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image, size: 40),
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 80,
                                    width: 80,
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              pair.userSelected.isEmpty
                                  ? 'Drop text here'
                                  : pair.userSelected,
                              style: TextStyle(
                                color: pair.userSelected.isEmpty
                                    ? Colors.grey[600]
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (pair.userSelected.isNotEmpty)
                            const Icon(Icons.check_circle, color: Colors.green),
                        ],
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ],
        );

      case QuestionType.dragAndDrop:
        // For drag and drop, ensure options list exists
        if (question.options == null || question.options!.isEmpty) {
          return const Text("No options available for this question.");
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Drag items to reorder them:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = question.options!.removeAt(oldIndex);
                  question.options!.insert(newIndex, item);
                  // Store the reordered list as user answer
                  question.userAnswer = question.options!.join(',');
                });
              },
              children: [
                for (int i = 0; i < question.options!.length; i++)
                  Card(
                    key: ValueKey('${question.options![i]}-$i'),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(question.options![i]),
                      trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                    ),
                  )
              ],
            ),
          ],
        );
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
