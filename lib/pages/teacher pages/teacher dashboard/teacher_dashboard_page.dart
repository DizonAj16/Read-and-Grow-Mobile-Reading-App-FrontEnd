import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/api/prefs_service.dart';
import 'package:deped_reading_app_laravel/api/user_service.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20classes/class_details_page.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20dashboard/create%20student%20and%20classes/create_class_or_student_dialog.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20dashboard/manage%20classes/delete_class_modal.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20dashboard/manage%20classes/edit_class_modal.dart';
import 'package:deped_reading_app_laravel/pages/teacher%20pages/teacher%20dashboard/students_list/teacher_student_list_modal.dart';
import 'package:deped_reading_app_laravel/widgets/navigation/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'cards/horizontal_card.dart';
import 'cards/class_card.dart';
import '../../../models/student.dart';
import '../../../models/teacher.dart';
import '../../../models/classroom.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  // Initialize futures with default values
  Future<List<Student>> _studentsFuture = Future.value([]);
  Future<Teacher> _teacherFuture = Future.value(
    Teacher(id: 0, userId: 0, name: 'Loading...', profilePicture: null),
  );
  Future<int> _classCountFuture = Future.value(0);
  Future<List<Classroom>> _classesFuture = Future.value([]);

  static const List<int> _pageSizes = [2, 5, 10, 20, 50];
  final int _pageSize = 10;
  List<Student> _allStudents = [];

  bool _isLoading = true;
  bool _isRefreshing = false;
  DateTime? _loadingStartTime;

  @override
  void initState() {
    super.initState();
    // Initial load with minimum 2-second delay
    Future.wait([
      _loadInitialData(),
      Future.delayed(const Duration(seconds: 2)),
    ]).then((_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _loadInitialData() async {
    _loadingStartTime = DateTime.now();
    setState(() => _isLoading = true);

    try {
      await Future.wait([
        _loadTeacherData(),
        _loadStudentData(),
        _loadClassData(),
      ]);
    } catch (e) {
      debugPrint("Initial data loading error: $e");
    } finally {
      await _ensureMinimumLoadingTime();
    }
  }

  Future<void> _loadTeacherData() async {
    _teacherFuture = Teacher.fromPrefs();
    await _teacherFuture;
  }

  Future<void> _loadStudentData() async {
    _studentsFuture = _loadStudents().then((students) {
      _allStudents = students;
      return students;
    });
    await _studentsFuture;
  }

  Future<void> _loadClassData() async {
    _classesFuture = _loadClassesAndCount().then((classes) {
      _classCountFuture = Future.value(classes.length);
      return classes;
    });
    await _classesFuture;
  }

  Future<void> _ensureMinimumLoadingTime() async {
    if (_loadingStartTime != null) {
      final elapsed = DateTime.now().difference(_loadingStartTime!);
      final remaining = const Duration(seconds: 2) - elapsed;
      if (remaining > Duration.zero) await Future.delayed(remaining);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
      _isLoading = true; // Show shimmer immediately
    });

    try {
      await _loadInitialData();
    } catch (e) {
      debugPrint("Refresh error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Student>> _loadStudents() async {
    try {
      final apiList = await UserService.fetchAllStudents();
      await PrefsService.storeStudentsToPrefs(apiList);
    } catch (_) {
      debugPrint(
        "Failed to fetch students from API, loading from local storage.",
      );
    }
    return await PrefsService.getStudentsFromPrefs();
  }

  Future<List<Classroom>> _loadClassesAndCount() async {
    final classes = await ClassroomService.fetchTeacherClasses();
    await PrefsService.storeTeacherClassesToPrefs(classes);
    return classes;
  }

  void _refreshStudentCount() {
    setState(() => _studentsFuture = _loadStudents());
  }

  void _refreshClasses() {
    setState(() {
      _classesFuture = _loadClassesAndCount();
      _classCountFuture = _classesFuture.then((list) => list.length);
    });
  }

  /// Shows the create class/student dialog.
  void _showCreateClassOrStudentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => CreateClassOrStudentDialog(
            onStudentAdded: _refreshStudentCount,
            onClassAdded: _refreshClasses,
          ),
    );
  }

  /// Shows a loading dialog with a Lottie animation and text.
  void showLoadingDialog(String lottieAsset, String loadingText) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 75,
                    height: 75,
                    child: Lottie.asset(lottieAsset),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loadingText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// Hides the loading dialog after a delay.
  Future<void> hideLoadingDialog(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  /// Shows the student list modal bottom sheet.
  Future<void> _showStudentListModal(BuildContext context) async {
    if (_allStudents.isEmpty) {
      await _studentsFuture;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TeacherStudentListModal(
                      allStudents: _allStudents,
                      pageSizes: _pageSizes,
                      initialPageSize: _pageSize,
                      onDataChanged: () {
                        setState(() {
                          _studentsFuture = _loadStudents(); // REFRESH DATA
                        });
                      },
                    ),
                  ),
                ),
          ),
    );
  }

  /// Navigates to the class details page for a given class ID.
  void _viewClassDetails(BuildContext context, int classId) async {
    try {
      final details = await ClassroomService.getClassDetails(classId);
      if (!context.mounted) return;

      await Navigator.of(
        context,
        rootNavigator: true,
      ).push(PageTransition(page: ClassDetailsPage(classDetails: details)));

      // ✅ Refresh after returning from ClassDetailsPage
      _refreshClasses();
    } catch (e) {
      print("Failed to load class details: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load class details.")),
      );
    }
  }

  /// Opens a dialog to edit a class's details.
  void _editClass(BuildContext context, Classroom classroom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => EditClassBottomModal(
            classroom: classroom,
            onClassUpdated: _refreshClasses,
          ),
    );
  }

  /// Deletes a class after confirmation.
  void _deleteClass(BuildContext context, int classId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DeleteClassBottomModal(
            classId: classId,
            onClassDeleted: _refreshClasses,
          ),
    );
  }

  Widget _buildShimmerLoading() {
    return Stack(
      children: [
        // Main shimmer content
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Shimmer for welcome card
              Container(
                height: 100,
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
              // Shimmer for statistics cards
              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    Container(
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Shimmer for classes section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 150, height: 30, color: Colors.white),
                  const SizedBox(height: 10),
                  ...List.generate(
                    1,
                    (index) => Container(
                      height: 150,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // FAB shimmer overlay (always fixed at bottom right)
        Positioned(
          bottom: 16,
          right: 16,
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the main widget tree for the dashboard page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          _isLoading || _isRefreshing
              ? null
              : FloatingActionButton(
                onPressed: () => _showCreateClassOrStudentDialog(context),
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.add, color: Colors.white),
              ),
      body: Stack(
        children: [
          // Main content (hidden when loading)
          if (!_isLoading && !_isRefreshing)
            RefreshIndicator(
              onRefresh: _handleRefresh,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildWelcomeMessage(),
                  const SizedBox(height: 20),
                  _buildStatisticsCards(),
                  const SizedBox(height: 20),
                  _buildMyClassesSection(),
                ],
              ),
            ),

          // Shimmer loading overlay
          if (_isLoading || _isRefreshing) _buildShimmerLoading(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return FutureBuilder<Teacher>(
      future: _teacherFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget("Failed to load teacher data");
        }

        final teacher = snapshot.data ?? Teacher.empty();
        final username = teacher.username ?? teacher.name;
        final initials =
            teacher.name.isNotEmpty
                ? teacher.name.trim().split(' ').first[0].toUpperCase()
                : 'T';
        final hasProfile = teacher.profilePicture?.isNotEmpty ?? false;
        final avatarUrl =
            hasProfile
                ? "${teacher.profilePicture!}?t=${DateTime.now().millisecondsSinceEpoch}"
                : null;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                child:
                    hasProfile
                        ? ClipOval(
                          child: FadeInImage.assetNetwork(
                            placeholder:
                                'assets/placeholder/avatar_placeholder.jpg',
                            image: avatarUrl!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                            imageErrorBuilder:
                                (_, __, ___) => _buildAvatarFallback(initials),
                            fadeInDuration: const Duration(milliseconds: 300),
                            fadeInCurve: Curves.easeInOut,
                          ),
                        )
                        : _buildAvatarFallback(initials),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome Teacher,",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$username 👋",
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarFallback(String initials) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return FutureBuilder<List<Student>>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget("Failed to load student data");
        }

        final studentCount = snapshot.hasData ? snapshot.data!.length : 0;

        return SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              TeacherDashboardHorizontalCard(
                title: "Students",
                value: studentCount.toString(),
                gradientColors: [Colors.blue, Colors.lightBlueAccent],
                icon: Icons.people,
                onPressed: () => _showStudentListModal(context),
              ),
              const SizedBox(width: 16),
              FutureBuilder<int>(
                future: _classCountFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return TeacherDashboardHorizontalCard(
                      title: "My Classes",
                      value: "0",
                      gradientColors: [Colors.purple, Colors.deepPurpleAccent],
                      icon: Icons.school,
                    );
                  }
                  final myClassCount = snapshot.data ?? 0;
                  return TeacherDashboardHorizontalCard(
                    title: "My Classes",
                    value: myClassCount.toString(),
                    gradientColors: [Colors.purple, Colors.deepPurpleAccent],
                    icon: Icons.school,
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyClassesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Classes",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<Classroom>>(
          future: _classesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorWidget("Failed to load class data");
            }

            final classrooms = snapshot.data ?? [];

            if (classrooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Lottie.asset(
                      'assets/animation/empty_box.json',
                      width: 200,
                      height: 200,
                      repeat: true,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No Classrooms Yet! 🏫",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the "+" button to get started! 👇',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children:
                  classrooms.map((classroom) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TeacherDashboardClassCard(
                        classId: classroom.id!,
                        className: classroom.className,
                        section:
                            "${classroom.gradeLevel} - ${classroom.section}",
                        studentCount: classroom.studentCount,
                        teacherName: classroom.teacherName ?? "Unknown",
                        onView: () => _viewClassDetails(context, classroom.id!),
                        onEdit: () => _editClass(context, classroom),
                        onDelete: () => _deleteClass(context, classroom.id!),
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }
}
