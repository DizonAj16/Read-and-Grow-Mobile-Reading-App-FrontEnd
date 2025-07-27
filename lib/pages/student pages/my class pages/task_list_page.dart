import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../activities/activity_controller.dart';

class TaskListPage extends StatefulWidget {
  final int studentLevel;

  const TaskListPage({super.key, required this.studentLevel});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List<Map<String, String>> tasks = [];

  @override
  void initState() {
    super.initState();
    _initializeTasks();
  }

  Future<void> _initializeTasks() async {
    final fetchedTasks = _getTasksForLevel(widget.studentLevel);
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      tasks =
          fetchedTasks.map((task) {
            final title = task['title'] ?? '';
            final savedStatus =
                prefs.getString("task_status_$title") ?? 'Pending';
            return {'title': title, 'status': savedStatus};
          }).toList();
    });
  }

  Future<void> _saveTaskStatus(String title, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("task_status_$title", status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          tasks.isEmpty
              ? Center(
                child: Text(
                  "No tasks available for this level.",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final title = task['title'] ?? 'Untitled';
                  final status = task['status'] ?? 'Pending';

                  bool isLocked =
                      index > 0 && tasks[index - 1]['status'] != "Completed";

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
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: _buildStatusBadge(status),
                      ),
                      trailing:
                          isLocked
                              ? ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.lock, size: 16),
                                label: const Text("Locked"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              )
                              : ElevatedButton(
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ActivityController(
                                            activityTitle: title,
                                            studentLevel: widget.studentLevel,
                                            onCompleted: () async {
                                              await _saveTaskStatus(
                                                title,
                                                "Completed",
                                              );
                                              _initializeTasks(); // Reload updated statuses
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
              ),
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

  List<Map<String, String>> _getTasksForLevel(int level) {
    switch (level) {
      case 1:
        return [
          {"title": "Task 1"},
          {"title": "Task 2"},
        ];
      case 2:
        return [
          {"title": "Task 1"},
        ];
      case 3:
        return [
          {"title": "Task 1"},
          {"title": "Task 2"},
          {"title": "Task 3"},
        ];
      case 4:
        return [
          {"title": "Task 1"},
          {"title": "Task 2"},
          {"title": "Task 3"},
          {"title": "Task 4"},
          {"title": "Task 5"},
        ];

      case 5:
        return [
          {"title": "Task 1 - Day 1"},
          {"title": "Task 2 - Day 2"},
          {"title": "Task 3 - Day 3"},
          {"title": "Task 4-5 - Day 4-5"},
        ];
      default:
        return [];
    }
  }
}
