import 'package:flutter/material.dart';
import 'admin_dashboard_page.dart';
import 'admin_profile_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // Controls page navigation in PageView
  final PageController _pageController = PageController();
  // Tracks the currently selected tab index
  int _currentIndex = 0;

  // Pages displayed in the PageView
  final List<Widget> _pages = [
    AdminDashboardPage(),
    AdminProfilePage(),
  ];

  // Handles tab selection and animates to the selected page
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Displays title based on selected tab
        title: Text(
          _currentIndex == 0 ? "Admin Dashboard" : "Admin Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped, // Triggers tab/page change
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}
