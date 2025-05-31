import 'package:flutter/material.dart';
import 'pupil_submissions_and_report_page.dart';
import 'teacher_dashboard_page.dart';
import 'badges_list_page.dart';
import 'teacher_profile_page.dart';

class TeacherPage extends StatefulWidget {
  const TeacherPage({super.key});

  @override
  _TeacherPageState createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _currentTitle = "Teacher Dashboard";
  String _currentRoute = '/dashboard';

  // Function to show a confirmation dialog for logout
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Column(
              children: [
                Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.primary,
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
              "You are about to log out. Make sure to save your work before leaving.",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
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
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (Route<dynamic> route) => false,
                  );
                },
                child: Text("Log Out", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  // Function to navigate to a specific route and update the title
  void _navigateTo(String route, String title) {
    if (_currentRoute != route) {
      setState(() {
        _currentTitle = title;
        _currentRoute = route; // Update the current route
      });
      Navigator.pop(context); // Close the drawer
      _navigatorKey.currentState?.pushReplacementNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar with dynamic title and search button
        title: Text(_currentTitle, style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search_rounded)),
        ],
      ),
      drawer: Drawer(
        // Drawer with navigation options
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 250, // Adjust the height of the DrawerHeader
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: GestureDetector(
                  // Navigate to the teacher profile page
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherProfilePage(),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Hero(
                        tag: 'teacher-profile-image',
                        child: CircleAvatar(
                          backgroundColor: Colors.white70,
                          radius: 50,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/placeholder/teacher_placeholder.png',
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Teacher',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Navigation options in the drawer
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Dashboard'),
              selected: _currentRoute == '/dashboard', // Highlight if active
              selectedTileColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(30),
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: _currentRoute == '/dashboard' ? 24 : 16,
              ), // Adjust padding for selected
              onTap: () => _navigateTo('/dashboard', 'Teacher Dashboard'),
            ),
            ListTile(
              leading: Icon(Icons.task_rounded),
              title: Text('Badges List'),
              selected: _currentRoute == '/badges', // Highlight if active
              selectedTileColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(30),
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: _currentRoute == '/badges' ? 24 : 16,
              ), // Adjust padding for selected
              onTap: () => _navigateTo('/badges', 'Badges List'),
            ),
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('Pupil Submissions/Reports'),
              selected: _currentRoute == '/submissions', // Highlight if active
              selectedTileColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(30),
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: _currentRoute == '/submissions' ? 24 : 16,
              ), // Adjust padding for selected
              onTap: () => _navigateTo('/submissions', 'Student Submissions'),
            ),
            ListTile(
              leading: Icon(Icons.logout_sharp),
              title: Text('Log out'),
              onTap:
                  () => _showLogoutConfirmation(
                    context,
                  ), // Show logout confirmation
            ),
          ],
        ),
      ),
      body: Navigator(
        // Navigator to handle page transitions
        key: _navigatorKey,
        initialRoute: '/dashboard',
        onGenerateRoute: (RouteSettings settings) {
          Widget page;
          switch (settings.name) {
            case '/badges':
              page = BadgesListPage();
              break;
            case '/submissions':
              page = StudentSubmissionsPage();
              break;
            case '/dashboard':
            default:
              page = TeacherDashboardPage();
              break;
          }
          return MaterialPageRoute(builder: (_) => page);
        },
      ),
    );
  }
}
