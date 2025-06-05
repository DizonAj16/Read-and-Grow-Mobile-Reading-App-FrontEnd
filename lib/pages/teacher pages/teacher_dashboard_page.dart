import 'package:flutter/material.dart';
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
    final TextEditingController studentNameController = TextEditingController();
    final TextEditingController studentLrnController = TextEditingController();
    final TextEditingController studentSectionController = TextEditingController();
    final TextEditingController studentLevelController = TextEditingController();
    final TextEditingController studentEmailController = TextEditingController();
    final TextEditingController studentPasswordController = TextEditingController();

    // 0 = Create Class, 1 = Create Student
    int selectedTab = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Column(
                children: [
                  Icon(
                    selectedTab == 0 ? Icons.class_ : Icons.person_add,
                    color: Theme.of(context).colorScheme.primary,
                    size: 50,
                  ),
                  SizedBox(height: 8),
                  Text(
                    selectedTab == 0 ? "Create New Class" : "Create Student Account",
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
                  // Toggle buttons for selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Text("Class"),
                        selected: selectedTab == 0,
                        onSelected: (selected) {
                          if (!selected) return;
                          setState(() => selectedTab = 0);
                        },
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: selectedTab == 0
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: 12),
                      ChoiceChip(
                        label: Text("Student"),
                        selected: selectedTab == 1,
                        onSelected: (selected) {
                          if (!selected) return;
                          setState(() => selectedTab = 1);
                        },
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: selectedTab == 1
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedTab == 0) ...[
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
                    ] else ...[
                      // Student name input
                      TextField(
                        controller: studentNameController,
                        decoration: InputDecoration(
                          labelText: "Student Name",
                          prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary,),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Student LRN input
                      TextField(
                        controller: studentLrnController,
                        decoration: InputDecoration(
                          labelText: "LRN",
                          prefixIcon: Icon(Icons.confirmation_number, color: Theme.of(context).colorScheme.primary,),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Student section input
                      TextField(
                        controller: studentSectionController,
                        decoration: InputDecoration(
                          labelText: "Section",
                          prefixIcon: Icon(Icons.group, color: Theme.of(context).colorScheme.primary,),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Student level input
                      TextField(
                        controller: studentLevelController,
                        decoration: InputDecoration(
                          labelText: "Level",
                          prefixIcon: Icon(Icons.grade, color: Theme.of(context).colorScheme.primary,),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Student Email input
                      TextField(
                        controller: studentEmailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary,),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Student password input
                      TextField(
                        controller: studentPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary,),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (selectedTab == 0) {
                      // Create Class logic
                      String className = classNameController.text.trim();
                      String classSection = classSectionController.text.trim();

                      if (className.isNotEmpty && classSection.isNotEmpty) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Class created successfully!")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please fill in all fields")),
                        );
                      }
                    } else {
                      // Create Student logic
                      String studentName = studentNameController.text.trim();
                      String studentLrn = studentLrnController.text.trim();
                      String studentSection = studentSectionController.text.trim();
                      String studentLevel = studentLevelController.text.trim();
                      String studentEmail = studentEmailController.text.trim();
                      String studentPassword = studentPasswordController.text.trim();

                      if (studentName.isNotEmpty &&
                          studentLrn.isNotEmpty &&
                          studentSection.isNotEmpty &&
                          studentLevel.isNotEmpty &&
                          studentEmail.isNotEmpty &&
                          studentPassword.isNotEmpty) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Student account created successfully!")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please fill in all fields")),
                        );
                      }
                    }
                  },
                  child: Text(
                    selectedTab == 0 ? "Create" : "Add Student",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
