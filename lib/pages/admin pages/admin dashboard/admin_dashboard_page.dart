import 'package:deped_reading_app_laravel/pages/admin%20pages/admin%20dashboard/registration%20forms/create_account_dialog.dart';
import 'package:flutter/material.dart';
import 'student and teachers list/admin_view_students_page.dart';
import 'student and teachers list/admin_view_teachers_page.dart';
import 'admin_analytics_page.dart';

/// Admin dashboard page with options to view teachers/students and create accounts.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            SizedBox(height: 20),
            // Button to view the list of teachers
            ElevatedButton.icon(
              icon: Image.asset(
                'assets/icons/teacher.png',
                width: 40,
                height: 40,
              ),
              label: Text(
                "View Teacher List",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AdminViewTeachersPage(),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            // Button to view the list of students
            ElevatedButton.icon(
              icon: Image.asset(
                'assets/icons/graduating-student.png',
                width: 40,
                height: 40,
              ),
              label: Text(
                "View Student List",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AdminViewStudentsPage(),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            // Button to view analytics
            ElevatedButton.icon(
              icon: Icon(Icons.analytics, size: 40),
              label: Text(
                "View Analytics & Performance",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminAnalyticsPage(),
                  ),
                );
              },
            ),
            ],
          ),
        ),
      ),
      // Floating action button to open the create teacher or student dialog
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => showDialog(
              context: context,
              builder: (context) => const CreateAccountDialog(),
            ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Colors.white),
        shape: CircleBorder(),
        tooltip: "Create Teacher or Student Account",
      ),
    );
  }
}
