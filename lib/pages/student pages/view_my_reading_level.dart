import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReadingLevelsPage extends StatefulWidget {
  final String studentId;

  const ReadingLevelsPage({super.key, required this.studentId});

  @override
  State<ReadingLevelsPage> createState() => _ReadingLevelsPageState();
}

class _ReadingLevelsPageState extends State<ReadingLevelsPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  String? levelTitle;
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> progress = [];

  @override
  void initState() {
    super.initState();
    _loadReadingLevel();
  }

  Future<void> _loadReadingLevel() async {
    try {
      // 1. Get assigned reading level for this student
      final levelRes = await supabase
          .from('student_levels')
          .select('level_id, reading_levels(title)')
          .eq('student_id', widget.studentId)
          .eq('status', 'active')
          .maybeSingle();

      if (levelRes == null) {
        setState(() {
          loading = false;
          levelTitle = "No assigned level";
        });
        return;
      }

      final levelId = levelRes['level_id'];
      levelTitle = levelRes['reading_levels']['title'];

      // 2. Get all tasks for this level
      final taskRes = await supabase
          .from('reading_tasks')
          .select('*')
          .eq('level_id', levelId)
          .order('order', ascending: true);

      // 3. Get student progress for these tasks
      final progressRes = await supabase
          .from('student_task_progress')
          .select('task_id, status')
          .eq('student_id', widget.studentId)
          .inFilter('task_id', taskRes.map((t) => t['id']).toList());

      setState(() {
        tasks = List<Map<String, dynamic>>.from(taskRes);
        progress = List<Map<String, dynamic>>.from(progressRes);
        loading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading reading levels: $e");
      setState(() => loading = false);
    }
  }

  String _getTaskStatus(int taskId) {
    final record = progress.firstWhere(
          (p) => p['task_id'] == taskId,
      orElse: () => {},
    );
    return record.isEmpty ? "not_started" : record['status'];
  }

  bool _isTaskLocked(int index) {
    if (index == 0) return false; // first task always unlocked
    final prevTask = tasks[index - 1];
    final prevStatus = _getTaskStatus(prevTask['id']);
    return prevStatus != "completed";
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Reading Level: $levelTitle")),
      body: tasks.isEmpty
          ? const Center(child: Text("No tasks assigned"))
          : ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final status = _getTaskStatus(task['id']);
          final locked = _isTaskLocked(index);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ListTile(
              leading: Icon(
                locked
                    ? Icons.lock
                    : (status == "completed"
                    ? Icons.check_circle
                    : Icons.play_circle_fill),
                color: locked
                    ? Colors.grey
                    : (status == "completed"
                    ? Colors.green
                    : Colors.blue),
              ),
              title: Text(task['title']),
              subtitle: Text("Type: ${task['type']}"),
              trailing: locked
                  ? const Text("Locked", style: TextStyle(color: Colors.grey))
                  : ElevatedButton(
                onPressed: () {
                  // 🚀 Navigate to reading, quiz, or activity page
                  debugPrint("Opening task ${task['id']}");
                },
                child: Text(status == "completed" ? "Review" : "Start"),
              ),
            ),
          );
        },
      ),
    );
  }
}
