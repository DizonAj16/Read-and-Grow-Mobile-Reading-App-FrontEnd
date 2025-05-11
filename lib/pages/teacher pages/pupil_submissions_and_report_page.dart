import 'package:flutter/material.dart';

class StudentSubmissionsPage extends StatelessWidget {
  const StudentSubmissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Display a simple message for the Student Submissions page
      body: Center(
        child: Text(
          "This is the Student Submissions page.",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
