import 'package:flutter/material.dart';
import '../../activities/activity_controller.dart';
import '../../../widgets/student_page_widgets/task_card.dart'; // Import the new widget

class TaskListPage extends StatelessWidget {
  final int studentLevel;

  const TaskListPage({super.key, this.studentLevel = 1});

  @override
  Widget build(BuildContext context) {
    // Get tasks based on the student's level
    List<Map<String, String>> tasks = _getTasksForLevel(studentLevel);

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          title: task['title']!,
          status: task['status']!,
          statusColor:
              task['status'] == "Completed" ? Colors.green : Colors.orange,
          onViewTask: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        ActivityController(activityTitle: task['title']!),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // Function to get tasks based on the student's level
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
          {"title": "Task 2", "status": "Pending"},
          {"title": "Task 3", "status": "Pending"},
        ];
      case 3:
        return [
          {"title": "Task 1", "status": "Pending"},
          {"title": "Task 2", "status": "Pending"},
          {"title": "Task 3", "status": "Pending"},
          {"title": "Task 4", "status": "Pending"},
        ];
      case 4:
        return [
          {"title": "Task 1", "status": "Pending"},
          {"title": "Task 2", "status": "Pending"},
          {"title": "Task 3", "status": "Pending"},
          {"title": "Task 4", "status": "Pending"},
          {"title": "Task 5", "status": "Pending"},
          {"title": "Task 6", "status": "Pending"},
        ];
      case 5:
        return [
          {"title": "Task 1", "status": "Pending"},
          {"title": "Task 2", "status": "Pending"},
          {"title": "Task 3", "status": "Pending"},
          {"title": "Task 4", "status": "Pending"},
          {"title": "Task 5", "status": "Pending"},
          {"title": "Task 6", "status": "Pending"},
          {"title": "Task 7", "status": "Pending"},
          {"title": "Task 8", "status": "Pending"},
          {"title": "Task 9", "status": "Pending"},
          {"title": "Task 10", "status": "Pending"},
          {"title": "Task 11", "status": "Pending"},
        ];
      default:
        return [];
    }
  }
}
