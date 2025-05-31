import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  // Shows a dialog for creating a new teacher account
  void _showCreateTeacherAccountDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController positionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              // Icon at the top of the dialog
              Icon(
                Icons.person_add,
                color: Theme.of(context).colorScheme.primary,
                size: 50,
              ),
              SizedBox(height: 8),
              // Dialog title
              Text(
                "Create Teacher Account",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              // Divider below the title
              Divider(thickness: 1, color: Colors.grey.shade300),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Full Name input field
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary,),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Email Address input field
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: Icon(Icons.email, color: Theme.of(context).colorScheme.primary,),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Password input field
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary,),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Position input field
                TextField(
                  controller: positionController,
                  decoration: InputDecoration(
                    labelText: "Position",
                    prefixIcon: Icon(Icons.work, color: Theme.of(context).colorScheme.primary,),
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
            // Cancel button closes the dialog
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            // Create button validates input and shows a snackbar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
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
                      content: Text("Teacher account created successfully!"),
                    ),
                  );
                } else {
                  // Show error if any field is empty
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
      // Floating action button to open the create teacher dialog
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTeacherAccountDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Colors.white),
        shape: CircleBorder(),
        tooltip: "Create Teacher Account",
      ),
    );
  }
}