import 'package:deped_reading_app_laravel/api/reading_materials_service.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/enhanced_reading_level_page.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student%20class%20pages/tabs/materials_page.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student%20class%20pages/tabs/student_announcements_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tabs/list_of_quiz_and_lessons.dart';
import 'tabs/student_list_page.dart';
import 'tabs/teacher_info_page.dart';
// Add this import for the reading level page

class ClassDetailsPage extends StatefulWidget {
  final String classId;
  final String className;
  final String backgroundImage;
  final String teacherName;
  final String teacherEmail;
  final String teacherPosition;
  final String? teacherAvatar;

  const ClassDetailsPage({
    super.key,
    required this.classId,
    required this.className,
    required this.backgroundImage,
    required this.teacherName,
    required this.teacherEmail,
    required this.teacherPosition,
    this.teacherAvatar,
  });

  @override
  State<ClassDetailsPage> createState() => _ClassDetailsPageState();
}

class _ClassDetailsPageState extends State<ClassDetailsPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;
  final user = Supabase.instance.client.auth.currentUser;
  // Add these with your other state variables
  int _pendingTasksCount = 0;
  bool _isLoadingPendingCount = true;
  // Add these with your other state variables
  int _pendingReadingMaterialsCount = 0;
  bool _isLoadingReadingMaterialsCount = true;

  @override
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadPendingTasksCount();
    _loadPendingReadingMaterialsCount(); // Add this line
  }

  void _handleScroll() {
    final double offset = _scrollController.offset;
    setState(() {
      _appBarOpacity = (offset / 100).clamp(0.0, 1.0);
    });
  }

  void _onTabTapped(int index) {
    // Refresh pending counts when tapping on respective tabs
    if (index == 1) {
      _loadPendingTasksCount();
    } else if (index == 2) {
      _loadPendingReadingMaterialsCount();
    }

    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarColor = _getAvatarColor(widget.className);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: NestedScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder:
            (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(
                context,
                theme,
                avatarColor,
                innerBoxIsScrolled,
              ),
            ],
        body: _buildPageView(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(theme),
    );
  }

  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    ThemeData theme,
    Color avatarColor,
    bool innerBoxIsScrolled,
  ) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: theme.colorScheme.primary.withOpacity(_appBarOpacity),
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        centerTitle: true,
        title: _buildAppBarTitle(innerBoxIsScrolled),
        background: _buildAppBarBackground(avatarColor),
      ),
    );
  }

  Hero _buildAppBarTitle(bool innerBoxIsScrolled) {
    return Hero(
      tag: 'class-title-${widget.className}',
      child: Material(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: innerBoxIsScrolled ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.className,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Stack _buildAppBarBackground(Color avatarColor) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackgroundImage(avatarColor),
        _buildBackgroundGradient(),
        _buildClassNameOverlay(),
      ],
    );
  }

  Hero _buildBackgroundImage(Color avatarColor) {
    return Hero(
      tag: 'class-bg-${widget.className}',
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.black.withOpacity(0.3),
          BlendMode.darken,
        ),
        child:
            widget.backgroundImage.startsWith('http')
                ? Image.network(
                  widget.backgroundImage,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: avatarColor.withOpacity(0.2),
                      child: Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: avatarColor.withOpacity(0.2),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white54,
                          size: 48,
                        ),
                      ),
                    );
                  },
                )
                : Image.asset(
                  widget.backgroundImage,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                          Container(color: avatarColor.withOpacity(0.2)),
                ),
      ),
    );
  }

  Container _buildBackgroundGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.5),
            Colors.transparent,
            Colors.black.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }

  Positioned _buildClassNameOverlay() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            widget.className,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PageView _buildPageView() {
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      children: [
        StudentAnnouncementsScreen(
          classId: widget.classId,
          className: widget.className,
        ),
        ClassContentScreen(classRoomId: widget.classId),
        EnhancedReadingLevelPage(classId: widget.classId),

        MaterialsPage(classId: widget.classId),
        StudentListPage(classId: widget.classId),
        TeacherInfoPage(classId: widget.classId),
      ],
    );
  }

  Container _buildBottomNavigationBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: theme.scaffoldBackgroundColor,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          elevation: 10,
          type: BottomNavigationBarType.fixed,
          items: _buildBottomNavigationItems(theme),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavigationItems(ThemeData theme) {
    return [
      _buildBottomNavItem(
        0,
        Icons.announcement_outlined,
        "Announcements",
        theme,
      ),
      _buildBottomNavItem(1, Icons.task_outlined, "Tasks", theme),
      _buildBottomNavItem(
        2,
        Icons.library_books_outlined,
        "Reading Level",
        theme,
      ),
      _buildBottomNavItem(3, Icons.book_outlined, "Materials", theme),
      _buildBottomNavItem(4, Icons.people_outline, "Classmates", theme),
      _buildBottomNavItem(5, Icons.person_outline, "Teacher", theme),
    ];
  }

  BottomNavigationBarItem _buildBottomNavItem(
    int index,
    IconData icon,
    String label,
    ThemeData theme,
  ) {
    Widget iconWidget;

    // Check which tab needs a badge
    if (index == 1 && _pendingTasksCount > 0) {
      // Tasks tab with badge
      iconWidget = Container(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon),
            Positioned(
              top: -6,
              right: -8,
              child: Container(
                padding:
                    _pendingTasksCount > 9
                        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                        : const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                constraints: BoxConstraints(
                  minWidth: _isLoadingPendingCount ? 16 : 18,
                  minHeight: _isLoadingPendingCount ? 16 : 18,
                ),
                child:
                    _isLoadingPendingCount
                        ? SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          _pendingTasksCount > 99
                              ? '99+'
                              : '$_pendingTasksCount',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
              ),
            ),
          ],
        ),
      );
    } else if (index == 2 && _pendingReadingMaterialsCount > 0) {
      // Reading Level tab with badge
      iconWidget = Container(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon),
            Positioned(
              top: -6,
              right: -8,
              child: Container(
                padding:
                    _pendingReadingMaterialsCount > 9
                        ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
                        : const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.orange, // Different color for reading materials
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                constraints: BoxConstraints(
                  minWidth: _isLoadingReadingMaterialsCount ? 16 : 18,
                  minHeight: _isLoadingReadingMaterialsCount ? 16 : 18,
                ),
                child:
                    _isLoadingReadingMaterialsCount
                        ? SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          _pendingReadingMaterialsCount > 99
                              ? '99+'
                              : '$_pendingReadingMaterialsCount',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Tab without badge
      iconWidget = Icon(icon);
    }

    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color:
              _currentIndex == index
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: iconWidget,
      ),
      label: label,
    );
  }

  Color _getAvatarColor(String className) {
    final colors = [
      Colors.pink[300]!,
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.orange[300]!,
      Colors.purple[300]!,
      Colors.teal[300]!,
    ];
    return colors[className.hashCode % colors.length];
  }

  Future<void> _loadPendingTasksCount() async {
    setState(() => _isLoadingPendingCount = true);
    try {
      final count = await _getPendingTasksCount();
      setState(() {
        _pendingTasksCount = count;
        _isLoadingPendingCount = false;
      });
    } catch (e) {
      setState(() => _isLoadingPendingCount = false);
      debugPrint('Failed to load pending count: $e');
    }
  }

  // Add this method in your _ClassDetailsPageState class
  Future<int> _getPendingTasksCount() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      // Get student.id from students table
      final studentRow =
          await supabase
              .from('students')
              .select('id')
              .eq('id', userId)
              .maybeSingle();

      if (studentRow == null) return 0;
      final String studentId = studentRow['id'] as String;

      // Get all classes the student is enrolled in
      final enrollments = await supabase
          .from('student_enrollments')
          .select('class_room_id')
          .eq('student_id', studentId);

      final classIds =
          (enrollments as List)
              .map((e) => e['class_room_id'] as String)
              .toList();

      // Get all assignments for these classes
      List<String> assignedTaskIds = [];
      List<String> assignedQuizIds = [];
      Set<String> tasksWithQuizzes = {};

      if (classIds.isNotEmpty) {
        final assignments = await supabase
            .from('assignments')
            .select('task_id, quiz_id, tasks(id, quizzes(id))')
            .inFilter('class_room_id', classIds);

        for (var assignment in assignments) {
          final directQuizId = assignment['quiz_id'] as String?;
          if (directQuizId != null && !assignedQuizIds.contains(directQuizId)) {
            assignedQuizIds.add(directQuizId);
          }

          final taskId = assignment['task_id'] as String?;
          if (taskId != null) {
            final task = assignment['tasks'] as Map<String, dynamic>?;
            bool taskHasQuiz = false;

            if (task != null) {
              final quizzes = task['quizzes'] as List?;
              if (quizzes != null && quizzes.isNotEmpty) {
                taskHasQuiz = true;
                tasksWithQuizzes.add(taskId);
                for (var quiz in quizzes) {
                  final quizId = quiz['id'] as String?;
                  if (quizId != null && !assignedQuizIds.contains(quizId)) {
                    assignedQuizIds.add(quizId);
                  }
                }
              }
            }

            if (!taskHasQuiz && !assignedTaskIds.contains(taskId)) {
              assignedTaskIds.add(taskId);
            }
          }
        }
      }

      // Get existing progress records
      final response = await supabase
          .from('student_task_progress')
          .select('task_id, completed')
          .eq('student_id', userId);

      Set<String> completedTaskIds = {};
      Set<String> pendingTaskIds = {};

      for (var row in response) {
        final taskId = row['task_id'] as String?;
        if (taskId == null) continue;

        if (row['completed'] == true) {
          completedTaskIds.add(taskId);
        } else {
          pendingTaskIds.add(taskId);
        }
      }

      // Filter out tasks with quizzes
      Set<String> pendingTasksWithoutQuizzes =
          pendingTaskIds.where((id) => !tasksWithQuizzes.contains(id)).toSet();
      Set<String> completedTasksWithoutQuizzes =
          completedTaskIds
              .where((id) => !tasksWithQuizzes.contains(id))
              .toSet();

      // Count newly assigned tasks (without quizzes)
      int newPendingTasks = 0;
      for (var taskId in assignedTaskIds) {
        if (!completedTasksWithoutQuizzes.contains(taskId) &&
            !pendingTasksWithoutQuizzes.contains(taskId)) {
          newPendingTasks++;
        }
      }

      // Get completed quizzes
      final quizSubmissions = await supabase
          .from('student_submissions')
          .select(
            'assignment_id, assignments(id, task_id, quiz_id, tasks(id, quizzes(id)))',
          )
          .eq('student_id', userId);

      Set<String> completedQuizIds = {};
      for (var submission in quizSubmissions) {
        final assignment = submission['assignments'] as Map<String, dynamic>?;
        if (assignment != null) {
          final directQuizId = assignment['quiz_id'] as String?;
          if (directQuizId != null && directQuizId.isNotEmpty) {
            completedQuizIds.add(directQuizId);
          }

          final task = assignment['tasks'] as Map<String, dynamic>?;
          if (task != null) {
            final quizzes = task['quizzes'] as List?;
            if (quizzes != null) {
              for (var quiz in quizzes) {
                final quizId = quiz['id'] as String?;
                if (quizId != null) {
                  completedQuizIds.add(quizId);
                }
              }
            }
          }
        }
      }

      // Count newly assigned quizzes
      int newPendingQuizzes = 0;
      for (var quizId in assignedQuizIds) {
        if (!completedQuizIds.contains(quizId)) {
          newPendingQuizzes++;
        }
      }

      // Total pending count
      return pendingTasksWithoutQuizzes.length +
          newPendingTasks +
          newPendingQuizzes;
    } catch (e) {
      debugPrint('Error getting pending tasks count: $e');
      return 0;
    }
  }

  // Add this method
  Future<void> _loadPendingReadingMaterialsCount() async {
    setState(() => _isLoadingReadingMaterialsCount = true);
    try {
      final count = await _getPendingReadingMaterialsCount();
      setState(() {
        _pendingReadingMaterialsCount = count;
        _isLoadingReadingMaterialsCount = false;
      });
    } catch (e) {
      setState(() => _isLoadingReadingMaterialsCount = false);
      debugPrint('Failed to load pending reading materials count: $e');
    }
  }

  // Add this method in your _ClassDetailsPageState class
  Future<int> _getPendingReadingMaterialsCount() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return 0;

      // Get student's current reading level
      final studentRes =
          await supabase
              .from('students')
              .select('id, current_reading_level_id')
              .eq('id', user.id)
              .maybeSingle();

      if (studentRes == null ||
          studentRes['current_reading_level_id'] == null) {
        return 0;
      }

      final studentId = studentRes['id'];
      final levelId = studentRes['current_reading_level_id'];

      // Get reading materials for this level
      final materialsData =
          await ReadingMaterialsService.getReadingMaterialsByLevelForStudent(
            levelId,
            studentId,
            classRoomId: widget.classId, // Pass classId for class context
          );

      // Sort materials by creation date
      materialsData.sort((a, b) {
        final materialA = a['material'] as ReadingMaterial;
        final materialB = b['material'] as ReadingMaterial;
        return materialA.createdAt.compareTo(materialB.createdAt);
      });

      // Filter materials that are accessible (not locked by prerequisites)
      final accessibleMaterials =
          materialsData.where((data) {
            final isAccessible = data['is_accessible'] as bool;
            return isAccessible;
          }).toList();

      if (accessibleMaterials.isEmpty) return 0;

      // Get material IDs
      final materialIds =
          accessibleMaterials
              .map((data) {
                final material = data['material'] as ReadingMaterial;
                return material.id;
              })
              .whereType<String>()
              .toList();

      // Get submitted materials
      final submissionsRes = await supabase
          .from('student_recordings')
          .select('material_id')
          .eq('student_id', studentId)
          .inFilter('material_id', materialIds)
          .isFilter('task_id', null); // Only reading materials (not tasks)

      Set<String> submittedMaterialIds = {};
      for (final s in submissionsRes) {
        final materialId = s['material_id'] as String?;
        if (materialId != null) {
          submittedMaterialIds.add(materialId);
        }
      }

      // Pending count = total accessible materials - submitted materials
      final pendingCount =
          accessibleMaterials.length - submittedMaterialIds.length;
      return pendingCount > 0 ? pendingCount : 0;
    } catch (e) {
      debugPrint('Error getting pending reading materials count: $e');
      return 0;
    }
  }
}
