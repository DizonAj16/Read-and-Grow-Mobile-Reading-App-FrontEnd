import 'package:flutter/material.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final VoidCallback onViewTask;

  const TaskCard({
    Key? key,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.onViewTask,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Status icon
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
            // Task details
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
            // Popup menu for task actions
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'view_task') {
                  onViewTask();
                }
              },
              itemBuilder: (BuildContext context) => [
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
