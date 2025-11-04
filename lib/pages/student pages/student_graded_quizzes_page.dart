import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/database_helpers.dart';
import '../../models/quiz_questions.dart';

class StudentGradedQuizzesPage extends StatefulWidget {
  final String studentId;
  const StudentGradedQuizzesPage({super.key, required this.studentId});

  @override
  State<StudentGradedQuizzesPage> createState() => _StudentGradedQuizzesPageState();
}

class _StudentGradedQuizzesPageState extends State<StudentGradedQuizzesPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> gradedQuizzes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadGradedQuizzes();
  }

  Future<void> _loadGradedQuizzes() async {
    setState(() => loading = true);

    try {
      List<Map<String, dynamic>> gradedList = [];

      // 1. Fetch all quiz submissions that have been graded (have a score)
      final submissions = await supabase
          .from('student_submissions')
          .select('''
            id,
            assignment_id,
            score,
            max_score,
            submitted_at,
            quiz_answers,
            attempt_number,
            assignments!inner(
              id,
              class_room:class_rooms(class_name),
              task:tasks(
                id,
                title,
                quizzes(
                  id,
                  title
                )
              )
            )
          ''')
          .eq('student_id', widget.studentId)
          .not('score', 'is', null)
          .order('submitted_at', ascending: false);

      for (var submission in submissions) {
        final assignment = submission['assignments'] as Map<String, dynamic>?;
        if (assignment == null) continue;

        final task = assignment['task'] as Map<String, dynamic>?;
        if (task == null) continue;

        final quizzes = task['quizzes'] as List<dynamic>?;
        if (quizzes == null || quizzes.isEmpty) continue;

        final quiz = quizzes.first as Map<String, dynamic>;
        final classRoom = assignment['class_room'] as Map<String, dynamic>?;

        gradedList.add({
          'type': 'quiz',
          'submission_id': submission['id'],
          'assignment_id': submission['assignment_id'],
          'quiz_id': quiz['id'],
          'quiz_title': quiz['title'],
          'task_title': task['title'],
          'class_name': classRoom?['class_name'] ?? 'Unknown Class',
          'score': submission['score'],
          'max_score': submission['max_score'],
          'submitted_at': submission['submitted_at'],
          'quiz_answers': submission['quiz_answers'],
          'attempt_number': submission['attempt_number'] ?? 1,
        });
      }

      // 2. Fetch all reading recordings that have been graded (have a score)
      final recordings = await supabase
          .from('student_recordings')
          .select('''
            id,
            task_id,
            score,
            teacher_comments,
            graded_at,
            recorded_at,
            file_url,
            tasks(
              id,
              title,
              reading_level:reading_levels(
                id,
                title
              )
            )
          ''')
          .eq('student_id', widget.studentId)
          .not('score', 'is', null)
          .eq('needs_grading', false)
          .order('graded_at', ascending: false);

      for (var recording in recordings) {
        final task = recording['tasks'] as Map<String, dynamic>?;
        if (task == null) continue;

        final readingLevel = task['reading_level'] as Map<String, dynamic>?;
        
        // Try to extract material_id from teacher_comments if it's a reading material
        final teacherComments = recording['teacher_comments'] as String? ?? '';
        String? materialId;
        if (teacherComments.contains('material_id')) {
          try {
            final jsonMatch = RegExp(r'"material_id":\s*"([^"]+)"').firstMatch(teacherComments);
            if (jsonMatch != null) {
              materialId = jsonMatch.group(1);
            }
          } catch (e) {
            debugPrint('Error parsing material_id: $e');
          }
        }

        // Get material title if it's a reading material
        String title = task['title'] as String? ?? 'Reading Task';
        if (materialId != null) {
          try {
            final materialRes = await supabase
                .from('reading_materials')
                .select('title')
                .eq('id', materialId)
                .maybeSingle();
            if (materialRes != null) {
              title = materialRes['title'] as String? ?? title;
            }
          } catch (e) {
            debugPrint('Error fetching material title: $e');
          }
        }

        gradedList.add({
          'type': 'reading',
          'recording_id': recording['id'],
          'task_id': recording['task_id'],
          'material_id': materialId,
          'title': title,
          'reading_level': readingLevel?['title'] as String? ?? 'Unknown Level',
          'score': recording['score'],
          'max_score': 10.0, // Reading recordings are typically out of 10
          'submitted_at': recording['graded_at'] ?? recording['recorded_at'],
          'teacher_comments': teacherComments,
        });
      }

      // Sort by submitted/graded date (most recent first)
      gradedList.sort((a, b) {
        final dateA = DateTime.tryParse(a['submitted_at'] as String? ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['submitted_at'] as String? ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      setState(() {
        gradedQuizzes = gradedList;
        loading = false;
      });
    } catch (e) {
      debugPrint('Error loading graded quizzes: $e');
      setState(() => loading = false);
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  double _calculatePercentage(int score, int maxScore) {
    if (maxScore == 0) return 0.0;
    return (score / maxScore) * 100;
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildQuizCard(Map<String, dynamic> item) {
    final type = item['type'] as String? ?? 'quiz';
    final score = type == 'reading' 
        ? (item['score'] as num?)?.toDouble() ?? 0.0
        : DatabaseHelpers.safeIntFromResult(item, 'score').toDouble();
    final maxScore = type == 'reading'
        ? (item['max_score'] as num?)?.toDouble() ?? 10.0
        : DatabaseHelpers.safeIntFromResult(item, 'max_score').toDouble();
    final percentage = _calculatePercentage(score.toInt(), maxScore.toInt());
    final scoreColor = _getScoreColor(percentage);
    
    final title = type == 'reading'
        ? item['title'] as String? ?? 'Reading Recording'
        : item['quiz_title'] as String? ?? 'Untitled Quiz';
    final subtitle = type == 'reading'
        ? 'Reading Level: ${item['reading_level'] as String? ?? 'Unknown'}'
        : item['class_name'] as String? ?? '';
    final submittedAt = item['submitted_at'] as String?;
    final attemptNumber = item['attempt_number'] as int?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scoreColor.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _showQuizDetails(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              type == 'reading' ? Icons.mic : Icons.quiz,
                              size: 20,
                              color: type == 'reading' ? Colors.purple : Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (type == 'quiz' && attemptNumber != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Attempt #$attemptNumber',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scoreColor, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$score / $maxScore',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: scoreColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (submittedAt != null && submittedAt.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Submitted: ${_formatDate(submittedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showQuizDetails(Map<String, dynamic> item) async {
    final type = item['type'] as String? ?? 'quiz';

    if (type == 'reading') {
      // Show reading recording details
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.mic, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(child: Text(item['title'] as String? ?? 'Reading Recording')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score: ${item['score']} / ${item['max_score']}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(_calculatePercentage(
                      (item['score'] as num?)?.toInt() ?? 0,
                      (item['max_score'] as num?)?.toInt() ?? 10,
                    )),
                  ),
                ),
                const SizedBox(height: 16),
                if (item['teacher_comments'] != null && (item['teacher_comments'] as String).isNotEmpty) ...[
                  const Text(
                    'Teacher Comments:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(item['teacher_comments'] as String),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Quiz details
    final quizId = item['quiz_id'] as String;
    final submissionId = item['submission_id'] as String;
    final quizAnswers = item['quiz_answers'] as List<dynamic>? ?? [];

    // Load quiz questions
    try {
      final questionsRes = await supabase
          .from('quiz_questions')
          .select('''
            id,
            question_text,
            question_type,
            sort_order,
            question_options(
              id,
              option_text,
              is_correct
            ),
            matching_pairs(
              id,
              left_item,
              right_item
            )
          ''')
          .eq('quiz_id', quizId)
          .order('sort_order', ascending: true);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizReviewPage(
              quizTitle: item['quiz_title'] as String? ?? 'Quiz Review',
              questions: List<Map<String, dynamic>>.from(questionsRes),
              studentAnswers: quizAnswers,
              score: DatabaseHelpers.safeIntFromResult(item, 'score'),
              maxScore: DatabaseHelpers.safeIntFromResult(item, 'max_score'),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading quiz details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quiz details: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("📝 My Graded Quizzes"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (gradedQuizzes.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("📝 My Graded Quizzes"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                'No graded quizzes yet',
                style: TextStyle(color: Colors.grey[600], fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete quizzes to see your grades here',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("📝 My Graded Quizzes"),
      ),
      body: RefreshIndicator(
        onRefresh: _loadGradedQuizzes,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: gradedQuizzes.length,
          itemBuilder: (context, index) => _buildQuizCard(gradedQuizzes[index]),
        ),
      ),
    );
  }
}

class QuizReviewPage extends StatelessWidget {
  final String quizTitle;
  final List<Map<String, dynamic>> questions;
  final List<dynamic> studentAnswers;
  final int score;
  final int maxScore;

  const QuizReviewPage({
    super.key,
    required this.quizTitle,
    required this.questions,
    required this.studentAnswers,
    required this.score,
    required this.maxScore,
  });

  Map<String, dynamic>? _findStudentAnswer(String questionId) {
    try {
      return studentAnswers.firstWhere(
        (answer) => answer['question_id'] == questionId || answer['id'] == questionId,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  Widget _buildQuestionReview(int index, Map<String, dynamic> question) {
    final questionId = question['id'] as String;
    final questionText = question['question_text'] as String? ?? '';
    final questionType = question['question_type'] as String? ?? '';
    final studentAnswer = _findStudentAnswer(questionId);
    final studentAnswerText = studentAnswer?['user_answer'] as String? ?? 
                               studentAnswer?['answer'] as String? ?? 
                               '(No answer provided)';

    // Get correct answer
    String correctAnswerText = '';
    bool isCorrect = false;

    final options = question['question_options'] as List<dynamic>? ?? [];
    final correctOption = options.firstWhere(
      (opt) => opt['is_correct'] == true,
      orElse: () => null,
    );

    if (correctOption != null) {
      correctAnswerText = correctOption['option_text'] as String? ?? '';
      isCorrect = studentAnswerText.trim().toLowerCase() == correctAnswerText.trim().toLowerCase();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Question ${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              questionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildAnswerSection('Your Answer:', studentAnswerText, isCorrect ? Colors.green : Colors.red),
            const SizedBox(height: 8),
            _buildAnswerSection('Correct Answer:', correctAnswerText, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerSection(String label, String answer, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              answer,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentage = maxScore > 0 ? (score / maxScore) * 100 : 0.0;
    final scoreColor = percentage >= 80 ? Colors.green : percentage >= 60 ? Colors.orange : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(quizTitle),
      ),
      body: Column(
        children: [
          // Score Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: scoreColor.withOpacity(0.3), width: 2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Your Score',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$score / $maxScore',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 20,
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Questions Review
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: questions.length,
              itemBuilder: (context, index) => _buildQuestionReview(index, questions[index]),
            ),
          ),
        ],
      ),
    );
  }
}
