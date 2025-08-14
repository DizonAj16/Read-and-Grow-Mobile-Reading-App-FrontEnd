import 'package:deped_reading_app_laravel/api/auth_service.dart';
import 'package:deped_reading_app_laravel/pages/auth%20pages/landing_page.dart';
import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:deped_reading_app_laravel/widgets/helpers/tts_modal.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/navigation/page_transition.dart';
import 'student class pages/student_class_page.dart';
import 'student_dashboard_page.dart';
import 'student_profile_page.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final TTSHelper _ttsHelper = TTSHelper();

  final List<Widget> _pages = const [
    StudentDashboardPage(),
    StudentClassPage(),
  ];

  @override
  void initState() {
    super.initState();
    _ttsHelper.init();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ttsHelper.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await AuthService.logout(token);

    if (response.statusCode == 200) {
      await _clearUserData(prefs);
      await _showLogoutSuccess(context);
      _navigateToLandingPage();
    } else {
      _showLogoutError(context);
    }
  }

  Future<void> _clearUserData(SharedPreferences prefs) async {
    await prefs.remove('token');
    await prefs.remove('student_name');
    await prefs.remove('student_email');
    await prefs.remove('student_id');
    await prefs.remove('profile_picture');
    await prefs.remove('students_data');
    await prefs.remove('student_classes');
  }

  Future<void> _showLogoutSuccess(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LogoutProgressDialog(context: context),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context).pop();
  }

  void _navigateToLandingPage() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageTransition(page: const LandingPage()),
        (route) => false,
      );
    }
  }

  void _showLogoutError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _LogoutErrorDialog(),
    );
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => _LogoutConfirmationDialog(
            onStay: () => Navigator.pop(context),
            onLogout: _logout,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildPageView(),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        _currentIndex == 0 ? "Student Dashboard" : "My Classes",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        _ProfilePopupMenu(
          onLogout: _showLogoutConfirmation,
          ttsHelper: _ttsHelper,
        ),
      ],
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
    );
  }

  PageView _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      children: _pages,
    );
  }

  BottomNavigationBar _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      items: _buildBottomNavItems(),
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey.shade600,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: "Dashboard",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.class_outlined),
        activeIcon: Icon(Icons.class_),
        label: "My Class",
      ),
    ];
  }
}

class _ProfilePopupMenu extends StatefulWidget {
  final VoidCallback onLogout;
  final TTSHelper ttsHelper;

  const _ProfilePopupMenu({required this.onLogout, required this.ttsHelper});

  @override
  State<_ProfilePopupMenu> createState() => _ProfilePopupMenuState();
}

class _ProfilePopupMenuState extends State<_ProfilePopupMenu> {
  String _studentName = "Student";
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl =
        prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';
    final uri = Uri.parse(savedBaseUrl);
    final baseUrl = '${uri.scheme}://${uri.authority}';

    String? storedProfilePicture = prefs.getString('profile_picture');
    if (storedProfilePicture != null &&
        storedProfilePicture.isNotEmpty &&
        !storedProfilePicture.startsWith('http')) {
      storedProfilePicture =
          '$baseUrl/storage/profile_images/$storedProfilePicture';
    }

    if (mounted) {
      setState(() {
        _studentName = prefs.getString('student_name') ?? "Student";
        _profilePictureUrl = storedProfilePicture;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: _buildProfileAvatar(radius: 16),
      tooltip: "Student Profile",
      onSelected: (value) => _handleMenuSelection(value, context),
      itemBuilder: (context) => _buildMenuItems(context),
    );
  }

  Future<void> _handleMenuSelection(String value, BuildContext context) async {
    switch (value) {
      case 'logout':
        widget.onLogout();
        break;
      case 'profile':
        await _showProfileModal(context);
        break;
      case 'settings':
        await _showSettingsModal(context);
        break;
    }
  }

  Future<void> _showProfileModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              _ProfileModalContainer(child: const StudentProfilePage()),
    );
    await _loadStudentData();
  }

  Future<void> _showSettingsModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _ProfileModalContainer(
            heightFactor: 0.6,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TTSSettingsModal(ttsHelper: widget.ttsHelper),
            ),
          ),
    );
  }

  List<PopupMenuItem<String>> _buildMenuItems(BuildContext context) {
    return [
      PopupMenuItem(
        value: 'profile',
        child: SizedBox(
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProfileAvatar(radius: 40),
              const SizedBox(height: 12),
              Text(
                _studentName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Student',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
              ),
              const Divider(height: 24),
            ],
          ),
        ),
      ),
      const PopupMenuItem(
        value: 'settings',
        child: _MenuOptionRow(
          icon: Icons.settings,
          iconColor: Colors.blue,
          label: 'Settings',
        ),
      ),
      PopupMenuItem(
        value: 'logout',
        child: _MenuOptionRow(
          icon: Icons.logout,
          iconColor: Colors.red,
          label: 'Logout',
        ),
      ),
    ];
  }

  Widget _buildProfileAvatar({required double radius}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          _profilePictureUrl == null
              ? Theme.of(context).colorScheme.primary
              : null,
      child:
          _profilePictureUrl == null
              ? Text(
                _studentName.isNotEmpty ? _studentName[0].toUpperCase() : "S",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.6,
                ),
              )
              : ClipOval(
                child: FadeInImage.assetNetwork(
                  placeholder:
                      'assets/placeholder/avatar_placeholder.jpg', // Add this asset to your project
                  image: _profilePictureUrl!,
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).colorScheme.primary,
                      child: Center(
                        child: Text(
                          _studentName.isNotEmpty
                              ? _studentName[0].toUpperCase()
                              : "S",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: radius * 0.6,
                          ),
                        ),
                      ),
                    );
                  },
                  fadeInDuration: const Duration(milliseconds: 300),
                  fadeOutDuration: const Duration(milliseconds: 100),
                ),
              ),
    );
  }
}

class _ProfileModalContainer extends StatelessWidget {
  final Widget child;
  final double heightFactor;

  const _ProfileModalContainer({required this.child, this.heightFactor = 0.85});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: FractionallySizedBox(
        heightFactor: heightFactor,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MenuOptionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _MenuOptionRow({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 16),
        Text(label),
      ],
    );
  }
}

class _LogoutProgressDialog extends StatelessWidget {
  final BuildContext context;

  const _LogoutProgressDialog({required this.context});

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
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
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

class _LogoutErrorDialog extends StatelessWidget {
  const _LogoutErrorDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

class _LogoutConfirmationDialog extends StatelessWidget {
  final VoidCallback onStay;
  final VoidCallback onLogout;

  const _LogoutConfirmationDialog({
    required this.onStay,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Icon(
            Icons.logout,
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            "Are you leaving?",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
        "We hope to see you again soon! Are you sure you want to log out?",
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DialogButton(
              icon: Icons.cancel,
              text: "Stay",
              color: Colors.green,
              onPressed: onStay,
            ),
            const SizedBox(width: 12),
            _DialogButton(
              icon: Icons.logout,
              text: "Log Out",
              color: Theme.of(context).colorScheme.error,
              onPressed: onLogout,
            ),
          ],
        ),
      ],
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _DialogButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 2,
        shadowColor: color.withOpacity(0.4),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}
