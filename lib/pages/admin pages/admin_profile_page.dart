import 'package:flutter/material.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key});

  // Function to show a confirmation dialog for logout
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
              size: 50,
            ),
            SizedBox(height: 8),
            Text(
              "Are you sure?",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          "You are about to log out of your admin account. Make sure to save your work before leaving.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context), // Close dialog
            child: Text("Stay", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.of(context).pushReplacementNamed('/');
            },
            child: Text("Log Out", style: TextStyle(color: Colors.white),)
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile picture
            CircleAvatar(
              radius: 80,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
            SizedBox(height: 20),
            // Admin name
            Text(
              "Admin",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            // Admin email
            Text(
              "admin@example.com",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            // Logout button
            ElevatedButton.icon(
              onPressed:
                  () => _showLogoutConfirmation(
                    context,
                  ), // Show logout confirmation
              icon: Icon(Icons.logout, size: 20, color: Colors.white),
              label: Text("Logout", style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
