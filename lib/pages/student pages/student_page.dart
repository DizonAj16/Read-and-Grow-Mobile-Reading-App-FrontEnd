import 'package:deped_reading_app_laravel/api/supabase_auth_service.dart';
import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/models/student_model.dart';
import 'package:deped_reading_app_laravel/pages/auth%20pages/landing_page.dart';
// Removed import: import 'package:deped_reading_app_laravel/pages/student%20pages/enhanced_reading_level_page.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student_dashboard_page.dart';
// import 'package:deped_reading_app_laravel/pages/student%20pages/student_reading_materials_page.dart';
import 'package:deped_reading_app_laravel/widgets/helpers/tts_helper.dart';
import 'package:deped_reading_app_laravel/widgets/helpers/tts_modal.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/navigation/page_transition.dart';
import 'student class pages/student_class_page.dart';
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

  // Page titles for AppBar
  final List<String> _pageTitles = [
    "Dashboard",
    "My Class",
    // Removed "My Reading Level" from here
  ];

  // Fixed pages - order must match bottom navigation
  final List<Widget> _pages = [
    const StudentDashboardPage(),
    const StudentClassPage(),
    // Removed EnhancedReadingLevelPage from here
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
    try {
      await SupabaseAuthService.logout();

      final prefs = await SharedPreferences.getInstance();
      await _clearUserData(prefs);

      await _showLogoutSuccess(context);
      _navigateToLandingPage();
    } catch (e) {
      debugPrint("Logout failed: $e");
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
    await prefs.remove('student_data');
  }

  Future<void> _showLogoutSuccess(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _LogoutProgressDialog(),
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
    _pageController.jumpToPage(index); // Use jumpToPage instead of animateToPage for instant navigation
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
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _showEnrollDialog,
      //   icon: const Icon(Icons.meeting_room),
      //   label: const Text("Join Class"),
      // ),
    );
  }

  Future<void> _showEnrollDialog() async {
    final TextEditingController codeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Classroom Code"),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: "Classroom Code",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                await _enrollStudentToClass(code);
                Navigator.pop(context);
              }
            },
            child: const Text("Join"),
          ),
        ],
      ),
    );
  }

  Future<void> _enrollStudentToClass(String classroomCode) async {
    if (!mounted) return;

    try {
      debugPrint('📝 [STUDENT_ENROLL] Starting enrollment with code: $classroomCode');
      final supabase = Supabase.instance.client;

      // 1️⃣ Validate classroom code
      final classroomResponse = await supabase
          .from('class_rooms')
          .select('id, class_name')
          .eq('classroom_code', classroomCode.trim())
          .maybeSingle();

      if (classroomResponse == null || classroomResponse['id'] == null) {
        debugPrint('❌ [STUDENT_ENROLL] Invalid classroom code: $classroomCode');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Invalid classroom code"),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final classId = classroomResponse['id'] as String;
      final className = classroomResponse['class_name'] as String? ?? 'Unknown';

      debugPrint('✅ [STUDENT_ENROLL] Found class: $className ($classId)');

      // 2️⃣ Get current student
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ [STUDENT_ENROLL] No logged-in user');
        throw Exception("No logged-in user");
      }

      final studentResponse = await supabase
          .from('students')
          .select('id, student_name')
          .eq('id', user.id)
          .maybeSingle();

      if (studentResponse == null) {
        debugPrint('❌ [STUDENT_ENROLL] No matching student profile found');
        throw Exception("No matching student profile found for this user");
      }

      final studentId = studentResponse['id'] as String;
      final studentName = studentResponse['student_name'] as String? ?? 'Student';

      debugPrint('✅ [STUDENT_ENROLL] Found student: $studentName ($studentId)');

      // 3️⃣ Check if already enrolled in another class
      final existingEnrollment = await supabase
          .from('student_enrollments')
          .select('class_room_id, class_rooms(class_name)')
          .eq('student_id', studentId)
          .maybeSingle();

      if (existingEnrollment != null) {
        final existingClassId = existingEnrollment['class_room_id'] as String?;
        final existingClassName = existingEnrollment['class_rooms']?['class_name'] as String?;

        // If already enrolled in this class
        if (existingClassId == classId) {
          debugPrint('ℹ️ [STUDENT_ENROLL] Already enrolled in this class');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("You are already enrolled in $className"),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          return;
        }

        // If enrolled in different class
        debugPrint('❌ [STUDENT_ENROLL] Already enrolled in different class: $existingClassName');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You are already enrolled in \"${existingClassName ?? 'another class'}\". Please contact your teacher to switch classes."),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // 4️⃣ Insert enrollment using ClassroomService for consistency
      debugPrint('📝 [STUDENT_ENROLL] No existing enrollment - proceeding with join');
      final enrollmentResult = await ClassroomService.assignStudent(
        studentId: studentId,
        classRoomId: classId,
      );

      if (enrollmentResult != null && enrollmentResult.containsKey('error')) {
        final errorMessage = enrollmentResult['error'] as String? ?? 'Failed to join class';
        debugPrint('❌ [STUDENT_ENROLL] Assignment failed: $errorMessage');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      debugPrint('✅ [STUDENT_ENROLL] Successfully enrolled in class');

      // 5️⃣ Show success snackbar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Successfully joined $className!"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // 6️⃣ Close the dialog
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // 7️⃣ Wait a short moment to finish animations
      await Future.delayed(const Duration(milliseconds: 200));

      // 8️⃣ Refresh My Classes tab safely
      if (!mounted) return;
      setState(() {
        _currentIndex = 1;
      });

      // Rebuild StudentClassPage (forces refresh)
      _pageController.jumpToPage(1);

    } catch (e, stack) {
      debugPrint("❌ [STUDENT_ENROLL] Enrollment error: $e");
      debugPrintStack(stackTrace: stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error enrolling: ${e.toString().replaceAll('Exception: ', '')}"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        _pageTitles[_currentIndex], // Use dynamic page titles
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

  Widget _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      children: _pages,
      physics: const PageScrollPhysics(), // Standard page physics
      // Prevent overscroll/bounce
      scrollBehavior: const ScrollBehavior().copyWith(
        overscroll: false,
        scrollbars: false,
      ),
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
      // Removed Reading Level tab
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
  Student? _student;
  String? _profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final profileResponse = await SupabaseAuthService.getAuthProfile();
      final studentProfile = profileResponse?['profile'] ?? {};
      final Student student = Student.fromJson(studentProfile);
      await student.saveToPrefs();
      final String? fullProfileUrl = await _buildProfilePictureUrl(
        student.profilePicture,
      );

      if (mounted) {
        setState(() {
          _student = student;
          _profilePictureUrl = fullProfileUrl;
        });
      }

    } catch (e) {

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
      } catch (prefsError) {
        if (mounted) {
          setState(() {
            _student = Student(
              id: '',
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

  Future<String?> _buildProfilePictureUrl(String? profilePicture) async {
    if (profilePicture == null || profilePicture.isEmpty) {
      return null;
    }

    try {
      // If already a full URL (starts with http/https), use it as is
      if (profilePicture.startsWith('http://') || profilePicture.startsWith('https://')) {
        debugPrint('🖼️ Profile picture is already a full URL');
        return profilePicture;
      }
      
      // Get public URL from Supabase storage 'materials' bucket (matches UserService.uploadProfilePicture)
      final supabase = Supabase.instance.client;
      final bucketBaseUrl = supabase.storage
          .from('materials')
          .getPublicUrl(profilePicture);
      
      debugPrint('🖼️ Normalized profile picture URL: $bucketBaseUrl');
      return bucketBaseUrl;
    } catch (e) {
      debugPrint('⚠️ Error building profile picture URL: $e');
      return null;
    }
  }

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
            heightFactor: 0.4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TTSSettingsModal(ttsHelper: widget.ttsHelper),
            ),
          ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final studentName = _student?.studentName ?? "Student";

    return [
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
      // PopupMenuItem<String>(
      //   value: 'settings',
      //   height: 48,
      //   child: SizedBox(
      //     width: double.infinity,
      //     child: Row(
      //       mainAxisSize: MainAxisSize.min,
      //       mainAxisAlignment: MainAxisAlignment.start,
      //       children: [
      //         Icon(Icons.settings, size: 20, color: Colors.blue),
      //         const SizedBox(width: 12),
      //         Text(
      //           'Settings',
      //           style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
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
                  fontSize: radius * 0.9,
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
                            fontSize: radius * .6,
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

  const _ProfileModalContainer({required this.child, this.heightFactor = 0.68});

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