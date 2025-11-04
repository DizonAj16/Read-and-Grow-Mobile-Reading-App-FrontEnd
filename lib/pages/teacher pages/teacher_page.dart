import 'package:deped_reading_app_laravel/api/supabase_auth_service.dart';
import 'package:deped_reading_app_laravel/models/teacher_model.dart';
import 'package:flutter/material.dart';
import 'pupil_submissions_and_report_page.dart';
import 'teacher dashboard/teacher_dashboard_page.dart';
import 'badges_list_page.dart';
import 'teacher_profile_page.dart';
import 'pupil_management_page.dart';
import 'reading_recordings_grading_page.dart';
import 'teacher_reading_materials_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../pages/auth pages/landing_page.dart';
import '../../widgets/navigation/page_transition.dart';

// Main page container for teacher functionality with navigation drawer
class TeacherPage extends StatefulWidget {
  const TeacherPage({super.key});

  @override
  State<TeacherPage> createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String _currentTitle = "Dashboard";
  String _currentRoute = '/dashboard';
  String _teacherName = "Teacher";
  String? _profilePicture;

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      await SupabaseAuthService.logout(); // ✅ Use Supabase service

      await Teacher.clearPrefs();
      await prefs.remove('teacher_classes');
      await prefs.remove('students_data');

      _showLoadingDialog(context);
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushAndRemoveUntil(
          PageTransition(page: const LandingPage()),
              (route) => false,
        );
      }
    } catch (e) {
      _showErrorDialog(
        context,
        'Logout Failed',
        'Unable to logout. Please try again.',
      );
      debugPrint("Logout error: $e");
    }
  }

  Future<void> _loadTeacherData() async {
    try {
      final profileResponse = await SupabaseAuthService.getAuthProfile(); // ✅

      final teacherDetails = profileResponse?['profile'] ?? profileResponse ?? {};
      final teacher = Teacher.fromJson(teacherDetails);

      await teacher.saveToPrefs();

      final prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('base_url') ?? '';
      baseUrl = baseUrl.replaceAll(RegExp(r'/api/?$'), '');

      String? profilePicture;
      if (teacher.profilePicture != null && teacher.profilePicture!.isNotEmpty) {
        profilePicture = _buildProfilePictureUrl(
          baseUrl,
          teacher.profilePicture!,
        );
      }

      if (mounted) {
        setState(() {
          _teacherName = teacher.name;
          _profilePicture = profilePicture;
        });
      }
    } catch (e) {
      debugPrint("Failed to load teacher from API: $e");
      await _loadTeacherFromPrefs();
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _LogoutConfirmationDialog(logout: logout),
    );
  }

  void _navigateTo(String route, String title) {
    if (_currentRoute != route) {
      setState(() {
        _currentTitle = title;
        _currentRoute = route;
      });
      Navigator.pop(context);
      _navigatorKey.currentState?.pushReplacementNamed(route);
    }
  }

  Future<void> _loadTeacherFromPrefs() async {
    try {
      final teacher = await Teacher.fromPrefs();
      final prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('base_url') ?? '';
      baseUrl = baseUrl.replaceAll(RegExp(r'/api/?$'), '');

      String? profilePicture;
      if (teacher.profilePicture != null &&
          teacher.profilePicture!.isNotEmpty) {
        profilePicture = _buildProfilePictureUrl(
          baseUrl,
          teacher.profilePicture!,
        );
      }

      if (mounted) {
        setState(() {
          _teacherName = teacher.name;
          _profilePicture = profilePicture;
        });
      }
    } catch (prefsError) {
      debugPrint("Failed to load teacher from prefs: $prefsError");
      if (mounted) {
        setState(() {
          _teacherName = "Teacher";
          _profilePicture = null;
        });
      }
    }
  }

  String _buildProfilePictureUrl(String baseUrl, String profilePicturePath) {
    return "$baseUrl/${profilePicturePath.replaceFirst(RegExp(r'^/'), '')}?t=${DateTime.now().millisecondsSinceEpoch}";
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String? route,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border:
            isSelected
                ? Border.all(color: Colors.white.withOpacity(0.3), width: 1.0)
                : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minLeadingWidth: 0,
        horizontalTitleGap: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap:
            onTap ?? (route != null ? () => _navigateTo(route, title) : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded)),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Navigator(
        key: _navigatorKey,
        initialRoute: '/dashboard',
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.95),
              Theme.of(context).colorScheme.primary.withOpacity(0.9),
            ],
          ),
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerHeader(context),
                  const SizedBox(height: 16),
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_rounded,
                    title: 'Dashboard',
                    route: '/dashboard',
                    isSelected: _currentRoute == '/dashboard',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.people_rounded,
                    title: 'Manage Pupils',
                    route: '/pupils',
                    isSelected: _currentRoute == '/pupils',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.emoji_events_rounded,
                    title: 'Badges List',
                    route: '/badges',
                    isSelected: _currentRoute == '/badges',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.assignment_rounded,
                    title: 'Pupil Submissions/Reports',
                    route: '/submissions',
                    isSelected: _currentRoute == '/submissions',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.mic_rounded,
                    title: 'Grade Reading Recordings',
                    route: '/grade_recordings',
                    isSelected: _currentRoute == '/grade_recordings',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.library_books_rounded,
                    title: 'Reading Materials',
                    route: '/reading_materials',
                    isSelected: _currentRoute == '/reading_materials',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  const Divider(
                    color: Colors.white30,
                    thickness: 1,
                    height: 32,
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Log out',
                    route: null,
                    isSelected: false,
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TeacherProfilePage(),
                ),
              );
              await _loadTeacherData();
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Hero(
                  tag: 'teacher-profile-image',
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white70,
                      child: ClipOval(
                        child:
                            _profilePicture != null &&
                                    _profilePicture!.isNotEmpty
                                ? FadeInImage.assetNetwork(
                                  placeholder:
                                      'assets/placeholder/avatar_placeholder.jpg',
                                  image: _profilePicture!,
                                  fit: BoxFit.cover,
                                  fadeInDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                  fadeInCurve: Curves.easeInOut,
                                  imageErrorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return Image.asset(
                                      'assets/placeholder/avatar_placeholder.jpg',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                                : Image.asset(
                                  'assets/placeholder/avatar_placeholder.jpg',
                                  fit: BoxFit.cover,
                                ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _teacherName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 6,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Teacher",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Route _generateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/pupils':
        page = const PupilManagementPage();
        break;
      case '/badges':
        page = const BadgesListPage();
        break;
      case '/submissions':
        page = const StudentSubmissionsPage();
        break;
      case '/grade_recordings':
        page = const ReadingRecordingsGradingPage();
        break;
      case '/reading_materials':
        page = const TeacherReadingMaterialsPage();
        break;
      case '/dashboard':
      default:
        page = const TeacherDashboardPage();
        break;
    }
    return MaterialPageRoute(builder: (_) => page);
  }
}

class _LogoutConfirmationDialog extends StatelessWidget {
  final VoidCallback logout;

  const _LogoutConfirmationDialog({required this.logout});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Confirm Logout",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "You are about to log out. Make sure to save your work before leaving.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      Icons.cancel_outlined,
                      size: 20,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    label: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                        width: 1.5,
                      ),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Log Out",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.3),
                    ),
                    onPressed: logout,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showLoadingDialog(BuildContext context) {
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
        ),
  );
}

void _showErrorDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}
