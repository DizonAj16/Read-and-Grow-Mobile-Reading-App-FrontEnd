import 'dart:async';
import 'package:deped_reading_app_laravel/api/task_service.dart';
import 'package:deped_reading_app_laravel/api/supabase_api_service.dart';
import 'package:deped_reading_app_laravel/models/quiz_questions.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20classes/add_quiz_screen.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20classes/tabs/view_quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TasksPage extends StatefulWidget {
  final String classId;

  const TasksPage({super.key, required this.classId});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late Future<List<Map<String, dynamic>>> _tasksFuture;
  final supabase = Supabase.instance.client;
  RealtimeChannel? _quizChannel;
  RealtimeChannel? _assignmentChannel;

  @override
  void initState() {
    super.initState();
    _tasksFuture = TaskService.fetchTasksForClass(widget.classId);
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _quizChannel?.unsubscribe();
    _assignmentChannel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    try {
      // Subscribe to quiz deletions for real-time updates
      _quizChannel = supabase
          .channel(
            'quizzes_changes_${widget.classId}_${DateTime.now().millisecondsSinceEpoch}',
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'quizzes',
            callback: (payload) {
              debugPrint('📡 [REALTIME] Quiz deleted: ${payload.oldRecord}');
              // Refresh tasks to reflect the deletion
              if (mounted) {
                _refreshTasks();
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'quizzes',
            callback: (payload) {
              debugPrint('📡 [REALTIME] Quiz added: ${payload.newRecord}');
              // Refresh tasks to show the new quiz
              if (mounted) {
                _refreshTasks();
              }
            },
          )
          .subscribe((status, [error]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint(
                '✅ [REALTIME] Subscribed to quiz changes for class ${widget.classId}',
              );
            } else {
              debugPrint('⚠️ [REALTIME] Quiz subscription status: $status');
              if (error != null) {
                debugPrint('❌ [REALTIME] Quiz subscription error: $error');
              }
            }
          });

      // Subscribe to assignment changes for real-time updates
      _assignmentChannel = supabase
          .channel(
            'assignments_changes_${widget.classId}_${DateTime.now().millisecondsSinceEpoch}',
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'assignments',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'class_room_id',
              value: widget.classId,
            ),
            callback: (payload) {
              debugPrint(
                '📡 [REALTIME] Assignment deleted: ${payload.oldRecord}',
              );
              // Refresh tasks to reflect the deletion
              if (mounted) {
                _refreshTasks();
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'assignments',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'class_room_id',
              value: widget.classId,
            ),
            callback: (payload) {
              debugPrint(
                '📡 [REALTIME] Assignment added: ${payload.newRecord}',
              );
              // Refresh tasks to show the new assignment
              if (mounted) {
                _refreshTasks();
              }
            },
          )
          .subscribe((status, [error]) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint(
                '✅ [REALTIME] Subscribed to assignment changes for class ${widget.classId}',
              );
            } else {
              debugPrint(
                '⚠️ [REALTIME] Assignment subscription status: $status',
              );
              if (error != null) {
                debugPrint(
                  '❌ [REALTIME] Assignment subscription error: $error',
                );
              }
            }
          });
    } catch (e) {
      debugPrint('⚠️ [REALTIME] Error setting up subscriptions: $e');
      // Continue without real-time - manual refresh will still work
    }
  }

  Future<void> _refreshTasks() async {
    if (mounted) {
      setState(() {
        _tasksFuture = TaskService.fetchTasksForClass(widget.classId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryLight = Color.alphaBlend(primaryColor.withOpacity(0.1), Colors.white);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Class Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/animation/empty_box.json', width: 200),
                  const SizedBox(height: 24),
                  const Text("No Tasks Found"),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshTasks,
            color: primaryColor,
            backgroundColor: Colors.white,
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final item = tasks[index];
                final quizTitle = item['title'];
                final taskTitle = item['tasks']?['title'];

                final quizId = item['id']; // from quizzes table
                final dueDate = item['due_date'];
                final hasQuiz = quizId != null; // only check if quizId exists
                // DEBUG PRINTS
                debugPrint("========== TASK ITEM #$index ==========");
                debugPrint(
                  "quizId: $quizId, quizTitle: $quizTitle, hasQuiz: $hasQuiz",
                );
                debugPrint("Raw Item: $item");
                debugPrint("Task Title: $taskTitle");
                debugPrint("Quiz Title: $quizTitle");
                debugPrint("Quiz ID: $quizId");
                debugPrint("Has Quiz?: $hasQuiz");
                debugPrint("Due Date (raw): $dueDate");

                debugPrint("========================================");
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            hasQuiz
                                ? primaryLight
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        hasQuiz ? Icons.quiz : Icons.assignment,
                        color: hasQuiz ? primaryColor : Colors.grey,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      quizTitle ?? taskTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          dueDate != null
                              ? "Due: ${DateTime.parse(dueDate).toLocal().toString().split(' ')[0]}"
                              : "No due date",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (hasQuiz) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Quiz',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing:
                        hasQuiz
                            ? PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: primaryColor),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editQuiz(quizId, quizTitle);
                                } else if (value == 'delete') {
                                  _deleteQuiz(quizId, quizTitle);
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            color: primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text('Edit Quiz'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text('Delete Quiz'),
                                        ],
                                      ),
                                    ),
                                  ],
                            )
                            : null,
                    isThreeLine: hasQuiz,
                    onTap:
                        hasQuiz
                            ? () async {
                              debugPrint(
                                "➡️ onTap triggered for quizId: $quizId, quizTitle: $quizTitle",
                              );

                              try {
                                // Fetch quiz + questions
                                final quizData =
                                    await TaskService.fetchQuizWithQuestions(
                                      quizId!,
                                    );

                                if (quizData == null ||
                                    quizData['questions'] == null ||
                                    (quizData['questions'] as List).isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'No questions found for this quiz.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final questions =
                                    quizData['questions'] as List<QuizQuestion>;
                                final quizTitle =
                                    quizData['quiz']['title'] as String;

                                // Navigate to preview
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => QuizPreviewScreen(
                                            title: quizTitle,
                                            questions: questions,
                                          ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint("❌ Error in onTap: $e");
                              }
                            }
                            : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _editQuiz(String quizId, String? quizTitle) async {
    if (!mounted) return;
    
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      // Fetch quiz data for editing
      final quizData = await ApiService.fetchQuizForEdit(quizId);
      final questions = quizData?['questions'] as List<dynamic>? ?? [];

      final multipleChoiceQuestions =
          questions
              .where((q) => q['question_type'] == 'multipleChoice')
              .toList();

      final trueFalseQuestions =
          questions.where((q) => q['question_type'] == 'trueOrFalse').toList();

      final fillInTheBlanksQuestions =
          questions
              .where((q) => q['question_type'] == 'fillInTheBlanks')
              .toList();

      final matchingQuestions =
          questions.where((q) => q['question_type'] == 'matching').toList();
      debugPrint('Total questions: ${questions.length}');
      for (var q in questions) {
        debugPrint(
          'Question: ${q['question_text']}, type: ${q['question_type']}',
        );
      }

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (quizData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load quiz data. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Navigate to edit quiz screen
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => AddQuizScreen(
                  quizId: quizId,
                  initialQuizData: quizData,
                  classRoomId: widget.classId,
                ),
          ),
        );

        // Refresh if quiz was updated
        if (result == true && mounted) {
          _refreshTasks();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quiz updated successfully!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading quiz: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteQuiz(String quizId, String? quizTitle) async {
    if (!mounted) return;
    
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text('Delete Quiz'),
              ],
            ),
            content: Text(
              'Are you sure you want to delete "${quizTitle ?? 'this quiz'}"?\n\n'
              'This will permanently delete:\n'
              '• The quiz\n'
              '• All questions\n'
              '• All student submissions\n\n'
              'This action cannot be undone.',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context, false);
                  }
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.pop(context, true);
                  }
                },
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
      builder: (context) => Center(child: CircularProgressIndicator(color: primaryColor)),
    );

    try {
      // Add timeout to prevent hanging
      final success = await ApiService.deleteQuiz(quizId).timeout(
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Quiz deleted successfully')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Real-time subscription will update automatically, but refresh to ensure consistency
          _refreshTasks();
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
                    child: Text(
                      'Failed to delete quiz. The quiz may not exist or you may not have permission.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          // Refresh to sync state
          _refreshTasks();
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
                  child: Text(
                    'Deletion timed out. Please check your connection and try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
        // Refresh to check actual state
        _refreshTasks();
      }
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      if (mounted) {
        final errorMessage =
            e.toString().contains('network') ||
                    e.toString().contains('connection')
                ? 'Network error. Please check your internet connection and try again.'
                : 'Error deleting quiz: ${e.toString()}';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
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
        _refreshTasks();
      }
    }
  }
}