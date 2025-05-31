import 'package:flutter/material.dart';
import 'dart:math';
import '../../widgets/teacher_page_widgets/horizontal_card.dart';
import '../../widgets/teacher_page_widgets/student_list_tile.dart';
import '../../widgets/teacher_page_widgets/class_card.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Floating action button to create a new class
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateClassDialog(context);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: "Create Class",
        shape: CircleBorder(), // Ensures the button is circular
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message for teacher
            Text(
              "Welcome, Teacher!",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 20),
            // Horizontal scrollable cards for teacher statistics
            SizedBox(
              height: 150, // Height for the horizontal cards
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Students count card
                  TeacherDashboardHorizontalCard(
                    title: "Students",
                    value: "100",
                    gradientColors: [Colors.blue, Colors.lightBlueAccent],
                    icon: Icons.people,
                  ),
                  SizedBox(width: 16),
                  // Sections count card
                  TeacherDashboardHorizontalCard(
                    title: "Sections",
                    value: "3",
                    gradientColors: [Colors.green, Colors.lightGreenAccent],
                    icon: Icons.class_,
                  ),
                  SizedBox(width: 16),
                  // My Classes count card
                  TeacherDashboardHorizontalCard(
                    title: "My Classes",
                    value: "25",
                    gradientColors: [Colors.purple, Colors.deepPurpleAccent],
                    icon: Icons.school,
                  ),
                  SizedBox(width: 16),
                  // Rankings card
                  TeacherDashboardHorizontalCard(
                    title: "Rankings",
                    value: "Top 10",
                    gradientColors: [Colors.orange, Colors.deepOrangeAccent],
                    icon: Icons.star,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Student list section
            Text(
              "Student List",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 10),
            // List of students (sample)
            Column(
              children: [
                TeacherDashboardStudentListTile(
                  name: "Alice Johnson",
                  section: "1A",
                  level: "1",
                  avatarLetter: "A",
                ),
                TeacherDashboardStudentListTile(
                  name: "Bob Smith",
                  section: "2B",
                  level: "2",
                  avatarLetter: "B",
                ),
                TeacherDashboardStudentListTile(
                  name: "Charlie Davis",
                  section: "3C",
                  level: "1",
                  avatarLetter: "C",
                ),
                TeacherDashboardStudentListTile(
                  name: "Diana Evans",
                  section: "1A",
                  level: "3",
                  avatarLetter: "D",
                ),
                // See more button for student list
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Handle "See more" logic for Student List
                    },
                    child: Text(
                      "See more...",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // My Classes section
            Text(
              "My Classes",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 10),
            // List of teacher's classes (sample)
            Column(
              children: [
                TeacherDashboardClassCard(
                  className: "English 1",
                  section: "Grade 1 - Section A",
                  studentCount: 30,
                ),
                TeacherDashboardClassCard(
                  className: "English 2",
                  section: "Grade 2 - Section B",
                  studentCount: 25,
                ),
                TeacherDashboardClassCard(
                  className: "English 3",
                  section: "Grade 3 - Section C",
                  studentCount: 20,
                ),
                // See more button for class list
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Handle "See more" logic for Class List
                    },
                    child: Text(
                      "See more...",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Shows a dialog for creating a new class
  void _showCreateClassDialog(BuildContext context) {
    final TextEditingController classNameController = TextEditingController();
    final TextEditingController classSectionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              // Dialog icon and title
              Icon(
                Icons.class_,
                color: Theme.of(context).colorScheme.primary,
                size: 50,
              ),
              SizedBox(height: 8),
              Text(
                "Create New Class",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              Divider(
                thickness: 1,
                color: Colors.grey.shade300,
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Class name input
                TextField(
                  controller: classNameController,
                  decoration: InputDecoration(
                    labelText: "Class Name",
                    prefixIcon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary,),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Class section input
                TextField(
                  controller: classSectionController,
                  decoration: InputDecoration(
                    labelText: "Class Section",
                    prefixIcon: Icon(Icons.group, color: Theme.of(context).colorScheme.primary,),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            // Cancel button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            // Create button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Handle class creation logic here
                String className = classNameController.text.trim();
                String classSection = classSectionController.text.trim();

                if (className.isNotEmpty && classSection.isNotEmpty) {
                  // Perform class creation logic
                  Navigator.pop(context); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Class created successfully!")),
                  );
                } else {
                  // Show error if fields are empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill in all fields")),
                  );
                }
              },
              child: Text("Create", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
