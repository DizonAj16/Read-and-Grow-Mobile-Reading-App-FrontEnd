import 'package:deped_reading_app_laravel/api/api_service.dart';
import 'package:deped_reading_app_laravel/pages/auth%20pages/landing_page.dart';
import 'package:deped_reading_app_laravel/widgets/navigation/page_transition.dart';
import 'package:flutter/material.dart';
import 'admin dashboard/admin_dashboard_page.dart';
import 'admin_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await ApiService.logout(token);

    if (response.statusCode == 200) {
      // Only remove token and user-related data, not all preferences
      await prefs.remove('token');
      await prefs.remove('admin_name');
      await prefs.remove('admin_email');
      // ...add/remove other admin-specific keys as needed...

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _LoggingOutDialog(),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(page: LandingPage()),
          (route) => false,
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => const _LogoutFailedDialog(),
      );
    }
  }

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
        title: Text(
          _currentIndex == 0 ? "Admin Dashboard" : "Admin Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          AdminDashboardPage(),
          AdminProfilePage(onLogout: () => _logout(context)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
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

class _LoggingOutDialog extends StatelessWidget {
  const _LoggingOutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 32),
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
    );
  }
}

class _LogoutFailedDialog extends StatelessWidget {
  const _LogoutFailedDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Logout Failed'),
      content: const Text('Unable to logout. Please try again.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
