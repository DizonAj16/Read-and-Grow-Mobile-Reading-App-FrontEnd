import 'package:flutter/material.dart';

class TeacherProfilePage extends StatelessWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar with the title "Teacher Profile"
        title: Text("Teacher Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile picture with a hero animation
            Hero(
              tag: 'teacher-profile-image',
              child: CircleAvatar(
                radius: 100,
                backgroundColor: Colors.white70,
                child: ClipOval(
                  child: Image.asset(
                    'assets/placeholder/teacher_placeholder.png',
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Teacher's name
            Text(
              "John Doe",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 10),
            // Teacher's designation
            Text(
              "Grade 5 Teacher",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            SizedBox(height: 30),
            // Contact information
            ListTile(
              leading: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
              title: Text("johndoe@example.com"),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
              title: Text("+1 234 567 890"),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.school, color: Theme.of(context).colorScheme.primary),
              title: Text("Elementary School"),
            ),
          ],
        ),
      ),
    );
  }
}
