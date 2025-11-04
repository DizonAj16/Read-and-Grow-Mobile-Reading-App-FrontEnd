import 'package:deped_reading_app_laravel/pages/student%20pages/student%20class%20pages/reading_tasks_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ReadingLevelsPage extends StatefulWidget {
  const ReadingLevelsPage({super.key});

  @override
  State<ReadingLevelsPage> createState() => _ReadingLevelsPageState();
}

class _ReadingLevelsPageState extends State<ReadingLevelsPage> with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  Map<String, dynamic>? currentLevel;
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> gradedTasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReadingLevel();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReadingLevel() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      // Load current reading level and tasks
      final res = await supabase
          .from('students')
          .select('current_reading_level_id, reading_levels(*, reading_tasks(*))')
          .eq('id', user.id)
          .maybeSingle();

      if (res != null) {
        currentLevel = res['reading_levels'];
        tasks = List<Map<String, dynamic>>.from(res['reading_levels']['reading_tasks'] ?? []);
      }

      // Load graded readings
      await _loadGradedReadings(user.id);
    } catch (e) {
      debugPrint('Error loading reading level: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadGradedReadings(String userId) async {
    try {
      // Validate user ID
      if (userId.isEmpty) {
        debugPrint('Invalid user ID');
        setState(() {
          gradedTasks = [];
        });
        return;
      }

      // Fetch graded recordings for the current student
      final recordingsRes = await supabase
          .from('student_recordings')
          .select('task_id, score, teacher_comments, graded_at, tasks(*)')
          .eq('student_id', userId)
          .eq('needs_grading', false)
          .not('score', 'is', null)
          .order('graded_at', ascending: false);

      final gradedRecordings = List<Map<String, dynamic>>.from(recordingsRes);
      
      // Get unique task IDs with their grades (filter out null scores)
      Map<String, Map<String, dynamic>> gradedTasksMap = {};
      
      for (var recording in gradedRecordings) {
        try {
          final taskId = recording['task_id']?.toString();
          final score = recording['score'];
          
          // Validate task ID and score
          if (taskId == null || taskId.isEmpty || score == null) {
            continue;
          }

          // Get task data safely
          final tasksData = recording['tasks'];
          Map<String, dynamic>? taskData;
          
          if (tasksData != null) {
            if (tasksData is Map<String, dynamic>) {
              taskData = tasksData;
            } else if (tasksData is List && tasksData.isNotEmpty) {
              taskData = Map<String, dynamic>.from(tasksData.first);
            }
          }

          if (taskData != null && taskData.isNotEmpty && !gradedTasksMap.containsKey(taskId)) {
            // Safely extract values
            final title = taskData['title']?.toString() ?? 'Untitled Task';
            final description = taskData['description']?.toString();
            final teacherComments = recording['teacher_comments']?.toString();
            final gradedAt = recording['graded_at']?.toString();

            gradedTasksMap[taskId] = {
              ...taskData,
              'id': taskId,
              'title': title,
              'description': description,
              'score': score is num ? score.toDouble() : double.tryParse(score.toString()) ?? 0.0,
              'teacher_comments': teacherComments,
              'graded_at': gradedAt,
            };
          }
        } catch (e) {
          debugPrint('Error processing recording: $e');
          // Continue with next recording
        }
      }

      if (mounted) {
        setState(() {
          gradedTasks = gradedTasksMap.values.toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading graded readings: $e');
      if (mounted) {
        setState(() {
          gradedTasks = [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("📚 ${currentLevel?['title'] ?? 'Reading Level'}"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Tasks', icon: Icon(Icons.list)),
            Tab(text: 'Graded', icon: Icon(Icons.grade)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Tasks Tab
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentLevel?['description'] != null)
                  Text(
                    currentLevel!['description'] ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(
                          child: Text(
                            'No tasks available',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (_, i) {
                            final task = tasks[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              child: ListTile(
                                title: Text(task['title'] ?? 'Untitled Task'),
                                subtitle: Text(task['description'] ?? ''),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReadingTaskPage(task: task),
                                    ),
                                  ).then((_) => _loadReadingLevel());
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Graded Tab
          gradedTasks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No graded readings yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Complete reading tasks to see your grades here',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    final user = supabase.auth.currentUser;
                    if (user != null) {
                      await _loadGradedReadings(user.id);
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: gradedTasks.length,
                    itemBuilder: (_, i) {
                      final task = gradedTasks[i];
                      final score = task['score'] as num?;
                      final comments = task['teacher_comments'] as String?;
                      final gradedAt = task['graded_at'] as String?;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 3,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReadingTaskPage(task: task),
                              ),
                            ).then((_) => _loadReadingLevel());
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
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
                                            task['title'] ?? 'Untitled Task',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (task['description'] != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                task['description'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getScoreColor(score),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            score != null
                                                ? score.toStringAsFixed(1)
                                                : 'N/A',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (comments != null && comments.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.comment,
                                          size: 20,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            comments,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (gradedAt != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDateTime(gradedAt),
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
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Color _getScoreColor(num? score) {
    if (score == null) return Colors.grey;
    if (score >= 8) return Colors.green;
    if (score >= 6) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'Unknown';
    try {
      final dt = DateTime.parse(dateTime);
      return 'Graded on ${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'Invalid date';
    }
  }
}
