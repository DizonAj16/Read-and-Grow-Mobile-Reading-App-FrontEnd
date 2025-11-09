import 'dart:async';
import 'package:deped_reading_app_laravel/widgets/helpers/quiz_preview_screen_interactive.dart';
import 'package:flutter/material.dart';
import 'package:deped_reading_app_laravel/api/supabase_api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final supabase = Supabase.instance.client;
  RealtimeChannel? _quizChannel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _quizChannel?.unsubscribe();
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    try {
      // Subscribe to quiz deletions for real-time updates
      _quizChannel = supabase
          .channel('quizzes_changes_${DateTime.now().millisecondsSinceEpoch}')
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'quizzes',
            callback: (payload) {
              debugPrint('📡 [REALTIME] Quiz deleted: ${payload.oldRecord}');
              // Remove deleted quiz from list
              if (mounted) {
                setState(() {
                  _quizzes.removeWhere((quiz) => quiz['id'] == payload.oldRecord['id']);
                });
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'quizzes',
            callback: (payload) {
              debugPrint('📡 [REALTIME] Quiz added: ${payload.newRecord}');
              // Reload data to get the new quiz
              if (mounted) {
                _loadData();
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'quizzes',
            callback: (payload) {
              debugPrint('📡 [REALTIME] Quiz updated: ${payload.newRecord}');
              // Reload data to get updated quiz
              if (mounted) {
                _loadData();
              }
            },
          )
          .subscribe((status, [error]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('✅ [REALTIME] Subscribed to quiz changes');
            } else {
              debugPrint('⚠️ [REALTIME] Subscription status: $status');
              if (error != null) {
                debugPrint('❌ [REALTIME] Subscription error: $error');
              }
            }
          });
    } catch (e) {
      debugPrint('⚠️ [REALTIME] Error setting up subscription: $e');
      // Continue without real-time - manual refresh will still work
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _lessons = await ApiService.getLessons();
      final quizzesResult = await ApiService.getQuizzes();
      _quizzes = quizzesResult ?? [];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
    if (_quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No quizzes added yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _quizzes.length,
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          final quizId = quiz['id']?.toString();
          final quizTitle = quiz['title'] ?? 'No Title';
          
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(quizTitle),
              subtitle: quiz['description'] != null 
                  ? Text(quiz['description'].toString())
                  : null,
              trailing: quizId != null && quizId.isNotEmpty
                  ? PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'view') {
                          _viewQuiz(quizId);
                        } else if (value == 'delete') {
                          _deleteQuiz(quizId, quizTitle);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, color: Colors.blue, size: 20),
                              SizedBox(width: 8),
                              Text('View'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text('Delete Quiz'),
                            ],
                          ),
                        ),
                      ],
                    )
                  : null,
              onTap: quizId != null && quizId.isNotEmpty
                  ? () => _viewQuiz(quizId)
                  : null,
            ),
          );
        },
      ),
    );
  }

  void _viewQuiz(String quizId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPreviewScreenInteractive(
          quizId: quizId,
          userRole: 'student',
          loggedInUserId: '123',
          taskId: quizId,
        ),
      ),
    );
  }

  Future<void> _deleteQuiz(String quizId, String quizTitle) async {
    if (!mounted) return;
    
    // Validate quiz ID
    if (quizId.isEmpty || quizId.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid quiz ID. Cannot delete quiz.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Delete Quiz'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$quizTitle"?\n\n'
          'This will permanently delete:\n'
          '• The quiz\n'
          '• All questions\n'
          '• All student submissions\n'
          '• Related assignments\n'
          '• Student recordings\n\n'
          'This action cannot be undone.',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Add timeout to prevent hanging
      final success = await ApiService.deleteQuiz(quizId)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('⏱️ [DELETE_QUIZ] Deletion timeout after 30 seconds');
              return false;
            },
          );
      
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (success) {
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Quiz deleted successfully'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Real-time subscription will update the list automatically
          // But we also manually refresh to ensure consistency
          await _loadData();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Failed to delete quiz. The quiz may not exist or you may not have permission.'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          // Refresh to sync state
          _loadData();
        }
      }
    } on TimeoutException {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.timer_off, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Deletion timed out. Please check your connection and try again.'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        // Refresh to check actual state
        _loadData();
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      if (mounted) {
        final errorMessage = e.toString().contains('network') || e.toString().contains('connection')
            ? 'Network error. Please check your internet connection and try again.'
            : 'Error deleting quiz: ${e.toString()}';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(errorMessage),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _deleteQuiz(quizId, quizTitle);
              },
            ),
          ),
        );
        // Refresh to sync state
        _loadData();
      }
    }
  }
}
