import 'package:deped_reading_app_laravel/pages/activities/activity_controller.dart';
import 'package:flutter/material.dart';

class TasksTab extends StatelessWidget {
  final int gradeLevel;

  const TasksTab({super.key, required this.gradeLevel});

  @override
  Widget build(BuildContext context) {
    // ✅ Map grade levels to task IDs
    final Map<int, List<int>> gradeTaskMap = {
      1: [1, 2],
      2: [3],
      3: [4],
      4: [5, 6, 7, 8, 9],
      5: [10, 11, 12, 13],
    };

    final List<int> tasksForGrade = gradeTaskMap[gradeLevel] ?? [];

    if (tasksForGrade.isEmpty) {
      return Center(
        child: Text(
          "No tasks available for Grade $gradeLevel",
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasksForGrade.length,
      itemBuilder: (context, index) {
        final taskId = tasksForGrade[index];
        final taskTitle = "Task $taskId";

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(Icons.task, color: Theme.of(context).colorScheme.primary),
            title: Text(taskTitle),
            subtitle: Text("Grade $gradeLevel"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              // ✅ Navigate to the ActivityController
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActivityController(
                    activityTitle: taskTitle,
                    onCompleted: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$taskTitle completed!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
