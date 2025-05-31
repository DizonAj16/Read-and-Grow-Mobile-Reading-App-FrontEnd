import 'package:deped_reading_app_laravel/pages/auth%20pages/landing_page.dart';
import 'package:flutter/material.dart';
import 'student_dashboard_page.dart';
import 'my class pages/my_class_page.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  int _currentIndex = 0; // Track the current index of the bottom navigation bar
  final PageController _pageController =
      PageController(); // PageController for smooth transitions

  // List of pages for the bottom navigation bar
  final List<Widget> _pages = [StudentDashboardPage(), MyClassPage()];

  // Function to handle tab selection in the bottom navigation bar
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300), // Smooth transition duration
      curve: Curves.easeInOut, // Smooth transition curve
    );
  }

  // Method to show the logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => _LogoutDialog(
        onStay: () => Navigator.pop(context), // Close dialog
        onLogout: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LandingPage(),
            ),
            (Route<dynamic> route) => false,
          ); // Navigate to login
        },
      ),
    );
  }

  // Method to build the AppBar widget
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      // AppBar with dynamic title based on the selected tab
      title: Text(
        _currentIndex == 0 ? "Student Dashboard" : "Tasks/Activities",
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      iconTheme: IconThemeData(color: Colors.white),
      actions: [
        // Profile and logout menu
        _ProfilePopupMenu(onLogout: _showLogoutDialog),
        IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped, // Handle tab selection
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "My Class"),
        ],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}

// Modularized PopupMenu for profile and logout
class _ProfilePopupMenu extends StatelessWidget {
  final VoidCallback onLogout;
  const _ProfilePopupMenu({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        radius: 20,
        backgroundColor: const Color.fromARGB(255, 191, 8, 8),
        child: Text("D"),
      ),
      tooltip: "Student Profile",
      onSelected: (value) {
        if (value == 'logout') {
          onLogout();
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'profile',
          child: SizedBox(
            height: 160, // Adjusted height for better spacing
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color.fromARGB(255, 191, 8, 8),
                  child: Text(
                    "D",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Arjec Jose Dizon',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                ),
                SizedBox(height: 4),
                Text(
                  'Student',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey, fontSize: 14),
                ),
                Divider(
                  height: 20,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Logout',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Modularized Logout Dialog
class _LogoutDialog extends StatelessWidget {
  final VoidCallback onStay;
  final VoidCallback onLogout;
  const _LogoutDialog({required this.onStay, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.primary,
            size: 50,
          ),
          SizedBox(height: 8),
          Text(
            "Are you leaving?",
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Text(
        "We hope to see you again soon! Are you sure you want to log out?",
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Colors.black87),
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
          onPressed: onStay,
          child: Text("Stay", style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onLogout,
          child: Text("Log Out", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
