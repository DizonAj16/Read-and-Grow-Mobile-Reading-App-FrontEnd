import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/database_helpers.dart';

class TeacherGradedQuizzesPage extends StatefulWidget {
  const TeacherGradedQuizzesPage({super.key});

  @override
  State<TeacherGradedQuizzesPage> createState() => _TeacherGradedQuizzesPageState();
}

class _TeacherGradedQuizzesPageState extends State<TeacherGradedQuizzesPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> gradedQuizzes = [];
  List<Map<String, dynamic>> allClasses = [];
  List<Map<String, dynamic>> allStudents = [];
  String? selectedClassId;
  String? selectedStudentId;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);

    try {
      // Load teacher's classes
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => loading = false);
        return;
      }

      final classesRes = await supabase
          .from('class_rooms')
          .select('id, class_name')
          .eq('teacher_id', user.id)
          .order('class_name');

      // Load all students from teacher's classes
      final classIds = (classesRes as List).map((c) => c['id']).toList();
      final studentsRes = <Map<String, dynamic>>[];
      
      if (classIds.isNotEmpty) {
        final enrollments = await supabase
            .from('student_enrollments')
            .select('student_id, students(id, student_name)')
            .inFilter('class_room_id', classIds);

        final studentMap = <String, Map<String, dynamic>>{};
        for (var enrollment in enrollments) {
          final student = enrollment['students'] as Map<String, dynamic>?;
          if (student != null) {
            final studentId = student['id'] as String;
            if (!studentMap.containsKey(studentId)) {
              studentMap[studentId] = student;
            }
          }
        }
        studentsRes.addAll(studentMap.values);
      }

      await _loadGradedQuizzes();

      setState(() {
        allClasses = List<Map<String, dynamic>>.from(classesRes);
        allStudents = studentsRes;
        loading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => loading = false);
    }
  }

  Future<void> _loadGradedQuizzes() async {
    try {
      // Build query based on filters
      dynamic query = supabase
          .from('student_submissions')
          .select('''
            id,
            assignment_id,
            student_id,
            score,
            max_score,
            submitted_at,
            quiz_answers,
            assignments!inner(
              id,
              quiz_id,
              class_room:class_rooms(id, class_name),
              task:tasks(
                id,
                title,
                quizzes(
                  id,
                  title
                )
              ),
              quiz:quizzes(
                id,
                title
              )
            ),
            students!inner(
              id,
              student_name
            )
          ''')
          .not('score', 'is', null);

      // Apply filters BEFORE order()
      if (selectedClassId != null) {
        query = query.eq('assignments.class_room_id', selectedClassId!);
      }

      if (selectedStudentId != null) {
        query = query.eq('student_id', selectedStudentId!);
      }

      // Apply ordering after filters
      query = query.order('submitted_at', ascending: false);

      final submissions = await query;

      List<Map<String, dynamic>> gradedList = [];

      for (var submission in submissions) {
        final assignment = submission['assignments'] as Map<String, dynamic>?;
        if (assignment == null) continue;

        final classRoom = assignment['class_room'] as Map<String, dynamic>?;
        final student = submission['students'] as Map<String, dynamic>?;
        
        // Check for quiz directly linked via quiz_id in assignment
        Map<String, dynamic>? quiz;
        String? taskTitle;
        
        final directQuiz = assignment['quiz'] as Map<String, dynamic>?;
        if (directQuiz != null) {
          quiz = directQuiz;
          taskTitle = null; // No task for directly linked quizzes
        } else {
          // Check for quiz linked through task
          final task = assignment['task'] as Map<String, dynamic>?;
          if (task != null) {
            taskTitle = task['title'] as String?;
            final quizzes = task['quizzes'] as List<dynamic>?;
            if (quizzes != null && quizzes.isNotEmpty) {
              quiz = quizzes.first as Map<String, dynamic>;
            }
          }
        }
        
        if (quiz == null) continue;

        gradedList.add({
          'submission_id': submission['id'],
          'assignment_id': submission['assignment_id'],
          'student_id': submission['student_id'],
          'student_name': student?['student_name'] ?? 'Unknown Student',
          'quiz_id': quiz['id'],
          'quiz_title': quiz['title'],
          'task_title': taskTitle,
          'class_name': classRoom?['class_name'] ?? 'Unknown Class',
          'score': submission['score'],
          'max_score': submission['max_score'],
          'submitted_at': submission['submitted_at'],
          'quiz_answers': submission['quiz_answers'],
        });
      }

      setState(() {
        gradedQuizzes = gradedList;
      });
    } catch (e) {
      debugPrint('Error loading graded quizzes: $e');
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

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedClassId,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Class',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Classes'),
                    ),
                    ...allClasses.map((cls) => DropdownMenuItem<String>(
                      value: cls['id'] as String,
                      child: Text(cls['class_name'] as String? ?? ''),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedClassId = value;
                      selectedStudentId = null; // Reset student filter
                    });
                    _loadGradedQuizzes();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedStudentId,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Student',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Students'),
                    ),
                    ...allStudents.map((student) => DropdownMenuItem<String>(
                      value: student['id'] as String,
                      child: Text(student['student_name'] as String? ?? ''),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStudentId = value;
                    });
                    _loadGradedQuizzes();
                  },
                ),
              ),
            ],
          ),
          if (selectedClassId != null || selectedStudentId != null) ...[
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  selectedClassId = null;
                  selectedStudentId = null;
                });
                _loadGradedQuizzes();
              },
              icon: const Icon(Icons.clear, size: 18),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    final score = DatabaseHelpers.safeIntFromResult(quiz, 'score');
    final maxScore = DatabaseHelpers.safeIntFromResult(quiz, 'max_score');
    final percentage = _calculatePercentage(score, maxScore);
    final scoreColor = _getScoreColor(percentage);
    final quizTitle = quiz['quiz_title'] as String? ?? 'Untitled Quiz';
    final studentName = quiz['student_name'] as String? ?? 'Unknown Student';
    final className = quiz['class_name'] as String? ?? '';
    final submittedAt = quiz['submitted_at'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scoreColor.withOpacity(0.3), width: 2),
      ),
      child: InkWell(
        onTap: () => _showQuizDetails(quiz),
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
                        Text(
                          quizTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Student: $studentName',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Class: $className',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
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

  Future<void> _showQuizDetails(Map<String, dynamic> quiz) async {
    final quizId = quiz['quiz_id'] as String;
    final quizAnswers = quiz['quiz_answers'] as List<dynamic>? ?? [];

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
            builder: (context) => TeacherQuizReviewPage(
              quizTitle: quiz['quiz_title'] as String? ?? 'Quiz Review',
              studentName: quiz['student_name'] as String? ?? 'Unknown Student',
              questions: List<Map<String, dynamic>>.from(questionsRes),
              studentAnswers: quizAnswers,
              score: DatabaseHelpers.safeIntFromResult(quiz, 'score'),
              maxScore: DatabaseHelpers.safeIntFromResult(quiz, 'max_score'),
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
          title: const Text("📊 Graded Quizzes"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Graded Quizzes"),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: gradedQuizzes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 20),
                        Text(
                          'No graded quizzes found',
                          style: TextStyle(color: Colors.grey[600], fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Student quiz submissions will appear here',
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadGradedQuizzes,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: gradedQuizzes.length,
                      itemBuilder: (context, index) => _buildQuizCard(gradedQuizzes[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class TeacherQuizReviewPage extends StatelessWidget {
  final String quizTitle;
  final String studentName;
  final List<Map<String, dynamic>> questions;
  final List<dynamic> studentAnswers;
  final int score;
  final int maxScore;

  const TeacherQuizReviewPage({
    super.key,
    required this.quizTitle,
    required this.studentName,
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
            _buildAnswerSection('Student Answer:', studentAnswerText, isCorrect ? Colors.green : Colors.red),
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
          width: 140,
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
                  studentName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Score',
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
