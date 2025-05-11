import 'package:flutter/material.dart';
import '../auth pages/login_page.dart';
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
  String _currentRoute = '/dashboard'; // Track the current route

  void _navigateTo(String route, String title) {
    setState(() {
      _currentTitle = title;
      _currentRoute = route; // Update the current route
    });
    Navigator.pop(context); // Close the drawer
    _navigatorKey.currentState?.pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTitle, style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search_rounded)),
        ],
      ),
      drawer: Drawer(
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherProfilePage(),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Center content vertically
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
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Dashboard'),
              selected: _currentRoute == '/dashboard', // Highlight if active
              selectedTileColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                // Add border radius to the selected tile
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
                // Add border radius to the selected tile
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
                // Add border radius to the selected tile
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }, // Close the drawer
            ),
          ],
        ),
      ),
      body: Navigator(
        key: _navigatorKey,
        initialRoute: '/dashboard',
        onGenerateRoute: (RouteSettings settings) {
          Widget page;
          switch (settings.name) {
            case '/badges':
              page = BadgesListPage();
              break;
            case '/submissions':
              page = StudentSubmissionsPage(); // Add this page
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
