import 'package:deped_reading_app_laravel/api/classroom_service.dart';
import 'package:deped_reading_app_laravel/constants.dart';
import 'package:flutter/material.dart';
import 'package:deped_reading_app_laravel/pages/student%20pages/student%20class%20pages/widgets/student_view_page.dart';
import 'package:deped_reading_app_laravel/models/student_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_custom_clippers/flutter_custom_clippers.dart';

class StudentListPage extends StatefulWidget {
  final String classId;
  const StudentListPage({super.key, required this.classId});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  // State variables - initialized with default values
  List<Student> _students = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentPage = 0;
  final int _studentsPerPage = 6;
  final PageController _pageController = PageController();
  String? _baseUrl;
  int? _currentStudentId;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadSharedPreferences();
    await _fetchStudents();
  }

  Future<void> _loadSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('base_url') ?? 'http://10.0.2.2:8000';
    final studentIdString = prefs.getString('student_id');
    if (studentIdString != null) {
      _currentStudentId = int.tryParse(studentIdString);
    }
  }

  Future<void> _fetchStudents() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final fetchedStudents = await ClassroomService.getAssignedStudents(
        widget.classId,
      );
      if (!mounted) return;

      _sortAndSetStudents(fetchedStudents);
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _showErrorSnackbar("Oops! Couldn't load classmates");
    }
  }

  void _sortAndSetStudents(List<Student> students) {
    students.sort((a, b) {
      if (a.id == _currentStudentId) return -1;
      if (b.id == _currentStudentId) return 1;
      return 0;
    });
    setState(() {
      _students = students;
      _isLoading = false;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Column(
        children: [
          _StudentListHeader(studentCount: _students.length),
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _fetchStudents,
              color: Colors.blue,
              backgroundColor: Colors.white,
              child: _StudentListContent(
                isLoading: _isLoading,
                hasError: _hasError,
                students: _students,
                currentPage: _currentPage,
                pageController: _pageController,
                studentsPerPage: _studentsPerPage,
                currentStudentId: _currentStudentId,
                baseUrl: _baseUrl,
                onRetry: _fetchStudents,
                onPageChanged: (index) => setState(() => _currentPage = index),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentListHeader extends StatelessWidget {
  final int studentCount;

  const _StudentListHeader({required this.studentCount});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipperOne(reverse: false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryColor, Color(0xFFB71C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              "$studentCount Students",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'ComicNeue',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentListContent extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final List<Student> students;
  final int currentPage;
  final PageController pageController;
  final int studentsPerPage;
  final int? currentStudentId;
  final String? baseUrl;
  final VoidCallback onRetry;
  final Function(int) onPageChanged;

  const _StudentListContent({
    required this.isLoading,
    required this.hasError,
    required this.students,
    required this.currentPage,
    required this.pageController,
    required this.studentsPerPage,
    required this.currentStudentId,
    required this.baseUrl,
    required this.onRetry,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const _LoadingView();
    if (hasError) return _ErrorView(onRetry: onRetry);
    if (students.isEmpty) return const _EmptyView();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: constraints.maxHeight * 1.0,
                  child: _StudentGridView(
                    students: students,
                    currentPage: currentPage,
                    pageController: pageController,
                    studentsPerPage: studentsPerPage,
                    currentStudentId: currentStudentId,
                    baseUrl: baseUrl,
                    onPageChanged: onPageChanged,
                  ),
                ),
                _PageIndicators(
                  itemCount: (students.length / studentsPerPage).ceil(),
                  currentPage: currentPage,
                  onDotTap: (index) {
                    pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animation/loading_rainbow.json',
            width: 90,
            height: 90,
          ),
          const SizedBox(height: 20),
          const Text(
            "Loading Students...",
            style: TextStyle(fontSize: 16, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/error.json', width: 150, height: 150),
          const SizedBox(height: 20),
          const Text(
            "Failed to load students",
            style: TextStyle(
              fontSize: 18,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: onRetry, child: const Text("Retry")),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animations/empty.json', width: 250, height: 250),
          const SizedBox(height: 20),
          Text(
            "No classmates yet!",
            style: TextStyle(
              fontSize: 22,
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentGridView extends StatelessWidget {
  final List<Student> students;
  final int currentPage;
  final PageController pageController;
  final int studentsPerPage;
  final int? currentStudentId;
  final String? baseUrl;
  final Function(int) onPageChanged;

  const _StudentGridView({
    required this.students,
    required this.currentPage,
    required this.pageController,
    required this.studentsPerPage,
    required this.currentStudentId,
    required this.baseUrl,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      itemCount: (students.length / studentsPerPage).ceil(),
      itemBuilder: (context, pageIndex) {
        final studentsToShow =
            students
                .skip(pageIndex * studentsPerPage)
                .take(studentsPerPage)
                .toList();

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          physics: const BouncingScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.8,
          ),
          itemCount: studentsToShow.length,
          itemBuilder: (context, index) {
            return _StudentCard(
              student: studentsToShow[index],
              index: index,
              currentStudentId: currentStudentId,
              baseUrl: baseUrl,
            );
          },
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  final Student student;
  final int index;
  final int? currentStudentId;
  final String? baseUrl;

  const _StudentCard({
    required this.student,
    required this.index,
    required this.currentStudentId,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser =
        currentStudentId != null && student.id == currentStudentId;
    final displayName =
        isCurrentUser ? '${student.studentName} (You)' : student.studentName;
    final profileUrl = _getProfileUrl(student);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.8, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: StudentCard(
            name: displayName,
            avatarLetter: student.avatarLetter,
            profileUrl: profileUrl,
            isCurrentUser: isCurrentUser,
            onTap:
                () => _navigateToStudentProfile(
                  context,
                  displayName,
                  student.avatarLetter,
                  profileUrl,
                ),
          ),
        );
      },
    );
  }

  String? _getProfileUrl(Student student) {
    final sanitizedBaseUrl = baseUrl?.replaceAll(RegExp(r'/api/?$'), '') ?? '';
    return (student.profilePicture != null &&
            student.profilePicture!.isNotEmpty)
        ? "$sanitizedBaseUrl/${student.profilePicture}"
        : null;
  }

  void _navigateToStudentProfile(
    BuildContext context,
    String name,
    String avatarLetter,
    String? profileUrl,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => StudentProfilePage(
              name: name,
              avatarLetter: avatarLetter,
              avatarColor: Colors.blue[300]!,
              profileUrl: profileUrl,
            ),
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  final int itemCount;
  final int currentPage;
  final Function(int) onDotTap;

  const _PageIndicators({
    required this.itemCount,
    required this.currentPage,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(itemCount, (index) {
          return GestureDetector(
            onTap: () => onDotTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: currentPage == index ? 18.0 : 8.0,
              height: 8.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color:
                    currentPage == index
                        ? Colors.blue[700]
                        : Colors.blue.withOpacity(0.3),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class StudentCard extends StatelessWidget {
  final String name;
  final String avatarLetter;
  final String? profileUrl;
  final bool isCurrentUser;
  final VoidCallback onTap;

  const StudentCard({
    super.key,
    required this.name,
    required this.avatarLetter,
    this.profileUrl,
    required this.isCurrentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            if (isCurrentUser) _buildCurrentUserBadge(),
            _buildStudentContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserBadge() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          "YOU",
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            _buildAvatar(),
            const SizedBox(height: 8),
            _buildStudentName(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue[300]!, width: 2),
      ),
      child: ClipOval(
        child:
            (profileUrl != null && profileUrl!.isNotEmpty)
                ? FadeInImage.assetNetwork(
                  placeholder: 'assets/placeholder/avatar_placeholder.jpg',
                  image: profileUrl!,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (_, __, ___) => _buildAvatarFallback(),
                )
                : _buildAvatarFallback(),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      color: Colors.blue[300],
      alignment: Alignment.center,
      child: Text(
        avatarLetter.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
          fontFamily: 'ComicNeue',
        ),
      ),
    );
  }

  Widget _buildStudentName() {
    return Text(
      name.split(' ')[0],
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
