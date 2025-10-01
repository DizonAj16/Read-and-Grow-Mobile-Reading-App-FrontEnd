import 'package:deped_reading_app_laravel/widgets/helpers/quiz_preview_screen_interactive.dart';
import 'package:flutter/material.dart';
import 'package:deped_reading_app_laravel/api/supabase_api_service.dart';
import 'package:deped_reading_app_laravel/models/quiz_questions.dart';

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
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
          children: [_buildLessonList(), _buildQuizList()],
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
                      builder: (_) => QuizPreviewScreenInteractive(
                        quizId: lesson['quiz_id'],
                        userRole: 'student',
                        loggedInUserId: '123',
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
                    builder: (_) => QuizPreviewScreenInteractive(
                      quizId: quiz['id'],
                      userRole: 'student',
                      loggedInUserId: '123',
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
