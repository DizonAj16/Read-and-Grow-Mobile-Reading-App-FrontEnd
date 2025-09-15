import 'package:deped_reading_app_laravel/api/supabase_auth_service.dart';
import 'package:deped_reading_app_laravel/models/student_model.dart';
import 'package:deped_reading_app_laravel/pages/auth%20pages/landing_page.dart';
import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:deped_reading_app_laravel/widgets/helpers/tts_modal.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/navigation/page_transition.dart';
import 'student class pages/student_class_page.dart';
import 'student_dashboard_page.dart';
import 'student_profile_page.dart';

// =============================================================================
// STUDENT PAGE - MAIN CONTAINER FOR STUDENT FUNCTIONALITY
// =============================================================================

/// Main page container for student functionality with bottom navigation
/// Handles navigation between dashboard and class pages
class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  // ===========================================================================
  // STATE VARIABLES
  // ===========================================================================

  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final TTSHelper _ttsHelper = TTSHelper();

  final List<Widget> _pages = const [
    StudentDashboardPage(),
    StudentClassPage(),
  ];

  // ===========================================================================
  // LIFECYCLE METHODS
  // ===========================================================================

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

  // ===========================================================================
  // AUTHENTICATION METHODS
  // ===========================================================================

  /// Logs out the student with comprehensive cleanup
  Future<void> _logout() async {
    try {
      await SupabaseAuthService.logout(); // ✅ no need to pass token manually

      final prefs = await SharedPreferences.getInstance();
      await _clearUserData(prefs);

      await _showLogoutSuccess(context);
      _navigateToLandingPage();
    } catch (e) {
      debugPrint("Logout failed: $e");
      _showLogoutError(context);
    }
  }

  /// Clears all user-specific data from shared preferences
  Future<void> _clearUserData(SharedPreferences prefs) async {
    await prefs.remove('token');
    await prefs.remove('student_name');
    await prefs.remove('student_email');
    await prefs.remove('student_id');
    await prefs.remove('profile_picture');
    await prefs.remove('students_data');
    await prefs.remove('student_classes');
    await prefs.remove('student_data');
  }

  /// Shows logout success dialog with progress indicator
  Future<void> _showLogoutSuccess(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _LogoutProgressDialog(),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context).pop();
  }

  /// Navigates to landing page after logout
  void _navigateToLandingPage() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageTransition(page: const LandingPage()),
        (route) => false,
      );
    }
  }

  /// Shows logout error dialog
  void _showLogoutError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _LogoutErrorDialog(),
    );
  }

  // ===========================================================================
  // NAVIGATION METHODS
  // ===========================================================================

  /// Handles bottom navigation tab selection
  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Shows logout confirmation dialog
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

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildPageView(),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  // ===========================================================================
  // UI COMPONENT BUILDERS
  // ===========================================================================

  /// Builds the app bar with dynamic title
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

  /// Builds the page view for navigation
  PageView _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      children: _pages,
    );
  }

  /// Builds the bottom navigation bar
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

  /// Builds bottom navigation items
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

// =============================================================================
// PROFILE POPUP MENU COMPONENT
// =============================================================================

class _ProfilePopupMenu extends StatefulWidget {
  final VoidCallback onLogout;
  final TTSHelper ttsHelper;

  const _ProfilePopupMenu({required this.onLogout, required this.ttsHelper});

  @override
  State<_ProfilePopupMenu> createState() => _ProfilePopupMenuState();
}

class _ProfilePopupMenuState extends State<_ProfilePopupMenu> {
  // ===========================================================================
  // STATE VARIABLES
  // ===========================================================================

  Student? _student;
  String? _profilePictureUrl;

  // ===========================================================================
  // LIFECYCLE METHODS
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  // ===========================================================================
  // DATA LOADING METHODS (ENHANCED WITH API FALLBACK)
  // ===========================================================================

  /// Loads student data with robust fallback mechanism
  /// Tries API first, then falls back to local storage if API fails
  Future<void> _loadStudentData() async {
    try {
      // ✅ Fetch from SupabaseAuthService
      final profileResponse = await SupabaseAuthService.getAuthProfile();
      final studentProfile = profileResponse?['profile'] ?? {};

      // Create Student object from API response
      final Student student = Student.fromJson(studentProfile);

      // ✅ Save to prefs
      await student.saveToPrefs();

      // ✅ Build full profile picture URL
      final String? fullProfileUrl = await _buildProfilePictureUrl(
        student.profilePicture,
      );

      if (mounted) {
        setState(() {
          _student = student;
          _profilePictureUrl = fullProfileUrl;
        });
        debugPrint("🖼️ Profile URL: $_profilePictureUrl");
      }

      debugPrint("✅ Loaded student profile from API: ${student.studentName}");
    } catch (e) {
      debugPrint("⚠️ API failed, loading student from prefs instead: $e");

      try {
        final Student student = await Student.fromPrefs();
        final String? fullProfileUrl = await _buildProfilePictureUrl(
          student.profilePicture,
        );

        if (mounted) {
          setState(() {
            _student = student;
            _profilePictureUrl = fullProfileUrl;
          });
        }

        debugPrint("✅ Loaded student profile from prefs: ${student.studentName}");
      } catch (prefsError) {
        debugPrint("❌ Failed to load student from prefs: $prefsError");

        if (mounted) {
          setState(() {
            _student = Student(
              id: 0,
              studentName: "Student",
              studentLrn: null,
              studentGrade: null,
              studentSection: null,
              username: null,
              profilePicture: null,
              classRoomId: null,
              completedTasks: 0,
            );
            _profilePictureUrl = null;
          });
        }
      }
    }
  }

  /// Builds the complete profile picture URL from base URL
  Future<String?> _buildProfilePictureUrl(String? profilePicture) async {
    if (profilePicture == null || profilePicture.isEmpty) {
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBaseUrl =
          prefs.getString('base_url') ?? 'http://10.0.2.2:8000/api';

      final uri = Uri.parse(savedBaseUrl);
      final baseUrl = '${uri.scheme}://${uri.authority}';
      final url = '$baseUrl/$profilePicture';

      debugPrint("✅ Built profile picture URL: $url"); // 👈 print here

      return url;
    } catch (e) {
      debugPrint("❌ Error building profile picture URL: $e");
      return null;
    }
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: _buildProfileAvatar(radius: 16),
      tooltip: "Student Profile",
      onSelected: (value) => _handleMenuSelection(value, context),
      itemBuilder: (context) => _buildMenuItems(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Theme.of(context).colorScheme.surface,
    );
  }

  // ===========================================================================
  // MENU HANDLING METHODS
  // ===========================================================================

  /// Handles menu item selection
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

  /// Shows profile modal bottom sheet
  Future<void> _showProfileModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              _ProfileModalContainer(child: const StudentProfilePage()),
    );
    await _loadStudentData(); // Refresh data after closing profile
  }

  /// Shows settings modal bottom sheet
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

  // ===========================================================================
  // UI COMPONENT BUILDERS
  // ===========================================================================

  /// Builds the popup menu items
  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final studentName = _student?.studentName ?? "Student";

    return [
      // Profile header
      PopupMenuItem<String>(
        value: 'profile',
        height: 100,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProfileAvatar(radius: 32),
              const SizedBox(height: 8),
              Text(
                studentName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Student',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
      const PopupMenuDivider(),
      // Settings option
      PopupMenuItem<String>(
        value: 'settings',
        height: 48,
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.settings, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
      // Logout option
      PopupMenuItem<String>(
        value: 'logout',
        height: 48,
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.logout, size: 20, color: Colors.red),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  /// Builds the profile avatar with image or fallback
  Widget _buildProfileAvatar({required double radius}) {
    final studentName = _student?.studentName ?? "Student";
    final initials =
        _student?.avatarLetter ??
        (studentName.isNotEmpty ? studentName[0].toUpperCase() : "S");

    return CircleAvatar(
      radius: radius,
      backgroundColor:
          _profilePictureUrl == null
              ? Theme.of(context).colorScheme.primary
              : null,
      child:
          _profilePictureUrl == null
              ? Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.6,
                ),
              )
              : ClipOval(
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/placeholder/avatar_placeholder.jpg',
                  image: _profilePictureUrl!,
                  fit: BoxFit.cover,
                  width: radius * 2,
                  height: radius * 2,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).colorScheme.primary,
                      child: Center(
                        child: Text(
                          initials,
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

// =============================================================================
// SUPPORTING DIALOG COMPONENTS
// =============================================================================

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

class _LogoutProgressDialog extends StatelessWidget {
  const _LogoutProgressDialog();

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
