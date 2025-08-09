import 'package:flutter/material.dart';

// TaskCard displays a task with title, status, and a button to view the task.
class TaskCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final VoidCallback onViewTask;

  const TaskCard({
    super.key,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.onViewTask,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(Icons.assignment, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          status,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
        ),
        trailing: ElevatedButton(
          onPressed: onViewTask,
          child: Text("View"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}
