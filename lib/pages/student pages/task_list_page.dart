import 'package:flutter/material.dart';
import '../activities/activity_controller.dart';

class TaskListPage extends StatelessWidget {
  final int studentLevel;

  const TaskListPage({super.key, this.studentLevel = 1});

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> tasks = _getTasksForLevel(studentLevel);

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(
          context,
          title: task['title']!,
          status: task['status']!,
          statusColor:
              task['status'] == "Completed" ? Colors.green : Colors.orange,
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

  Widget _buildTaskCard(
    BuildContext context, {
    required String title,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                status == "Completed"
                    ? Icons.check_circle
                    : Icons.pending_actions,
                color: Colors.white,
                size: 25,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'view_task') {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              ActivityController(activityTitle: title),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        const begin = Offset(
                          1.0,
                          0.0,
                        ); // Slide in from the right
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
                }
              },
              itemBuilder:
                  (BuildContext context) => [
                    PopupMenuItem(
                      value: 'view_task',
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: 8),
                          Text('View Task'),
                        ],
                      ),
                    ),
                  ],
              icon: Icon(
                Icons.more_vert,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
