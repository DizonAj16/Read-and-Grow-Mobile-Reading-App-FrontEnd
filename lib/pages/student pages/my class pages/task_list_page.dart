import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../activities/activity_controller.dart';

class TaskListPage extends StatefulWidget {
  final int studentLevel;

  const TaskListPage({super.key, this.studentLevel = 1});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  late List<Map<String, String>> tasks;

  @override
  void initState() {
    super.initState();
    tasks = _getTasksForLevel(widget.studentLevel);
    _loadTaskStatuses();
  }

  Future<void> _loadTaskStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      for (var task in tasks) {
        String key = "task_status_${task['title']}";
        task['status'] = prefs.getString(key) ?? "Pending";
      }
    });
  }

  Future<void> _saveTaskStatus(String title, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("task_status_$title", status);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 30,
              vertical: 10,
            ),
            title: Text(
              task['title']!,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: _buildStatusBadge(task['status']!),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ActivityController(
                          activityTitle: task['title']!,
                          studentLevel: widget.studentLevel,
                          onCompleted: () {
                            setState(() {
                              task['status'] = "Completed";
                            });
                            _saveTaskStatus(task['title']!, "Completed");
                          },
                        ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text("View"),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    bool isCompleted = status == "Completed";

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isCompleted ? Colors.green.shade400 : Colors.orange.shade400,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.hourglass_bottom,
              size: 11,
              color:
                  isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
            ),
            const SizedBox(width: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color:
                    isCompleted
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Define tasks per level
  List<Map<String, String>> _getTasksForLevel(int level) {
    switch (level) {
      case 1:
        return [
          {"title": "Task 1", "status": "Pending"},
          {"title": "Task 2", "status": "Pending"},
        ];
      case 2:
        return [
          {"title": "Task 1", "status": "Pending"},
        ];
      case 3:
        return [
          {"title": "Task 1", "status": "Pending"},
          {"title": "Task 2", "status": "Pending"},
          {"title": "Task 3", "status": "Pending"},
        ];
      case 4:
        return List.generate(5, (index) {
          return {"title": "Task ${index + 1}", "status": "Pending"};
        });
      case 5:
        return [
          {"title": "Task 1 - Day 1", "status": "Pending"},
          {"title": "Task 2 - Day 2", "status": "Pending"},
          {"title": "Task 3 - Day 3", "status": "Pending"},
          {"title": "Task 4-5 - Day 4-5", "status": "Pending"},
        ];
      default:
        return [];
    }
  }
}
