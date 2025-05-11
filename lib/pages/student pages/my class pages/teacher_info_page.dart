import 'package:flutter/material.dart';

class TeacherInfoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            "Teacher Name",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 8),
          Text(
            "Email: teacher@example.com",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
