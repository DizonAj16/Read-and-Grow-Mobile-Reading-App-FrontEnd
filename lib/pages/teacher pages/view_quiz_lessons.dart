import 'package:deped_reading_app_laravel/api/supabase_api_service.dart';
import 'package:deped_reading_app_laravel/helper/QuizHelper.dart';
import 'package:deped_reading_app_laravel/models/quiz_questions.dart';
import 'package:flutter/material.dart';

class LessonQuizListScreen extends StatefulWidget {
  const LessonQuizListScreen({super.key});

  @override
  State<LessonQuizListScreen> createState() => _LessonQuizListScreenState();
}

class _LessonQuizListScreenState extends State<LessonQuizListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _lessons = [];
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _lessons = await ApiService.getLessons() ?? [];
      _quizzes = await ApiService.getQuizzes() ?? [];
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lessons & Quizzes'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [Tab(text: 'Lessons'), Tab(text: 'Quizzes')],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          controller: _tabController,
          children: [
            _buildLessonList(),
            _buildQuizList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonList() {
    if (_lessons.isEmpty) return const Center(child: Text('No lessons added yet.'));
    return ListView.builder(
      itemCount: _lessons.length,
      itemBuilder: (context, index) {
        final lesson = _lessons[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(lesson['title'] ?? 'No Title'),
            subtitle: Text(lesson['description'] ?? ''),
            trailing: ElevatedButton(
              child: const Text('View Quiz'),
              onPressed: () {
                if (lesson['quiz_id'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QuizPreviewScreen(
                        quizId: lesson['quiz_id'],
                        userRole: 'student', // replace with your actual logged-in role
                        loggedInUserId: '123', // replace with your actual user id
                        taskId: lesson['id'].toString(),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizList() {
    if (_quizzes.isEmpty) return const Center(child: Text('No quizzes added yet.'));
    return ListView.builder(
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        final quiz = _quizzes[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(quiz['title'] ?? 'No Title'),
            trailing: ElevatedButton(
              child: const Text('View'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizPreviewScreen(
                      quizId: quiz['id'],
                      userRole: 'student', // replace with actual role
                      loggedInUserId: '123', // replace with actual user ID
                      taskId: quiz['id'].toString(),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ===========================================
// INTERACTIVE QUIZ SCREEN
// ===========================================
class QuizPreviewScreen extends StatefulWidget {
  final String quizId;
  final String userRole;
  final String loggedInUserId;
  final String taskId;

  const QuizPreviewScreen({
    super.key,
    required this.quizId,
    required this.userRole,
    required this.loggedInUserId,
    required this.taskId,
  });

  @override
  State<QuizPreviewScreen> createState() => _QuizPreviewScreenState();
}

class _QuizPreviewScreenState extends State<QuizPreviewScreen> {
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
      // Fetch quiz questions from API / Supabase
      final questionsData = await ApiService.getQuizQuestions(widget.quizId) ?? [];

      // Ensure we're mapping only if we have Map data
      if (questionsData.isNotEmpty && questionsData.first is Map<String, dynamic>) {
        _questions = questionsData
            .map<QuizQuestion>((e) => QuizQuestion.fromMap(e as Map<String, dynamic>))
            .toList();
      } else if (questionsData.isNotEmpty && questionsData.first is QuizQuestion) {
        _questions = List<QuizQuestion>.from(questionsData);
      } else {
        _questions = [];
      }

      // Initialize QuizHelper if user is a student
      if (_questions.isNotEmpty && widget.userRole == 'student') {
        _quizHelper = QuizHelper(
          studentId: widget.loggedInUserId,
          taskId: widget.taskId,
          questions: _questions,
          supabase: ApiService.supabase,
        );

        // Optional: start timer for first question if needed
        final firstQuestion = _questions[_currentIndex];
        if (firstQuestion.timeLimitSeconds != null) {
          _quizHelper!.startTimer(
            firstQuestion.timeLimitSeconds!,
            _submitQuiz,
                () => setState(() {}),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading quiz: $e')),
      );
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
      appBar: AppBar(title: const Text('Quiz Preview')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${_currentIndex + 1}/${_questions.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(q.questionText, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),

            // MULTIPLE CHOICE
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

            // FILL IN THE BLANK
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
