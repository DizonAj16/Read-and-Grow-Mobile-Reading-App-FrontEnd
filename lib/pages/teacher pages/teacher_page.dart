import 'package:deped_reading_app_laravel/api/auth_service.dart';
import 'package:deped_reading_app_laravel/models/teacher.dart';
import 'package:flutter/material.dart';
import 'pupil_submissions_and_report_page.dart';
import 'teacher dashboard/teacher_dashboard_page.dart';
import 'badges_list_page.dart';
import 'teacher_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../pages/auth pages/landing_page.dart';
import '../../widgets/navigation/page_transition.dart';

class TeacherPage extends StatefulWidget {
  const TeacherPage({super.key});

  @override
  _TeacherPageState createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _currentTitle = "Teacher Dashboard";
  String _currentRoute = '/dashboard';
  String _teacherName = "Teacher"; // Default
  String? _profilePicture;

  /// Logs out the teacher:
  /// - Calls the API to logout.
  /// - Clears SharedPreferences.
  /// - Shows a loading dialog and then navigates to the landing page.
  /// - Shows an error dialog if logout fails.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await AuthService.logout(token);

    if (response.statusCode == 200) {
      // ✅ Remove authentication and user-specific data
      await Teacher.clearPrefs();

      // ✅ Remove stored classes and students data
      await prefs.remove('teacher_classes');
      await prefs.remove('students_data');
      

      // ✅ Show logout progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      "Logging out...",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop(); // Close the loading dialog
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(page: LandingPage()),
          (route) => false,
        );
      }
    } else {
      // ❌ Handle logout failure
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Logout Failed'),
              content: const Text('Unable to logout. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    }
  }

  /// Shows a confirmation dialog before logging out.
  /// Provides options to stay or log out.
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
                // Logout icon and title
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            // Dialog message
            content: Text(
              "You are about to log out. Make sure to save your work before leaving.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              // Stay button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context), // Close dialog
                child: Text(
                  "Stay",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              // Log out button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: logout,
                child: Text("Log Out", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
              ),
            ],
          ),
    );
  }

  /// Navigates to a specific route and updates the app bar title.
  /// Closes the drawer and pushes the new route in the nested navigator.
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
  void initState() {
    // Initializes the teacher page and loads the teacher's name.
    super.initState();
    _loadTeacherName();
  }

  /// Loads the teacher's name from SharedPreferences.
  /// Updates the UI if a name is found.
  Future<void> _loadTeacherName() async {
    final teacher = await Teacher.fromPrefs();

    setState(() {
      _teacherName = teacher.name;
      _profilePicture = teacher.profilePicture;
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Main build method for the teacher page.
    /// Assembles the app bar, drawer, and nested navigator for teacher sections.
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
              height: 230, // DrawerHeader height
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: GestureDetector(
                  // Navigate to the teacher profile page on tap
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeacherProfilePage(),
                      ),
                    );
                    await _loadTeacherName(); // Reload teacher_name and profile_picture from SharedPreferences
                  },

                  child: Column(
                    children: [
                      // Teacher profile avatar with Hero animation
                      Hero(
                        tag: 'teacher-profile-image',
                        child: Material(
                          color: Colors.transparent,
                          child: CircleAvatar(
                            backgroundColor: Colors.white70,
                            radius: 50,
                            child: ClipOval(
                              child:
                                  _profilePicture != null &&
                                          _profilePicture!.isNotEmpty
                                      ? Image.network(
                                        _profilePicture!,
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Image.asset(
                                            'assets/placeholder/teacher_placeholder.png',
                                            height: 80,
                                            width: 80,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      )
                                      : Image.asset(
                                        'assets/placeholder/teacher_placeholder.png',
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                      ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 10),
                      // Teacher name label
                      Text(
                        _teacherName, // Use loaded teacher name
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Dashboard navigation option
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
            // Badges list navigation option
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
            // Pupil submissions/reports navigation option
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
            // Log out option
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
        // Nested navigator to handle page transitions within teacher section
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
