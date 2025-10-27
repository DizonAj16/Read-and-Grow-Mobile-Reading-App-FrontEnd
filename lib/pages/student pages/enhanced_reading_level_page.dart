import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'enhanced_reading_task_page.dart';

class EnhancedReadingLevelPage extends StatefulWidget {
  const EnhancedReadingLevelPage({super.key});

  @override
  State<EnhancedReadingLevelPage> createState() => _EnhancedReadingLevelPageState();
}

class _EnhancedReadingLevelPageState extends State<EnhancedReadingLevelPage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? currentLevel;
  List<Map<String, dynamic>> tasks = [];
  Map<String, dynamic> progressMap = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadingLevel();
  }

  Future<void> _loadReadingLevel() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Get student's current level with tasks
      final studentRes = await supabase
          .from('students')
          .select('current_reading_level_id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (studentRes == null || studentRes['current_reading_level_id'] == null) {
        setState(() => isLoading = false);
        return;
      }

      final levelId = studentRes['current_reading_level_id'];
      
      // Get level details
      final levelRes = await supabase
          .from('reading_levels')
          .select('*')
          .eq('id', levelId)
          .maybeSingle();

      // Get tasks for this level, ordered
      final tasksRes = await supabase
          .from('tasks')
          .select('*')
          .eq('reading_level_id', levelId)
          .order('order', ascending: true);

      // Get student progress for these tasks
      final progressRes = await supabase
          .from('student_task_progress')
          .select('task_id, attempts_left, completed, score, max_score')
          .eq('student_id', user.id)
          .inFilter('task_id', (tasksRes as List).map((t) => t['id']).toList());

      final Map<String, dynamic> progress = {};
      for (var p in progressRes) {
        progress[p['task_id']] = p;
      }

      setState(() {
        currentLevel = levelRes;
        tasks = List<Map<String, dynamic>>.from(tasksRes);
        progressMap = progress;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading reading level: $e');
      setState(() => isLoading = false);
    }
  }

  bool _isTaskLocked(int index) {
    if (index == 0) return false; // First task always available
    
    // Check if previous task is completed
    final prevTask = tasks[index - 1];
    final prevProgress = progressMap[prevTask['id']];
    
    return prevProgress == null || prevProgress['completed'] != true;
  }

  bool _isTaskCompleted(int taskId) {
    final progress = progressMap[taskId];
    return progress != null && progress['completed'] == true;
  }

  int _getAttemptsLeft(int taskId) {
    final progress = progressMap[taskId];
    return progress?['attempts_left'] ?? 3;
  }

  String _getProgressStatus(int taskId) {
    final progress = progressMap[taskId];
    if (progress == null) return 'not_started';
    if (progress['completed'] == true) return 'completed';
    return 'in_progress';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentLevel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('📚 My Reading Level')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No reading level assigned yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Ask your teacher to assign you a reading level',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final totalTasks = tasks.length;
    final completedCount = progressMap.values
        .where((p) => p['completed'] == true)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text('📚 ${currentLevel!['title']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReadingLevel,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Text(
                    currentLevel!['title'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentLevel!['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildProgressStat('Completed', '$completedCount/$totalTasks', Icons.check_circle),
                        const VerticalDivider(color: Colors.white70),
                        _buildProgressStat('Pending', '${totalTasks - completedCount} remaining', Icons.schedule),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tasks List
          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No tasks assigned yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final taskId = task['id'];
                      final locked = _isTaskLocked(index);
                      final completed = _isTaskCompleted(taskId);
                      final attemptsLeft = _getAttemptsLeft(taskId);
                      final status = _getProgressStatus(taskId);

                      return _buildTaskCard(
                        task: task,
                        index: index,
                        locked: locked,
                        completed: completed,
                        attemptsLeft: attemptsLeft,
                        status: status,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard({
    required Map<String, dynamic> task,
    required int index,
    required bool locked,
    required bool completed,
    required int attemptsLeft,
    required String status,
  }) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (locked) {
      statusColor = Colors.grey;
      statusIcon = Icons.lock;
      statusText = 'Locked';
    } else if (completed) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Completed';
    } else if (status == 'in_progress') {
      statusColor = Colors.orange;
      statusIcon = Icons.radio_button_checked;
      statusText = 'In Progress';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.play_circle_outline;
      statusText = 'Start';
    }

    return Card(
      elevation: locked ? 1 : 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: locked
            ? BorderSide(color: Colors.grey.shade300)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: locked
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EnhancedReadingTaskPage(task: task),
                  ),
                ).then((_) => _loadReadingLevel());
              },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Task ${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          task['title'] ?? 'Untitled Task',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (locked)
                    Icon(Icons.lock, color: Colors.grey[400])
                  else
                    Icon(Icons.arrow_forward_ios, size: 16, color: statusColor),
                ],
              ),
              if (task['description'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  task['description'],
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: Icon(locked ? Icons.lock : Icons.public, size: 16),
                    label: Text(statusText),
                    backgroundColor: statusColor.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!locked && !completed)
                    Text(
                      '${attemptsLeft} attempts left',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
