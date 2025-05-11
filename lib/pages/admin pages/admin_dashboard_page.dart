import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard", style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                // Handle create teacher account logic
              },
              child: Text("Create Teacher Account"),
            ),
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
    );
  }
}
