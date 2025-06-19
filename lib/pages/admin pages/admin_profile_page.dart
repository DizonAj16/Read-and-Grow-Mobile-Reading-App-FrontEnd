import 'package:flutter/material.dart';

class AdminProfilePage extends StatelessWidget {
  final VoidCallback? onLogout;
  const AdminProfilePage({super.key, this.onLogout});

  // Shows a confirmation dialog before logging out
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _LogoutConfirmationDialog(onLogout: onLogout),
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
            // Profile avatar
            CircleAvatar(
              radius: 80,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(Icons.person, size: 80, color: Colors.white),
            ),
            SizedBox(height: 20),
            // Admin display name
            Text(
              "Admin",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            // Admin email address
            Text(
              "admin@example.com",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            // Logout button triggers confirmation dialog
            ElevatedButton.icon(
              onPressed: () => _showLogoutConfirmation(context), // Show logout confirmation
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

class _LogoutConfirmationDialog extends StatelessWidget {
  final VoidCallback? onLogout;
  const _LogoutConfirmationDialog({this.onLogout});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          // Logout icon at the top of the dialog
          Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.error,
            size: 50,
          ),
          SizedBox(height: 8),
          // Dialog title
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
      // Dialog message
      content: Text(
        "You are about to log out of your admin account. Make sure to save your work before leaving.",
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        // Button to stay logged in (closes dialog)
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
        // Button to confirm logout (closes dialog and navigates to login/home)
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            if (onLogout != null) onLogout!();
          },
          child: Text("Log Out", style: TextStyle(color: Colors.white),)
        ),
      ],
    );
  }
}