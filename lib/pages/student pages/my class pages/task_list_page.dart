import 'package:flutter/material.dart';

import '../../../widgets/student_page_widgets/task_card.dart';
import '../../activities/activity_controller.dart';

class TaskListPage extends StatelessWidget {
  final int studentLevel;

  const TaskListPage({super.key, required this.studentLevel});

  @override
  Widget build(BuildContext context) {
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
                        ActivityController(
                          activityTitle: task['title']!,
                          studentLevel: studentLevel,
                        ),
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
        ];
      case 4:
        return [
          {"title": "Task 1", "status": "Pending"},
          {"title": "Task 2", "status": "Pending (Test Checkpoint)"},
          {"title": "Task 3", "status": "Pending (Test Checkpoint)"},
          {"title": "Task 4", "status": "Pending (Test Checkpoint)"},
          {"title": "Task 5", "status": "Pending (Test Checkpoint)"},
        ];
      // Level 5 is inactive, so we'll leave this empty for now
      default:
        return [
          {"title": "Task 1 - Day 1", "status": "Pending"},
          {"title": "Task 2 - Day 2", "status": "Pending"},
          {"title": "Task 3 - Day 3", "status": "Pending"},
          {"title": "Task 4-5 - Day 4-5", "status": "Pending"},
        ];
    }
  }
}
