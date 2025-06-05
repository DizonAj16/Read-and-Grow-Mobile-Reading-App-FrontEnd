import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  // Shows a dialog for creating a new teacher or student account
  void _showCreateTeacherAccountDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController positionController = TextEditingController();

    final TextEditingController studentNameController = TextEditingController();
    final TextEditingController studentLrnController = TextEditingController();
    final TextEditingController studentSectionController = TextEditingController();
    final TextEditingController studentGradeController =
        TextEditingController();
    final TextEditingController studentEmailController =
        TextEditingController();
    final TextEditingController studentPasswordController =
        TextEditingController();

    int selectedTab = 0; // 0 = Teacher, 1 = Student

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
                  // Icon at the top of the dialog
                  Icon(
                    Icons.person_add_alt_1,
                    color: Theme.of(context).colorScheme.primary,
                    size: 50,
                  ),
                  SizedBox(height: 8),
                  // Dialog title
                  Text(
                    selectedTab == 0
                        ? "Create Teacher Account"
                        : "Create Student Account",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Divider below the title
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  // Toggle between Teacher and Student account creation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Text("Teacher"),
                        selected: selectedTab == 0,
                        onSelected: (selected) {
                          if (!selected) return;
                          setState(() => selectedTab = 0);
                        },
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color:
                              selectedTab == 0
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
                          color:
                              selectedTab == 1
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
                    // Conditional fields based on the selected tab
                    if (selectedTab == 0) ...[
                      // Teacher fields
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Teacher Name",
                          prefixIcon: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: positionController,
                        decoration: InputDecoration(
                          labelText: "Position",
                          prefixIcon: Icon(
                            Icons.work,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(
                            Icons.email,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Student fields
                      TextField(
                        controller: studentNameController,
                        decoration: InputDecoration(
                          labelText: "Student Name",
                          prefixIcon: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // LRN field after name
                      TextField(
                        controller: studentLrnController,
                        decoration: InputDecoration(
                          labelText: "LRN",
                          prefixIcon: Icon(
                            Icons.confirmation_number,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: studentGradeController,
                        decoration: InputDecoration(
                          labelText: "Grade",
                          prefixIcon: Icon(
                            Icons.grade,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: studentSectionController,
                        decoration: InputDecoration(
                          labelText: "Section",
                          prefixIcon: Icon(
                            Icons.group,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: studentEmailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          prefixIcon: Icon(
                            Icons.account_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: studentPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Theme.of(context).colorScheme.primary,
                          ),
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
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel", style: TextStyle(color: Colors.grey)),
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
                      // Teacher account creation
                      String name = nameController.text.trim();
                      String email = emailController.text.trim();
                      String password = passwordController.text.trim();
                      String position = positionController.text.trim();

                      // Check if all fields are filled
                      if (name.isNotEmpty &&
                          email.isNotEmpty &&
                          password.isNotEmpty &&
                          position.isNotEmpty) {
                        // TODO: Add teacher account creation logic here
                        Navigator.pop(context); // Close the dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Teacher account created successfully!",
                            ),
                          ),
                        );
                      } else {
                        // Show error if any field is empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please fill in all fields")),
                        );
                      }
                    } else {
                      // Student account creation
                      String studentName = studentNameController.text.trim();
                      String studentSection =
                          studentSectionController.text.trim();
                      String studentGrade = studentGradeController.text.trim();
                      String studentEmail = studentEmailController.text.trim();
                      String studentPassword =
                          studentPasswordController.text.trim();

                      // Check if all fields are filled
                      if (studentName.isNotEmpty &&
                          studentSection.isNotEmpty &&
                          studentGrade.isNotEmpty &&
                          studentEmail.isNotEmpty &&
                          studentPassword.isNotEmpty) {
                        // TODO: Add student account creation logic here
                        Navigator.pop(context); // Close the dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Student account created successfully!",
                            ),
                          ),
                        );
                      } else {
                        // Show error if any field is empty
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            // Button to view the list of teachers
            ElevatedButton(
              onPressed: () {
                // TODO: Implement view teacher list logic
              },
              child: Text("View Teacher List"),
            ),
            SizedBox(height: 20),
            // Button to view the list of students
            ElevatedButton(
              onPressed: () {
                // TODO: Implement view student list logic
              },
              child: Text("View Student List"),
            ),
          ],
        ),
      ),
      // Floating action button to open the create teacher or student dialog
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTeacherAccountDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Colors.white),
        shape: CircleBorder(),
        tooltip: "Create Teacher or Student Account",
      ),
    );
  }
}
