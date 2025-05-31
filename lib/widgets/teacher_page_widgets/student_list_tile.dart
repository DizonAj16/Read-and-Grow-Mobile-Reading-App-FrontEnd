import 'package:flutter/material.dart';
import 'dart:math';

// TeacherDashboardStudentListTile displays a student in the teacher dashboard list with avatar, name, section, and level.
class TeacherDashboardStudentListTile extends StatelessWidget {
  final String name;
  final String section;
  final String level;
  final String avatarLetter;

  const TeacherDashboardStudentListTile({
    Key? key,
    required this.name,
    required this.section,
    required this.level,
    required this.avatarLetter,
  }) : super(key: key);

  // Generates a random color for the avatar background
  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[Random().nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              // Student avatar with random color
              CircleAvatar(
                backgroundColor: _getRandomColor(),
                child: Text(
                  avatarLetter,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 16),
              // Student name, section, and level
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Section: $section | Level: $level",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              // More actions button (placeholder)
              IconButton(
                icon: Icon(
                  Icons.more_horiz,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  // Handle action button logic
                },
                tooltip: "More Actions",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
