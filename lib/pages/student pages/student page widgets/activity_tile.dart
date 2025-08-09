import 'package:flutter/material.dart';

// StudentDashboardActivityTile displays a recent activity with icon, title, and subtitle.
class StudentDashboardActivityTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const StudentDashboardActivityTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
