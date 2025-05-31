import 'package:flutter/material.dart';
import 'dart:math';

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
              CircleAvatar(
                backgroundColor: _getRandomColor(),
                child: Text(
                  avatarLetter,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 16),
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
