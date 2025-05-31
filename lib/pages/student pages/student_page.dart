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
  int _currentIndex = 0; // Tracks selected tab index
  final PageController _pageController =
      PageController(); // Controls page transitions

  // List of main pages for navigation
  final List<Widget> _pages = [StudentDashboardPage(), MyClassPage()];

  // Handles tab selection and animates to the selected page
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300), // Animation duration
      curve: Curves.easeInOut, // Animation curve
    );
  }

  // Shows logout confirmation dialog
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
          ); // Navigate to landing page
        },
      ),
    );
  }

  // Builds the AppBar with dynamic title and actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      // Title changes based on selected tab
      title: Text(
        _currentIndex == 0 ? "Student Dashboard" : "Tasks/Activities",
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      iconTheme: IconThemeData(color: Colors.white),
      actions: [
        // Profile popup menu with logout option
        _ProfilePopupMenu(onLogout: _showLogoutDialog),
        // Placeholder for additional actions
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
        // Updates current index when page is changed via swipe
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _pages,
      ),
      // Bottom navigation bar for switching between pages
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

// Popup menu for profile and logout actions
class _ProfilePopupMenu extends StatelessWidget {
  final VoidCallback onLogout;
  const _ProfilePopupMenu({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      // Profile avatar as menu icon
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
        // Profile info section in popup
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
        // Logout option in popup
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

// Dialog for logout confirmation
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
          // Logout icon at top of dialog
          Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.primary,
            size: 50,
          ),
          SizedBox(height: 8),
          // Dialog title
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
      // Dialog message
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
        // Stay button closes dialog
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
        // Logout button triggers logout callback
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
