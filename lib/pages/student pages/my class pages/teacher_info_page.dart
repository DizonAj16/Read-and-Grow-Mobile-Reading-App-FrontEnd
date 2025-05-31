import 'package:flutter/material.dart';

class TeacherInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display teacher's profile picture
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          SizedBox(height: 16),
          // Display teacher's name
          Text(
            "Teacher",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 8),
          // Display teacher's email
          Text(
            "Email: teacher@example.com",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 8),
          // Display teacher's position
          Text(
            "Position: Senior Teacher",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
