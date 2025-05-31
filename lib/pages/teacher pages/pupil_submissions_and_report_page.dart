import 'package:flutter/material.dart';

// The StudentSubmissionsPage class represents the page where students can view their submissions.
class StudentSubmissionsPage extends StatelessWidget {
  const StudentSubmissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Centered message for the Student Submissions page
      body: Center(
        child: Text(
          "This is the Student Submissions page.",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
