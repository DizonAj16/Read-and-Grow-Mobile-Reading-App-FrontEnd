import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  void _showCreateTeacherDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController positionController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Create Teacher Account",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Teacher Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: positionController,
                decoration: InputDecoration(
                  labelText: "Teacher Position",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle teacher account creation logic here
                String name = nameController.text.trim();
                String position = positionController.text.trim();
                String password = passwordController.text.trim();

                if (name.isNotEmpty && position.isNotEmpty && password.isNotEmpty) {
                  // Perform account creation logic
                  Navigator.pop(context); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Teacher account created successfully!")),
                  );
                } else {
                  // Show error if fields are empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please fill in all fields")),
                  );
                }
              },
              child: Text("Create"),
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
            ElevatedButton(
              onPressed: () {
                // Handle view teacher list logic
              },
              child: Text("View Teacher List"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Handle view student list logic
              },
              child: Text("View Student List"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTeacherDialog(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: "Create Teacher Account",
      ),
    );
  }
}
