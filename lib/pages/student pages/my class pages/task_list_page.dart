import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../activities/activity_controller.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  List<Map<String, String>> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasksAndStatuses();
  }

  Future<void> _fetchTasksAndStatuses() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final taskTitles = await ApiService.fetchTasksForStudent(context);

      setState(() {
        tasks = taskTitles.map((title) {
          final status = prefs.getString("task_status_$title") ?? "Pending";
          return {"title": title, "status": status};
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load tasks: $e")),
      );
    }
  }

  Future<void> _saveTaskStatus(String title, String status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("task_status_$title", status);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasks.isEmpty) {
      return const Center(child: Text("No tasks assigned for your grade level."));
    }

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
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
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
                    builder: (_) => ActivityController(
                          activityTitle: task['title']!,
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
              color: isCompleted ? Colors.green.shade700 : Colors.orange.shade700,
            ),
            const SizedBox(width: 2),
            Text(
              status,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isCompleted
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
