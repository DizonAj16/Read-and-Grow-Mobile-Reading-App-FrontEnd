import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  // Function to show a dialog for creating a teacher account
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
              Icon(
                Icons.person_add,
                color: Theme.of(context).colorScheme.primary,
                size: 50,
              ),
              SizedBox(height: 8),
              Text(
                "Create Teacher Account",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              Divider(thickness: 1, color: Colors.grey.shade300),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
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
                // Handle teacher account creation logic here
                String name = nameController.text.trim();
                String email = emailController.text.trim();
                String password = passwordController.text.trim();
                String position = positionController.text.trim();

                if (name.isNotEmpty &&
                    email.isNotEmpty &&
                    password.isNotEmpty &&
                    position.isNotEmpty) {
                  // Perform account creation logic
                  Navigator.pop(context); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Teacher account created successfully!"),
                    ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 20),
            // Button to view teacher list
            ElevatedButton(
              onPressed: () {
                // Handle view teacher list logic
              },
              child: Text("View Teacher List"),
            ),
            SizedBox(height: 20),
            // Button to view student list
            ElevatedButton(
              onPressed: () {
                // Handle view student list logic
              },
              child: Text("View Student List"),
            ),
          ],
        ),
      ),
      // Floating action button to create a teacher account
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
