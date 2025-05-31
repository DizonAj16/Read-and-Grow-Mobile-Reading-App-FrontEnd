import 'package:flutter/material.dart';

class StudentDashboardHorizontalCard extends StatelessWidget {
  final String title;
  final String value;
  final List<Color> gradientColors;
  final IconData icon;

  const StudentDashboardHorizontalCard({
    Key? key,
    required this.title,
    required this.value,
    required this.gradientColors,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
